#!/usr/bin/env python3
"""Regenerate the checked-in Xcode project with Python 3; no XcodeGen required."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
objects = {}

def uid(name):
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()

def add(key_name, isa, **kwargs):
    key = uid(key_name)
    objects[key] = {"isa": isa, **kwargs}
    return key

def configs(name, settings):
    refs = []
    for kind in ("Debug", "Release"):
        options = dict(settings)
        options.update({"SWIFT_OPTIMIZATION_LEVEL": "-Onone" if kind == "Debug" else "-O",
                        "DEBUG_INFORMATION_FORMAT": "dwarf" if kind == "Debug" else "dwarf-with-dsym"})
        if kind == "Debug":
            options["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "DEBUG $(inherited)"
            options["ENABLE_TESTABILITY"] = "YES"
        refs.append(add(name + kind, "XCBuildConfiguration", name=kind, buildSettings=options))
    return add(name + "configs", "XCConfigurationList", buildConfigurations=refs,
               defaultConfigurationIsVisible="0", defaultConfigurationName="Release")

def file(name, path, kind):
    return add(name, "PBXFileReference", lastKnownFileType=kind, path=path, sourceTree="<group>")

app_sources, source_refs, resources = [], [], []
for path in sorted((ROOT / "LumaLilt").rglob("*.swift")):
    rel = str(path.relative_to(ROOT / "LumaLilt"))
    ref = file("source-" + rel, rel, "sourcecode.swift")
    source_refs.append(ref)
    app_sources.append(add("build-" + rel, "PBXBuildFile", fileRef=ref))
for path, kind in [("Resources/Assets.xcassets", "folder.assetcatalog"), ("Resources/PrivacyInfo.xcprivacy", "text.xml")]:
    ref = file(path, path, kind)
    source_refs.append(ref)
    resources.append(add("build-" + path, "PBXBuildFile", fileRef=ref))
source_group = add("sources", "PBXGroup", children=source_refs, path="LumaLilt", sourceTree="<group>")
test_file = file("testfile", "PuzzleTests.swift", "sourcecode.swift")
test_group = add("testgroup", "PBXGroup", children=[test_file], path="Tests", sourceTree="<group>")
test_build = add("testbuild", "PBXBuildFile", fileRef=test_file)
app_product = add("app-product", "PBXFileReference", explicitFileType="wrapper.application", includeInIndex="0", path="LumaLilt.app", sourceTree="BUILT_PRODUCTS_DIR")
test_product = add("test-product", "PBXFileReference", explicitFileType="wrapper.cfbundle", includeInIndex="0", path="LumaLiltTests.xctest", sourceTree="BUILT_PRODUCTS_DIR")
products = add("products", "PBXGroup", children=[app_product, test_product], name="Products", sourceTree="<group>")
main = add("main", "PBXGroup", children=[source_group, test_group, products], sourceTree="<group>")

def phase(name, isa, files):
    return add(name, isa, buildActionMask="2147483647", files=files, runOnlyForDeploymentPostprocessing="0")

app_phases = [phase("appsrc", "PBXSourcesBuildPhase", app_sources),
              phase("appframework", "PBXFrameworksBuildPhase", []),
              phase("appres", "PBXResourcesBuildPhase", resources)]
test_phases = [phase("testsrc", "PBXSourcesBuildPhase", [test_build]),
               phase("testframework", "PBXFrameworksBuildPhase", []),
               phase("testres", "PBXResourcesBuildPhase", [])]
base = {"CLANG_ENABLE_MODULES": "YES", "CLANG_ENABLE_OBJC_ARC": "YES", "SWIFT_VERSION": "5.0",
        "IPHONEOS_DEPLOYMENT_TARGET": "16.0", "SDKROOT": "iphoneos", "CODE_SIGN_STYLE": "Automatic",
        "TARGETED_DEVICE_FAMILY": "1,2", "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
        "CURRENT_PROJECT_VERSION": "2", "MARKETING_VERSION": "1.0", "ENABLE_USER_SCRIPT_SANDBOXING": "YES"}
project_configs = configs("project", base)
app_configs = configs("app", {
    "PRODUCT_BUNDLE_IDENTIFIER": "com.mackinnontech.LumaLilt", "PRODUCT_NAME": "$(TARGET_NAME)",
    "GENERATE_INFOPLIST_FILE": "YES", "INFOPLIST_KEY_CFBundleDisplayName": "LumaLilt",
    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.puzzle-games",
    "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption": "NO",
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
    "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "UIInterfaceOrientationPortrait",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight",
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon", "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "SUPPORTS_MACCATALYST": "YES", "DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER": "YES",
    "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/Frameworks"})
test_configs = configs("tests", {
    "PRODUCT_BUNDLE_IDENTIFIER": "com.mackinnontech.LumaLiltTests", "PRODUCT_NAME": "$(TARGET_NAME)",
    "GENERATE_INFOPLIST_FILE": "YES", "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/LumaLilt.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/LumaLilt",
    "BUNDLE_LOADER": "$(TEST_HOST)", "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/Frameworks @loader_path/Frameworks"})
app = add("app-target", "PBXNativeTarget", buildConfigurationList=app_configs, buildPhases=app_phases,
          buildRules=[], dependencies=[], name="LumaLilt", productName="LumaLilt", productReference=app_product, productType="com.apple.product-type.application")
proxy = add("proxy", "PBXContainerItemProxy", containerPortal=uid("project"), proxyType="1", remoteGlobalIDString=app, remoteInfo="LumaLilt")
dependency = add("dependency", "PBXTargetDependency", target=app, targetProxy=proxy)
tests = add("test-target", "PBXNativeTarget", buildConfigurationList=test_configs, buildPhases=test_phases,
            buildRules=[], dependencies=[dependency], name="LumaLiltTests", productName="LumaLiltTests", productReference=test_product, productType="com.apple.product-type.bundle.unit-test")
project = add("project", "PBXProject", attributes={"BuildIndependentTargetsInParallel": "YES", "LastUpgradeCheck": "1600",
              "TargetAttributes": {app: {"CreatedOnToolsVersion": "16.0"}, tests: {"CreatedOnToolsVersion": "16.0", "TestTargetID": app}}},
              buildConfigurationList=project_configs, compatibilityVersion="Xcode 14.0", developmentRegion="en", hasScannedForEncodings="0",
              knownRegions=["en", "Base"], mainGroup=main, productRefGroup=products, projectDirPath="", projectRoot="", targets=[app, tests])

def encode(value, depth=0):
    tab = "\t" * depth
    if isinstance(value, dict):
        return "{\n" + "".join(f'{tab}\t{json.dumps(k)} = {encode(v, depth + 1)};\n' for k, v in value.items()) + tab + "}"
    if isinstance(value, list):
        return "(\n" + "".join(f'{tab}\t{encode(v, depth + 1)},\n' for v in value) + tab + ")"
    return json.dumps(str(value))

project_dir = ROOT / "LumaLilt.xcodeproj"
project_dir.mkdir(exist_ok=True)
(project_dir / "project.pbxproj").write_text("// !$*UTF8*$!\n" + encode({"archiveVersion": "1", "classes": {}, "objectVersion": "56", "objects": objects, "rootObject": project}) + "\n")
scheme_dir = project_dir / "xcshareddata/xcschemes"
scheme_dir.mkdir(parents=True, exist_ok=True)
app_ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app}" BuildableName="LumaLilt.app" BlueprintName="LumaLilt" ReferencedContainer="container:LumaLilt.xcodeproj"/>'
test_ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{tests}" BuildableName="LumaLiltTests.xctest" BlueprintName="LumaLiltTests" ReferencedContainer="container:LumaLilt.xcodeproj"/>'
(scheme_dir / "LumaLilt.xcscheme").write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
    <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{app_ref}</BuildActionEntry>
  </BuildActionEntries></BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{test_ref}</TestableReference></Testables></TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugServiceExtension="internal"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print(f"Generated {project_dir} ({len(objects)} objects)")
