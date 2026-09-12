/// 面向用户显示的应用版本号。
///
/// 发布脚本从 pubspec.yaml 读取版本并通过 `--dart-define=APP_VERSION=` 注入；
/// 未注入时（如 `flutter run` 调试）显示"开发版"，避免出现与产物不符的写死数字。
const String kAppVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '开发版',
);
