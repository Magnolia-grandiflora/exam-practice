#include "flutter_window.h"

#include <flutter/standard_method_codec.h>
#include <shobjidl.h>
#include <shellapi.h>
#include <wincodec.h>
#include <algorithm>
#include <cwctype>
#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "utils.h"

namespace {
std::optional<std::string> ChooseDirectory(HWND owner) {
  IFileDialog* dialog = nullptr;
  HRESULT result = CoCreateInstance(CLSID_FileOpenDialog, nullptr,
                                    CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&dialog));
  if (FAILED(result) || dialog == nullptr) return std::nullopt;

  DWORD options = 0;
  dialog->GetOptions(&options);
  dialog->SetOptions(options | FOS_PICKFOLDERS | FOS_FORCEFILESYSTEM);
  result = dialog->Show(owner);
  if (result == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
    dialog->Release();
    return std::nullopt;
  }
  if (FAILED(result)) {
    dialog->Release();
    return std::nullopt;
  }

  IShellItem* item = nullptr;
  result = dialog->GetResult(&item);
  dialog->Release();
  if (FAILED(result) || item == nullptr) return std::nullopt;

  PWSTR path = nullptr;
  result = item->GetDisplayName(SIGDN_FILESYSPATH, &path);
  item->Release();
  if (FAILED(result) || path == nullptr) return std::nullopt;
  const std::string utf8_path = Utf8FromUtf16(path);
  CoTaskMemFree(path);
  return utf8_path;
}

std::optional<std::string> ChooseQuestionBankFile(HWND owner) {
  IFileDialog* dialog = nullptr;
  HRESULT result = CoCreateInstance(CLSID_FileOpenDialog, nullptr,
                                    CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&dialog));
  if (FAILED(result) || dialog == nullptr) return std::nullopt;

  DWORD options = 0;
  dialog->GetOptions(&options);
  dialog->SetOptions(options | FOS_FILEMUSTEXIST | FOS_PATHMUSTEXIST |
                     FOS_FORCEFILESYSTEM);
  const COMDLG_FILTERSPEC file_types[] = {
      {L"题库文件", L"*.zip;*.tsv;*.csv"},
      {L"所有文件", L"*.*"},
  };
  dialog->SetFileTypes(2, file_types);
  dialog->SetFileTypeIndex(1);
  dialog->SetTitle(L"选择要导入的题库文件");
  result = dialog->Show(owner);
  if (result == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
    dialog->Release();
    return std::nullopt;
  }
  if (FAILED(result)) {
    dialog->Release();
    return std::nullopt;
  }

  IShellItem* item = nullptr;
  result = dialog->GetResult(&item);
  dialog->Release();
  if (FAILED(result) || item == nullptr) return std::nullopt;

  PWSTR path = nullptr;
  result = item->GetDisplayName(SIGDN_FILESYSPATH, &path);
  item->Release();
  if (FAILED(result) || path == nullptr) return std::nullopt;
  const std::string utf8_path = Utf8FromUtf16(path);
  CoTaskMemFree(path);
  return utf8_path;
}

std::optional<std::string> ChooseOmrImageFile(HWND owner) {
  IFileDialog* dialog = nullptr;
  HRESULT result = CoCreateInstance(CLSID_FileOpenDialog, nullptr,
                                    CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&dialog));
  if (FAILED(result) || dialog == nullptr) return std::nullopt;
  DWORD options = 0;
  dialog->GetOptions(&options);
  dialog->SetOptions(options | FOS_FILEMUSTEXIST | FOS_PATHMUSTEXIST |
                     FOS_FORCEFILESYSTEM);
  const COMDLG_FILTERSPEC file_types[] = {
      {L"OMR images", L"*.png;*.jpg;*.jpeg"},
      {L"All files", L"*.*"},
  };
  dialog->SetFileTypes(2, file_types);
  dialog->SetFileTypeIndex(1);
  dialog->SetTitle(L"Select OMR image");
  result = dialog->Show(owner);
  if (result == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
    dialog->Release();
    return std::nullopt;
  }
  if (FAILED(result)) {
    dialog->Release();
    return std::nullopt;
  }
  IShellItem* item = nullptr;
  result = dialog->GetResult(&item);
  dialog->Release();
  if (FAILED(result) || item == nullptr) return std::nullopt;
  PWSTR path = nullptr;
  result = item->GetDisplayName(SIGDN_FILESYSPATH, &path);
  item->Release();
  if (FAILED(result) || path == nullptr) return std::nullopt;
  const std::string utf8_path = Utf8FromUtf16(path);
  CoTaskMemFree(path);
  return utf8_path;
}

