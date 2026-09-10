#!/usr/bin/env python3
"""Structural checks only; this does not replace a Swift compiler or native UI test."""
from pathlib import Path
import json
import plistlib
import re
import struct
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
project = (root / "LumaLilt.xcodeproj/project.pbxproj").read_text()
ids = set(re.findall(r'"([A-F0-9]{24})" = \{\s*"isa"', project))
refs = set(re.findall(r'"([A-F0-9]{24})"', project))
assert refs == ids, f"Dangling references: {refs - ids}"
sources = sorted((root / "LumaLilt").rglob("*.swift"))
for source in sources:
    assert json.dumps(str(source.relative_to(root / "LumaLilt"))) in project, f"Missing source {source}"
assert project.count('"isa" = "PBXNativeTarget"') == 2
assert '"ASSETCATALOG_COMPILER_APPICON_NAME" = "AppIcon"' in project
scheme = ET.parse(root / "LumaLilt.xcodeproj/xcshareddata/xcschemes/LumaLilt.xcscheme")
for ref in scheme.findall('.//BuildableReference'):
    assert ref.attrib['BlueprintIdentifier'] in ids
for metadata in root.rglob("Contents.json"):
    catalog = json.loads(metadata.read_text())
    for item in catalog.get('images', []):
        assert (metadata.parent / item['filename']).is_file(), item
png = (root / 'LumaLilt/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png').read_bytes()
assert png[:8] == b'\x89PNG\r\n\x1a\n'
assert struct.unpack('>II', png[16:24]) == (1024, 1024)
assert png[25] == 2, 'Icon must be RGB, without alpha'
privacy = plistlib.loads((root / 'LumaLilt/Resources/PrivacyInfo.xcprivacy').read_bytes())
assert privacy['NSPrivacyTracking'] is False
assert privacy['NSPrivacyAccessedAPITypes'][0]['NSPrivacyAccessedAPITypeReasons'] == ['CA92.1']
test_count = len(re.findall(r'func test\w+\(', (root / 'Tests/PuzzleTests.swift').read_text()))
assert test_count >= 12, 'Expected original tests plus build 3 regression tests'
for source in sources:
    text = source.read_text()
    assert not re.search(r'\b(URLSession|WKWebView|import Firebase|fatalError)\b', text), source
print(f'PASS: {len(sources)} Swift source references, {len(ids)} project objects, shared scheme, {test_count} declared tests, asset catalog, RGB 1024 icon, privacy manifest.')
print('Swift compilation, XCTest execution, and simulator/device UI checks require Xcode and were not performed by this script.')
