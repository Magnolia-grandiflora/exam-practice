#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  HANDLE single_instance_mutex =
      ::CreateMutexW(nullptr, TRUE, L"Local\\PersonalExamApp.SingleInstance");
  if (single_instance_mutex == nullptr) {
    ::MessageBoxW(nullptr, L"\u65e0\u6cd5\u68c0\u67e5\u7a0b\u5e8f\u8fd0\u884c\u72b6\u6001\u3002",
                  L"\u4e2a\u4eba\u5237\u9898", MB_OK | MB_ICONERROR);
    return EXIT_FAILURE;
  }
  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND existing_window = ::FindWindowW(nullptr, L"\u4e2a\u4eba\u5237\u9898");
    if (existing_window != nullptr) {
      ::ShowWindow(existing_window, SW_RESTORE);
      ::SetForegroundWindow(existing_window);
    }
    ::CloseHandle(single_instance_mutex);
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

#if defined(NDEBUG)
  // Flutter 3.44 on Windows can hit a native 0xc0000005 crash in the Impeller
  // renderer during a redraw after bursty FFI/network work. Keep release builds
  // on the stable renderer and platform UI thread until the engine fix lands.
  ::SetEnvironmentVariableW(L"FLUTTER_ENGINE_SWITCHES", L"2");
  ::SetEnvironmentVariableW(L"FLUTTER_ENGINE_SWITCH_1",
                            L"enable-impeller=false");
  // This app is text-first. Prefer the Skia software backend to avoid the
  // flutter_windows.dll GPU crash seen on this Windows 11 / Flutter 3.44 host.
  ::SetEnvironmentVariableW(L"FLUTTER_ENGINE_SWITCH_2",
                            L"enable-software-rendering=true");
#endif

  flutter::DartProject project(L"data");

#if defined(NDEBUG)
  project.set_gpu_preference(flutter::GpuPreference::LowPowerPreference);
  project.set_ui_thread_policy(flutter::UIThreadPolicy::RunOnPlatformThread);
#endif

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  // Use Unicode escapes as well as the /utf-8 compiler option so the native
  // title remains correct regardless of the machine's legacy code page.
  if (!window.Create(L"\u9898\u5e8f / Exam Practice", origin, size)) {
    ::ReleaseMutex(single_instance_mutex);
    ::CloseHandle(single_instance_mutex);
    ::CoUninitialize();
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  ::ReleaseMutex(single_instance_mutex);
  ::CloseHandle(single_instance_mutex);
  return EXIT_SUCCESS;
}