bool IsSupportedImagePath(const std::wstring& path) {
  const size_t dot = path.find_last_of(L'.');
  if (dot == std::wstring::npos) return false;
  std::wstring extension = path.substr(dot);
  std::transform(extension.begin(), extension.end(), extension.begin(),
                 [](wchar_t value) { return std::towlower(value); });
  return extension == L".png" || extension == L".jpg" ||
         extension == L".jpeg";
}

std::optional<std::string> PasteOmrImage(HWND owner, std::string* error) {
  if (!OpenClipboard(owner)) {
    *error = "无法打开 Windows 剪贴板";
    return std::nullopt;
  }

  // Copying a JPG/PNG in Explorer puts an HDROP file list on the clipboard.
  if (HANDLE files = GetClipboardData(CF_HDROP)) {
    const HDROP drop = static_cast<HDROP>(files);
    if (DragQueryFileW(drop, 0xFFFFFFFF, nullptr, 0) == 1) {
      const UINT length = DragQueryFileW(drop, 0, nullptr, 0);
      std::wstring path(length + 1, L'\0');
      DragQueryFileW(drop, 0, path.data(), length + 1);
      path.resize(length);
      if (IsSupportedImagePath(path)) {
        CloseClipboard();
        return Utf8FromUtf16(path.c_str());
      }
    }
  }

  const HBITMAP clipboard_bitmap =
      static_cast<HBITMAP>(GetClipboardData(CF_BITMAP));
  if (clipboard_bitmap == nullptr) {
    CloseClipboard();
    *error = "剪贴板中没有图片或 PNG/JPG 图片文件";
    return std::nullopt;
  }

  IWICImagingFactory* factory = nullptr;
  IWICBitmap* bitmap = nullptr;
  HRESULT result = CoCreateInstance(CLSID_WICImagingFactory, nullptr,
                                    CLSCTX_INPROC_SERVER,
                                    IID_PPV_ARGS(&factory));
  if (SUCCEEDED(result)) {
    result = factory->CreateBitmapFromHBITMAP(
        clipboard_bitmap, nullptr, WICBitmapIgnoreAlpha, &bitmap);
  }
  CloseClipboard();
  if (FAILED(result) || factory == nullptr || bitmap == nullptr) {
    if (bitmap) bitmap->Release();
    if (factory) factory->Release();
    *error = "无法读取剪贴板图片";
    return std::nullopt;
  }

  wchar_t temp_directory[MAX_PATH] = {};
  wchar_t temp_name[MAX_PATH] = {};
  if (GetTempPathW(MAX_PATH, temp_directory) == 0 ||
      GetTempFileNameW(temp_directory, L"pex", 0, temp_name) == 0) {
    bitmap->Release();
    factory->Release();
    *error = "无法创建剪贴板临时图片";
    return std::nullopt;
  }
  DeleteFileW(temp_name);
  std::wstring png_path(temp_name);
  const size_t dot = png_path.find_last_of(L'.');
  png_path = png_path.substr(0, dot) + L".png";

  IWICStream* stream = nullptr;
  IWICBitmapEncoder* encoder = nullptr;
  IWICBitmapFrameEncode* frame = nullptr;
  IPropertyBag2* properties = nullptr;
  result = factory->CreateStream(&stream);
  if (SUCCEEDED(result)) {
    result = stream->InitializeFromFilename(png_path.c_str(), GENERIC_WRITE);
  }
  if (SUCCEEDED(result)) {
    result = factory->CreateEncoder(GUID_ContainerFormatPng, nullptr, &encoder);
  }
  if (SUCCEEDED(result)) {
    result = encoder->Initialize(stream, WICBitmapEncoderNoCache);
  }
  if (SUCCEEDED(result)) {
    result = encoder->CreateNewFrame(&frame, &properties);
  }
  if (SUCCEEDED(result)) result = frame->Initialize(properties);
  UINT width = 0;
  UINT height = 0;
  if (SUCCEEDED(result)) result = bitmap->GetSize(&width, &height);
  if (SUCCEEDED(result)) result = frame->SetSize(width, height);
  WICPixelFormatGUID pixel_format = GUID_WICPixelFormat32bppBGRA;
  if (SUCCEEDED(result)) result = frame->SetPixelFormat(&pixel_format);
  if (SUCCEEDED(result)) result = frame->WriteSource(bitmap, nullptr);
  if (SUCCEEDED(result)) result = frame->Commit();
  if (SUCCEEDED(result)) result = encoder->Commit();

  if (properties) properties->Release();
  if (frame) frame->Release();
  if (encoder) encoder->Release();
  if (stream) stream->Release();
  bitmap->Release();
  factory->Release();
  if (FAILED(result)) {
    DeleteFileW(png_path.c_str());
    *error = "无法将剪贴板图片转换为 PNG";
    return std::nullopt;
  }
  return Utf8FromUtf16(png_path.c_str());
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  close_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "personal_exam/window",
          &flutter::StandardMethodCodec::GetInstance());
  close_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        if (call.method_name() == "allowClose") {
          close_allowed_ = true;
          close_request_pending_ = false;
          result->Success();
          PostMessage(GetHandle(), WM_CLOSE, 0, 0);
        } else if (call.method_name() == "cancelClose") {
          close_request_pending_ = false;
          result->Success();
        } else {
          result->NotImplemented();
        }
      });
  storage_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "personal_exam/storage",
          &flutter::StandardMethodCodec::GetInstance());
  storage_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        if (call.method_name() == "chooseQuestionBankFile") {
          const auto path = ChooseQuestionBankFile(GetHandle());
          if (path.has_value()) {
            result->Success(flutter::EncodableValue(path.value()));
          } else {
            result->Success();
          }
          return;
        }
        if (call.method_name() != "chooseDirectory") {
          result->NotImplemented();
          return;
        }
        const auto path = ChooseDirectory(GetHandle());
        if (path.has_value()) {
          result->Success(flutter::EncodableValue(path.value()));
        } else {
          result->Success();
        }
      });
  omr_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "personal_exam/windows_omr",
          &flutter::StandardMethodCodec::GetInstance());
  omr_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        if (call.method_name() == "pasteImage") {
          std::string error;
          const auto path = PasteOmrImage(GetHandle(), &error);
          if (path) {
            result->Success(flutter::EncodableValue(*path));
          } else {
            result->Error("clipboard_image_unavailable", error);
          }
          return;
        }
        if (call.method_name() != "chooseImage") {
          result->NotImplemented();
          return;
        }
        const auto path = ChooseOmrImageFile(GetHandle());
        if (path.has_value()) {
          result->Success(flutter::EncodableValue(path.value()));
        } else {
          result->Success();
        }
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  omr_channel_.reset();
  storage_channel_.reset();
  close_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_CLOSE:
      if (!close_allowed_ && close_channel_) {
        if (!close_request_pending_) {
          close_request_pending_ = true;
          close_channel_->InvokeMethod("requestClose", nullptr);
        }
        return 0;
      }
      break;
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
