const std = @import("std");
const builtin = @import("builtin");
pub const Application = @import("apk.zig");

build: *std.Build,
sdk_paths: *SdkPaths,

pub fn init(b: *std.Build, api_level: u32) @This() {
    const sdk_paths = try SdkPaths.init(b, api_level);
    return .{
        .build = b,
        .sdk_paths = sdk_paths,
    };
}

pub fn addRunBuildTool(self: *@This(), name: []const u8) *std.Build.Step.Run {
    const b = self.build;
    const run_cmd = b.addSystemCommand(&.{name});
    run_cmd.argv.clearRetainingCapacity();
    run_cmd.addFileArg(self.sdk_paths.build_tools.path(self.build, name));
    return run_cmd;
}

pub fn addRunPlatformTool(self: *@This(), name: []const u8) *std.Build.Step.Run {
    const b = self.build;
    const run_cmd = b.addSystemCommand(&.{name});
    run_cmd.argv.clearRetainingCapacity();
    run_cmd.addFileArg(self.sdk_paths.platform_tools.path(self.build, name));
    return run_cmd;
}

pub fn addLibrary(self: *@This(), options: std.Build.LibraryOptions) *std.Build.Step.Compile {
    const b = self.build;
    const target = options.root_module.resolved_target orelse {
        @panic("root_module.resolved_target is null");
    };
    const lib_paths = switch (target.result.cpu.arch) {
        .x86_64 => &self.sdk_paths.lib_paths.x86_64,
        .aarch64 => &self.sdk_paths.lib_paths.aarch64,
        else => @panic(b.fmt("unsupported target arch: {}", .{target.result.cpu.arch})),
    };

    const android_target = switch (target.result.cpu.arch) {
        .x86_64 => b.resolveTargetQuery(.{
            .cpu_arch = .x86_64,
            .os_tag = .linux,
            .abi = .android,
            .android_api_level = self.sdk_paths.api_level,
        }),
        .aarch64 => b.resolveTargetQuery(.{
            .cpu_arch = .aarch64,
            .os_tag = .linux,
            .abi = .android,
            .android_api_level = self.sdk_paths.api_level,
        }),
        else => unreachable,
    };

    var root_module = options.root_module;
    root_module.resolved_target = android_target;
    root_module.addIncludePath(lib_paths.include_dir);
    root_module.addIncludePath(lib_paths.sys_include_dir);
    root_module.addLibraryPath(lib_paths.crt_dir);

    var opts = options;
    opts.root_module = root_module;

    const lib = b.addLibrary(opts);
    lib.setLibCFile(lib_paths.libc_file);
    lib.step.dependOn(&self.sdk_paths.step);

    return lib;
}

pub fn createApp(self: *@This(), options: Application.CreateOptions) !*Application {
    return Application.create(self, options);
}

pub fn getDebugKeystore(self: *@This()) std.Build.LazyPath {
    const b = self.build;

    // Generate a debug keystore in the build cache using keytool.
    // Uses the same defaults as the standard Android debug keystore:
    //   alias=androiddebugkey, password=android, CN=Android Debug
    const keytool = b.addSystemCommand(&.{
        "keytool",
        "-genkeypair",
        "-dname",
        "CN=Android Debug,O=Android,C=US",
        "-keystore",
    });

    if (builtin.zig_version.major == 0 and builtin.zig_version.minor <= 15) {
        _ = keytool.captureStdErr();
    } else {
        _ = keytool.captureStdOut(.{});
    }

    const keystore = keytool.addOutputFileArg("debug.keystore");
    keytool.addArgs(&.{
        "-alias",     "androiddebugkey",
        "-keypass",   "android",
        "-storepass", "android",
        "-keyalg",    "RSA",
        "-keysize",   "2048",
        "-validity",  "10000",
    });

    return keystore;
}

