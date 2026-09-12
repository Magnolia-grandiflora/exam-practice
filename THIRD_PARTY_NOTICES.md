# Third-party notices

## Packaged paper OMR sidecar (paper_omr_bridge)

The Windows paper answer-sheet sidecar (`tool/paper_omr_bridge/`) is implemented
for this project directly on top of OpenCV and NumPy. It does not include
third-party OMR source. See `docs/omr-decoupling.md` for the source review and
its historical verification limits. The sidecar accepts only
PNG/JPG/JPEG images and never processes PDF input; its build and runtime are
checked to be free of PyMuPDF/Fitz.

## Packaged Python dependencies

The sidecar build uses the top-level pins in
`tool/paper_omr_bridge/requirements.lock` together with the resolved
transitive pins in `tool/paper_omr_bridge/constraints.lock`.
The declared runtime packages do not include PyMuPDF or Fitz.

| Component | License |
| --- | --- |
| numpy | BSD-3-Clause |
| opencv-python-headless packaging | MIT; bundled libraries have separate notices |
| OpenCV | Apache-2.0; see the wheel's LICENSE-3RD-PARTY.txt for bundled components |
| Python runtime | PSF license and bundled third-party notices |
| PyInstaller | GPL-2.0-or-later with bootloader exception |

PyInstaller's license permits distributing the frozen executable it produces;
the bootloader exception covers the static bootloader code embedded in the
frozen `paper_omr_bridge.exe`. The application itself does not link or bundle
any PyInstaller code beyond that frozen helper executable.

## Flutter / Dart packages

Dart dependencies are declared in `pubspec.yaml` with resolved versions in
`pubspec.lock`. `flutter pub deps` lists dependencies, not their license terms.
Preserve Flutter's generated `data/flutter_assets/NOTICES.Z` in Windows bundles
and the corresponding assets in APKs. Each resolved package's LICENSE remains
applicable; the project LICENSE does not replace dependency licenses.

## Distribution materials

The Windows release script includes the project LICENSE, this file, and
`licenses/python/`: original LICENSE/COPYING/NOTICE texts collected from the
installed wheels (including bundled library notices) and Python runtime.
The manifest records distribution versions and SHA-256 hashes. Build-tool
notices are included as well; this does not imply all tools are linked into the app.

To collect these separately with the same Python interpreter as the sidecar build:

```powershell
python tool/paper_omr_bridge/collect_licenses.py --runtime tool/paper_omr_bridge/runtime-build --output build/license-review
```

If skipping the sidecar build, retain its matching runtime-build environment.
Existing release archives are not updated by editing this file. Generate a clean
release before distribution; do not use build-skip options for the first public release.
