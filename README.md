# zig-android

Build Android apps with the Zig build system. No Gradle, no Android Studio required.

`zig-android` is a Zig build-system package that handles Android SDK/NDK discovery,
cross-compilation, manifest generation, and APK packaging — letting you build, sign,
and deploy Android apps entirely from `zig build`.

## Features

- **Automatic SDK/NDK discovery** — finds your Android SDK and NDK via environment
  variables, default install paths, or `PATH`
- **Cross-compilation** — builds native shared libraries for `x86_64` and `aarch64`
  Android targets with proper NDK sysroot configuration
- **Type-safe manifest generation** — write your `AndroidManifest.xml` as Zig structs
  with compile-time validation, predefined constants for permissions, actions, and
  categories
- **Full APK pipeline** — `aapt package` → `zipalign` → `apksigner` in a single
  `zig build` invocation
- **Multi-ABI support** — build native libraries for multiple architectures and bundle
  them into a single APK

## Requirements

- [Zig](https://ziglang.org/download/) 0.15.1 or later
- Android SDK and NDK — install via [Android Studio](https://developer.android.com/studio):
  1. Install Android Studio
  2. Open **Settings → Languages & Frameworks → Android SDK**
  3. Under **SDK Platforms**, install the API level you're targeting (e.g., Android 9.0 / API 28)
  4. Under **SDK Tools**, make sure these are installed:
     - **Android SDK Build-Tools** (includes `aapt`, `zipalign`, `apksigner`)
     - **Android SDK Platform-Tools** (includes `adb`)
     - **NDK (Side by side)**
  5. Note your SDK path (shown at the top of the settings page), or set the
     `ANDROID_HOME` environment variable to it

  > You can also install the SDK without Android Studio using the
  > [command-line tools](https://developer.android.com/studio#command-line-tools-only)
  > and `sdkmanager`.

The SDK is discovered automatically. Set `ANDROID_HOME` or `ANDROID_SDK_ROOT` if
auto-detection doesn't work. Similarly, set `ANDROID_NDK_HOME` to override NDK
discovery.

## Quick Start

Add `zig-android` as a dependency in your `build.zig.zon`:

```sh
zig fetch --save git+https://github.com/shreyassanthu77/zig-android
```

Then in your `build.zig`:

```zig
const std = @import("std");
const android = @import("zig_android");

pub fn build(b: *std.Build) void {
    const sdk = android.Sdk.init(b, 28); // API level 28

    const app = sdk.createApp(.{
        .manifest = .{
            .package = "com.example.myapp",
            .uses_sdk = .{
                .android_minSdkVersion = 24,
                .android_targetSdkVersion = 29,
            },
            .application = .{
                .android_label = "My App",
                .android_hasCode = false,
                .activity = &.{.{
                    .android_name = "android.app.NativeActivity",
                    .android_configChanges = &.{
                        .orientation,
                        .keyboardHidden,
                        .screenSize,
                    },
                    .meta_data = &.{.{
                        .android_name = "android.app.lib_name",
                        .android_value = "main",
                    }},
                    .intent_filter = &.{android.Manifest.IntentFilter.main_launcher},
                }},
            },
        },
    });

    // Build the native library for both x86_64 and arm64
    const targets: []const std.Target.Query = &.{
        .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .android },
        .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .android },
    };

    for (targets) |query| {
        _ = app.addLibrary(.{
            .name = "main",
            .root_module = .{
                .root_source_file = b.path("src/main.zig"),
                .target = b.resolveTargetQuery(query),
                .optimize = b.standardOptimizeOption(.{}),
            },
        });
    }

    app.installApk(".");
}
```

And in `src/main.zig`, implement the NativeActivity entry point:

```zig
const c = @cImport({
    @cInclude("android/native_activity.h");
    @cInclude("android/log.h");
});

fn logInfo(msg: [*:0]const u8) void {
    _ = c.__android_log_print(c.ANDROID_LOG_INFO, "myapp", msg);
}

export fn ANativeActivity_onCreate(
    activity: [*c]c.ANativeActivity,
    _: ?*anyopaque,
    _: usize,
) callconv(.c) void {
    logInfo("App started!");

    activity.*.callbacks.*.onStart = struct {
        fn f(_: [*c]c.ANativeActivity) callconv(.c) void {
            logInfo("onStart");
        }
    }.f;

    activity.*.callbacks.*.onResume = struct {
        fn f(_: [*c]c.ANativeActivity) callconv(.c) void {
            logInfo("onResume");
        }
    }.f;

    activity.*.callbacks.*.onNativeWindowCreated = struct {
        fn f(_: [*c]c.ANativeActivity, _: ?*c.ANativeWindow) callconv(.c) void {
            logInfo("onNativeWindowCreated");
        }
    }.f;
}
```

## Usage

### Build

```sh
zig build
```

This produces a signed, aligned APK at `zig-out/<package>.apk`.

### Install on device

```sh
adb install zig-out/com.example.myapp.apk
```

### View logs

```sh
adb logcat -s myapp
```

## API

### `Sdk`

The main entry point. Handles SDK/NDK discovery and provides build helpers.

```zig
const sdk = android.Sdk.init(b, api_level);
```

- **`sdk.createApp(opts)`** — creates an `Application` builder with the given manifest
- **`sdk.addLibrary(opts)`** — cross-compiles a library with NDK include/lib paths configured
- **`sdk.addRunBuildTool(name)`** — returns a `*std.Build.Step.Run` for an SDK build tool (e.g., `"aapt"`, `"zipalign"`)
- **`sdk.addRunPlatformTool(name)`** — returns a `*std.Build.Step.Run` for a platform tool (e.g., `"adb"`)
- **`sdk.getDebugKeystore()`** — returns a `LazyPath` to a generated debug keystore for APK signing

### `Application`

The APK builder. Created via `sdk.createApp()`.

- **`app.addLibrary(opts)`** — adds a native shared library to the APK. Automatically links `-lc`, `-llog`, and `-landroid`. Returns `*std.Build.Step.Compile` so you can link additional system libraries (e.g., `EGL`, `GLESv2`)
- **`app.installApk(dest)`** — installs the signed APK to `zig-out/<dest>/`

### `Manifest`

A type-safe representation of `AndroidManifest.xml`. All fields map directly to Android manifest attributes and elements, with Zig naming conventions (`android_label` becomes `android:label`, `intent_filter` becomes `<intent-filter>`).

Includes predefined constants for common values:

```zig
// Permissions
.uses_permission = &.{
    android.Manifest.UsesPermission.internet,
    android.Manifest.UsesPermission.camera,
},

// Intent filters
.intent_filter = &.{android.Manifest.IntentFilter.main_launcher},

// Actions and categories
const Action = android.Manifest.Action;
const Category = android.Manifest.Category;
```

## SDK Discovery

The SDK is located in this order:

1. `ANDROID_HOME` environment variable
2. `ANDROID_SDK_ROOT` environment variable
3. Default paths:
   - Linux: `~/Android/Sdk`
   - macOS: `~/Library/Android/sdk`
   - Windows: `%LOCALAPPDATA%\Android\Sdk`
4. Searching `PATH` for `adb` or `aapt`

NDK discovery:

1. `ANDROID_NDK_HOME` environment variable
2. `ANDROID_NDK_PATH` environment variable
3. `ANDROID_NDK_ROOT` environment variable
4. `<sdk>/ndk/<latest-version>/`

## License

MIT
