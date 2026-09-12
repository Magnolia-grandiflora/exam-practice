import 'dart:io';

import 'package:flutter/services.dart';

/// Windows-only native image chooser for the packaged paper OMR sidecar.
class WindowsOmrFilePicker {
  const WindowsOmrFilePicker._();

  static const _channel = MethodChannel('personal_exam/windows_omr');

  static Future<File?> pickImage() async {
    if (!Platform.isWindows) {
      throw PlatformException(
        code: 'unsupported_platform',
        message: '答题卡阅卷文件选择仅在 Windows 端开放',
      );
    }
    final path = await _channel.invokeMethod<String>('chooseImage');
    if (path == null || path.isEmpty) return null;
    return File(path);
  }

  /// Reads either a clipboard bitmap (screenshots, chat images) or one copied
  /// PNG/JPG file. Clipboard bitmaps are encoded to a temporary PNG by Windows.
  static Future<File?> pasteImage() async {
    if (!Platform.isWindows) {
      throw PlatformException(
        code: 'unsupported_platform',
        message: '剪贴板图片导入仅在 Windows 端开放',
      );
    }
    final path = await _channel.invokeMethod<String>('pasteImage');
    if (path == null || path.isEmpty) return null;
    return File(path);
  }

  static bool isTemporaryClipboardImage(File file) {
    final temp = Directory.systemTemp.path.toLowerCase();
    final parent = file.parent.path.toLowerCase();
    final name = file.uri.pathSegments.last.toLowerCase();
    return parent == temp && name.startsWith('pex') && name.endsWith('.png');
  }
}