const SdkPaths = struct {
    step: std.Build.Step,
    api_level: u32,

    _sdk_dir: std.Build.GeneratedFile,
    sdk_root: std.Build.LazyPath,
    platform_tools: std.Build.LazyPath,

    _build_tools_dir: std.Build.GeneratedFile,
    build_tools: std.Build.LazyPath,

    _ndk_dir: std.Build.GeneratedFile,
    ndk_root: std.Build.LazyPath,

    android_jar: std.Build.LazyPath,

    _wf: *std.Build.Step.WriteFile,
    lib_paths: struct {
        x86_64: LibPath,
        aarch64: LibPath,
    },

    const LibPath = struct {
        resolved: bool = false,
        include_dir: std.Build.LazyPath,
        sys_include_dir: std.Build.LazyPath,
        crt_dir: std.Build.LazyPath,
        libc_file: std.Build.LazyPath,
    };

    fn init(b: *std.Build, api_level: u32) !*SdkPaths {
        const host_os = builtin.os.tag;
        const host_arch = builtin.cpu.arch;
        const prebuilt_dir = switch (host_os) {
            .linux => "linux-x86_64",
            .macos => if (host_arch == .aarch64) "darwin-arm64" else "darwin-x86_64",
            .windows => "windows-x86_64",
            else => return error.UnsupportedHostOs,
        };
        const sysroot = b.pathJoin(&.{
            "toolchains/llvm/prebuilt",
            prebuilt_dir,
            "sysroot",
        });

        const self = b.allocator.create(SdkPaths) catch @panic("OOM");
        self.* = .{
            .step = .init(.{
                .id = .custom,
                .name = "resolve-android-sdk",
                .owner = b,
                .makeFn = make,
            }),
            .api_level = api_level,

            ._sdk_dir = .{ .step = &self.step },
            .sdk_root = .{ .generated = .{ .file = &self._sdk_dir } },
            .platform_tools = self.sdk_root.path(b, "platform-tools"),

            ._build_tools_dir = .{ .step = &self.step },
            .build_tools = .{ .generated = .{ .file = &self._build_tools_dir } },

            ._ndk_dir = .{ .step = &self.step },
            .ndk_root = .{ .generated = .{ .file = &self._ndk_dir } },

            .android_jar = self.sdk_root.path(b, b.pathJoin(&.{
                "platforms",
                b.fmt("android-{d}", .{api_level}),
                "android.jar",
            })),

            ._wf = b.addWriteFiles(),
            .lib_paths = .{
                .x86_64 = .{
                    .include_dir = self.ndk_root.path(b, b.pathJoin(&.{ sysroot, "usr/include" })),
                    .sys_include_dir = self.lib_paths.x86_64.include_dir.path(b, "x86_64-linux-android"),
                    .crt_dir = self.ndk_root.path(b, b.pathJoin(&.{
                        sysroot,
                        "usr/lib",
                        "x86_64-linux-android",
                        b.fmt("{d}", .{self.api_level}),
                    })),
                    .libc_file = self._wf.getDirectory().path(b, "android-libc-x86_64.conf"),
                },
                .aarch64 = .{
                    .include_dir = self.ndk_root.path(b, b.pathJoin(&.{ sysroot, "usr/include" })),
                    .sys_include_dir = self.lib_paths.aarch64.include_dir.path(b, "aarch64-linux-android"),
                    .crt_dir = self.ndk_root.path(b, b.pathJoin(&.{
                        sysroot,
                        "usr/lib",
                        "aarch64-linux-android",
                        b.fmt("{d}", .{self.api_level}),
                    })),
                    .libc_file = self._wf.getDirectory().path(b, "android-libc-aarch64.conf"),
                },
            },
        };
        self._wf.step.dependOn(&self.step);

        return self;
    }

    fn make(step: *std.Build.Step, _: std.Build.Step.MakeOptions) !void {
        const b = step.owner;
        const self: *SdkPaths = @fieldParentPtr("step", step);

        // search for android sdk
        var env = if (@hasField(std.Build.Graph, "environ_map"))
            b.graph.environ_map
        else if (@hasField(std.Build.Graph, "env_map"))
            b.graph.env_map
        else
            @compileError("Unsupported Zig version");

        var maybe_android_sdk_root: ?[]const u8 = null;
        if (env.get("ANDROID_HOME")) |home| {
            maybe_android_sdk_root = home;
        } else if (env.get("ANDROID_SDK_ROOT")) |sdk_root| {
            maybe_android_sdk_root = sdk_root;
        } else if (env.get("HOME") orelse env.get("USERPROFILE")) |home| {
            maybe_android_sdk_root = switch (builtin.os.tag) {
                .linux, .freebsd, .openbsd => b.pathResolve(&.{ home, "Android", "Sdk" }),
                .macos => b.pathResolve(&.{ home, "Library", "Android", "sdk" }),
                .windows => blk: {
                    const local_appdata = env.get("LOCALAPPDATA") orelse return error.AndroidSdkNotFound;
                    break :blk b.pathResolve(&.{ local_appdata, "Android", "Sdk" });
                },
                else => return error.UnsupportedOs,
            };
        } else {}

        if (maybe_android_sdk_root == null or !try pathExists(b, maybe_android_sdk_root.?)) blk: {
            const maybe_adb_or_aapt = b.findProgram(&.{ "adb", "aapt" }, &[_][]const u8{}) catch break :blk;

            const exe_name = std.fs.path.basename(maybe_adb_or_aapt);
            if (std.mem.eql(u8, exe_name, "adb")) {
                const platform_tools_dir = std.fs.path.dirname(maybe_adb_or_aapt) orelse break :blk;
                const platform_tools_dir_basename = std.fs.path.basename(platform_tools_dir);
                if (!std.mem.eql(u8, platform_tools_dir_basename, "platform-tools")) break :blk;
                maybe_android_sdk_root = b.pathResolve(&.{ platform_tools_dir, ".." });
            } else if (std.mem.eql(u8, exe_name, "aapt")) {
                const build_tools_base = b.pathResolve(&.{ maybe_adb_or_aapt, "../.." });
                if (!std.mem.eql(u8, std.fs.path.basename(build_tools_base), "build-tools")) break :blk;
                maybe_android_sdk_root = b.pathResolve(&.{ build_tools_base, ".." });
            }
        }

        const android_sdk_root = if (maybe_android_sdk_root) |sdk_root| blk: {
            const platform_tools_dir = b.pathResolve(&.{ sdk_root, "platform-tools" });
            if (!try pathExists(b, platform_tools_dir)) {
                std.log.err("platform-tools directory not found at expected location '{s}'", .{platform_tools_dir});
                return error.AndroidSdkNotFound;
            }

            break :blk sdk_root;
        } else {
            std.log.warn("Android SDK not found. Please set ANDROID_SDK_ROOT environment variable.", .{});
            return error.AndroidSdkNotFound;
        };

        const build_tools_base = b.pathResolve(&.{ android_sdk_root, "build-tools" });
        if (!try pathExists(b, build_tools_base)) {
            std.log.err("build-tools directory not found at expected location '{s}'", .{build_tools_base});
            return error.AndroidSdkNotFound;
        }

        const latest_build_tools_version = try findLatestVersionDir(b, build_tools_base) orelse {
            std.log.err("build-tools directory is empty or contains no valid version directories. Please make sure the Android SDK is installed correctly.", .{});
            return error.AndroidSdkNotFound;
        };
        const build_tools_dir = b.pathResolve(&.{ build_tools_base, latest_build_tools_version });

        // search for ndk
        const ndk_root = blk: {
            const ndk_env_vars = [_][]const u8{ "ANDROID_NDK_HOME", "ANDROID_NDK_PATH", "ANDROID_NDK_ROOT" };
            for (ndk_env_vars) |env_var| {
                if (env.get(env_var)) |ndk_env| {
                    if (try pathExists(b, ndk_env)) {
                        // Check if this is a direct NDK root (has toolchains/ inside)
                        const toolchains = b.pathResolve(&.{ ndk_env, "toolchains" });
                        if (try pathExists(b, toolchains)) {
                            break :blk ndk_env;
                        }
                        // Otherwise treat it as a parent dir containing version subdirs
                        if (try findLatestVersionDir(b, ndk_env)) |ver| {
                            break :blk b.pathResolve(&.{ ndk_env, ver });
                        }
                    }
                    std.log.warn("{s} is set to '{s}' but does not point to a valid NDK installation.", .{ env_var, ndk_env });
                }
            }

            // Fallback: look in <sdk_root>/ndk/
            const ndk_base = b.pathResolve(&.{ android_sdk_root, "ndk" });
            if (!try pathExists(b, ndk_base)) {
                std.log.err("NDK not found. Please install the NDK or set ANDROID_NDK_HOME.", .{});
                return error.AndroidSdkNotFound;
            }
            const latest_ndk_version = try findLatestVersionDir(b, ndk_base) orelse {
                std.log.err("ndk directory is empty or contains no valid version directories. Please make sure the Android SDK is installed correctly.", .{});
                return error.AndroidSdkNotFound;
            };
            break :blk b.pathResolve(&.{ ndk_base, latest_ndk_version });
        };

        self._sdk_dir.path = android_sdk_root;
        self._build_tools_dir.path = build_tools_dir;
        self._ndk_dir.path = ndk_root;

        const android_jar = try self.android_jar.getPath3(b, step).toString(b.allocator);
        if (!try pathExists(b, android_jar)) {
            std.log.err(
                "android.jar not found for API level {d}. Expected at '{s}'. " ++
                    "Make sure the Android SDK platform for API level {d} is installed " ++
                    "(install via `sdkmanager \"platforms;android-{d}\"`).",
                .{ self.api_level, android_jar, self.api_level, self.api_level },
            );
            return error.AndroidPlatformNotFound;
        }

        // x86_64 lib paths
        const x86_64_include_dir = try self.lib_paths.x86_64.include_dir.getPath3(b, step).toString(b.allocator);
        const x86_64_sys_include_dir = try self.lib_paths.x86_64.sys_include_dir.getPath3(b, step).toString(b.allocator);
        const x86_64_crt_dir = try self.lib_paths.x86_64.crt_dir.getPath3(b, step).toString(b.allocator);

        if (try pathExists(b, x86_64_crt_dir)) {
            self.lib_paths.x86_64.resolved = true;

            const x86_64_libc_contents = b.fmt(
                \\# Generated by zig-android-sdk. DO NOT EDIT.
                \\
                \\# The directory that contains `stdlib.h`.
                \\# On POSIX-like systems, include directories be found with: `cc -E -Wp,-v -xc /dev/null`
                \\include_dir={s}
                \\
                \\# The system-specific include directory. May be the same as `include_dir`.
                \\# On Windows it's the directory that includes `vcruntime.h`.
                \\# On POSIX it's the directory that includes `sys/errno.h`.
                \\sys_include_dir={s}
                \\
                \\# The directory that contains `crt1.o`.
                \\# On POSIX, can be found with `cc -print-file-name=crt1.o`.
                \\# Not needed when targeting MacOS.
                \\crt_dir={s}
                \\
                \\# The directory that contains `vcruntime.lib`.
                \\# Only needed when targeting MSVC on Windows.
                \\msvc_lib_dir=
                \\
                \\# The directory that contains `kernel32.lib`.
                \\# Only needed when targeting MSVC on Windows.
                \\kernel32_lib_dir=
                \\
                \\gcc_dir=
            , .{ x86_64_include_dir, x86_64_sys_include_dir, x86_64_crt_dir });
            _ = self._wf.add("android-libc-x86_64.conf", x86_64_libc_contents);
        }

        // aarch64 lib paths
        const aarch64_include_dir = try self.lib_paths.aarch64.include_dir.getPath3(b, step).toString(b.allocator);
        const aarch64_sys_include_dir = try self.lib_paths.aarch64.sys_include_dir.getPath3(b, step).toString(b.allocator);
        const aarch64_crt_dir = try self.lib_paths.aarch64.crt_dir.getPath3(b, step).toString(b.allocator);

        if (try pathExists(b, aarch64_crt_dir)) {
            self.lib_paths.aarch64.resolved = true;

            const aarch64_libc_contents = b.fmt(
                \\# Generated by zig-android-sdk. DO NOT EDIT.
                \\
                \\# The directory that contains `stdlib.h`.
                \\# On POSIX-like systems, include directories be found with: `cc -E -Wp,-v -xc /dev/null`
                \\include_dir={s}
                \\
                \\# The system-specific include directory. May be the same as `include_dir`.
                \\# On Windows it's the directory that includes `vcruntime.h`.
                \\# On POSIX it's the directory that includes `sys/errno.h`.
                \\sys_include_dir={s}
                \\
                \\# The directory that contains `crt1.o`.
                \\# On POSIX, can be found with `cc -print-file-name=crt1.o`.
                \\# Not needed when targeting MacOS.
                \\crt_dir={s}
                \\
                \\# The directory that contains `vcruntime.lib`.
                \\# Only needed when targeting MSVC on Windows.
                \\msvc_lib_dir=
                \\
                \\# The directory that contains `kernel32.lib`.
                \\# Only needed when targeting MSVC on Windows.
                \\kernel32_lib_dir=
                \\
                \\gcc_dir=
            , .{ aarch64_include_dir, aarch64_sys_include_dir, aarch64_crt_dir });
            _ = self._wf.add("android-libc-aarch64.conf", aarch64_libc_contents);
        }
    }

    fn findLatestVersionDir(b: *std.Build, base: []const u8) !?[]const u8 {
        var it = try DirIterator.init(b, base);
        defer it.deinit();

        var latest_ver: ?std.SemanticVersion = null;
        var latest_ver_str: ?[]const u8 = null;
        while (try it.next()) |entry| {
            if (entry.kind != .directory) continue;
            const parsed = std.SemanticVersion.parse(entry.name) catch continue;
            if (latest_ver) |ver| {
                if (parsed.order(ver) == .gt) {
                    latest_ver = parsed;
                    latest_ver_str = entry.name;
                }
            } else {
                latest_ver = parsed;
                latest_ver_str = entry.name;
            }
        }
        return if (latest_ver) |_| b.dupe(latest_ver_str.?) else null;
    }

    const DirIterator = struct {
        const has_io = @hasDecl(std, "Io") and @hasDecl(std.Io, "Dir");
        const Dir = if (has_io) std.Io.Dir else std.fs.Dir;
        const Iter = Dir.Iterator;

        b: *std.Build,
        dir: Dir,
        it: Iter,

        fn init(b: *std.Build, path: []const u8) !DirIterator {
            const dir = if (has_io) try std.Io.Dir.openDirAbsolute(b.graph.io, path, .{
                .iterate = true,
                .access_sub_paths = false,
            }) else try std.fs.openDirAbsolute(path, .{
                .iterate = true,
                .access_sub_paths = false,
            });

            const it = dir.iterate();
            return DirIterator{
                .b = b,
                .dir = dir,
                .it = it,
            };
        }

        fn deinit(self: *DirIterator) void {
            if (has_io) {
                self.dir.close(self.b.graph.io);
            } else {
                self.dir.close();
            }
        }

        fn next(self: *DirIterator) !?Dir.Entry {
            if (has_io) {
                return try self.it.next(self.b.graph.io);
            } else {
                return try self.it.next();
            }
        }
    };

    fn pathExists(b: *std.Build, path: []const u8) !bool {
        if (@hasDecl(std, "Io") and @hasDecl(std.Io, "Dir") and @hasDecl(std.Io.Dir, "accessAbsolute")) {
            std.Io.Dir.accessAbsolute(b.graph.io, path, .{
                .read = true,
            }) catch |err| switch (err) {
                error.FileNotFound => return false,
                else => |e| return e,
            };
        } else if (@hasDecl(std.fs, "accessAbsolute")) {
            std.fs.accessAbsolute(path, .{}) catch |err| switch (err) {
                error.FileNotFound => return false,
                else => |e| return e,
            };
        } else {
            @compileError("Unsupported Zig version");
        }
        return true;
    }
};
