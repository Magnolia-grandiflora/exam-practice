#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include <memory>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Native close interception without a third-party plugin. Dart asks the user
  // whether pending local outbox data should be synced before allowing WM_CLOSE.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> close_channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> storage_channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> omr_channel_;
  bool close_allowed_ = false;
  bool close_request_pending_ = false;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
