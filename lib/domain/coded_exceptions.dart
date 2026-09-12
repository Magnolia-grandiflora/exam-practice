/// 携带稳定错误码与占位参数的异常家族。
///
/// 约定：
/// - `code` 是跨语言、跨版本稳定的点分码（如 `omr.recognize.timeout`），
///   UI 层据此把用户可见文本映射到本地化资源（见 `lib/ui/error_messages.dart`）。
/// - 中文 `message` 与继承自标准异常的 `toString()` 输出是技术诊断，
///   与迁移前逐字一致，测试与日志依赖它们。
/// - [params] 按位置对应本地化消息中的占位符；无占位符时保持空列表。
/// - 全部子类继承标准异常类型，既有的 `is`/`throwsA` 类型捕获不受影响。
library;

import 'dart:async';
import 'dart:io';

/// 带稳定码的 [FormatException]。
class CodedFormatException extends FormatException {
  const CodedFormatException(this.code, String message, [this.params = const []])
    : super(message);

  final String code;
  final List<Object> params;
}

/// 带稳定码的 [StateError]。
class CodedStateError extends StateError {
  CodedStateError(this.code, String message, [this.params = const []])
    : super(message);

  final String code;
  final List<Object> params;
}

/// 带稳定码的 [UnsupportedError]。
class CodedUnsupportedError extends UnsupportedError {
  CodedUnsupportedError(this.code, String message, [this.params = const []])
    : super(message);

  final String code;
  final List<Object> params;
}

/// 带稳定码的 [TimeoutException]。
class CodedTimeoutException extends TimeoutException {
  CodedTimeoutException(
    this.code,
    String message, [
    Duration? duration,
    this.params = const [],
  ]) : super(message, duration);

  final String code;
  final List<Object> params;
}

/// 带稳定码的 [FileSystemException]。
class CodedFileSystemException extends FileSystemException {
  const CodedFileSystemException(
    this.code,
    String message, [
    String? path,
    this.params = const [],
  ]) : super(message, path);

  final String code;
  final List<Object> params;
}
