const std = @import("std");
const builtin = @import("builtin");
const Sdk = @import("sdk.zig");
const util = @import("util.zig");
pub const Manifest = @import("android_manifest.zig");

const Application = @This();

sdk: *Sdk,
manifest: Manifest,
wf: *std.Build.Step.WriteFile,
step: std.Build.Step,
aligned_apk: std.Build.LazyPath,
resource_symbols_txt: std.Build.LazyPath,

pub const CreateOptions = struct {
    manifest: Manifest,
    res_dir: ?std.Build.LazyPath = null,
    assets_dir: ?std.Build.LazyPath = null,
};

pub fn create(sdk: *Sdk, options: CreateOptions) !*Application {
    const b = sdk.build;
    const sdk_paths = sdk.sdk_paths;
    const wf = b.addWriteFiles();
    const self = b.allocator.create(Application) catch @panic("OOM");
    self.* = .{
        .sdk = sdk,
        .step = .init(.{
            .id = .custom,
            .name = "create-app",
            .owner = b,
            .makeFn = make,
        }),
        .wf = wf,
        .manifest = options.manifest,
        .aligned_apk = undefined,
        .resource_symbols_txt = undefined,
    };
    self.step.dependOn(&sdk_paths.step);
    wf.step.dependOn(&self.step);

    const wf_dir = wf.getDirectory();
    const manifest_path = wf_dir.path(b, "work/AndroidManifest.xml");
    const res_dir = if (options.res_dir) |dir|
        dir
    else blk: {
        _ = wf.add("build/res/values/strings.xml", "<resources/>\n");
        break :blk wf_dir.path(b, "build/res");
    };

    // aapt2 compile --dir build/res -o compiled-res.zip
    const aapt2_compile = sdk.addRunBuildTool("aapt2");
    aapt2_compile.addArg("compile");
    aapt2_compile.addArg("--dir");
    aapt2_compile.addDirectoryArg(res_dir);
    try util.addDirectoryFileInputs(aapt2_compile, res_dir);
    aapt2_compile.addArg("-o");
    const compiled_res = aapt2_compile.addOutputFileArg("compiled-res.zip");
    aapt2_compile.step.dependOn(&wf.step);

    // aapt2 link --manifest AndroidManifest.xml -I android.jar compiled-res.zip -o unaligned.apk
    const aapt2_link = sdk.addRunBuildTool("aapt2");
    aapt2_link.addArg("link");
    aapt2_link.addArg("--manifest");
    aapt2_link.addFileArg(manifest_path);
    aapt2_link.addArg("-I");
    aapt2_link.addFileArg(sdk_paths.android_jar);
    aapt2_link.addFileArg(compiled_res);
    if (options.assets_dir) |assets_dir| {
        aapt2_link.addArg("-A");
        aapt2_link.addDirectoryArg(assets_dir);
        try util.addDirectoryFileInputs(aapt2_link, assets_dir);
    }
    aapt2_link.addArg("--output-text-symbols");
    const symbols_txt = aapt2_link.addOutputFileArg("R.txt");
    aapt2_link.addArg("-o");
    const unaligned_apk = aapt2_link.addOutputFileArg(b.fmt("{s}.unaligned.apk", .{options.manifest.package}));
    aapt2_link.step.dependOn(&aapt2_compile.step);

    // jar uf unaligned.apk -C build lib
    const add_native_libs = b.addSystemCommand(&.{"jar"});
    add_native_libs.addArgs(&.{"uf"});
    add_native_libs.addFileArg(unaligned_apk);
    add_native_libs.addArgs(&.{"-C"});
    add_native_libs.addDirectoryArg(wf_dir.path(b, "build"));
    add_native_libs.addArg("lib");
    add_native_libs.step.dependOn(&aapt2_link.step);
    add_native_libs.step.dependOn(&wf.step);

    // zipalign -f 4 unaligned.apk aligned.apk
    const zipalign = sdk.addRunBuildTool("zipalign");
    zipalign.addArgs(&.{ "-f", "4" });
    zipalign.addFileArg(unaligned_apk);
    const aligned_apk = zipalign.addOutputFileArg(b.fmt("{s}.apk", .{options.manifest.package}));
    zipalign.step.dependOn(&add_native_libs.step);

    const apksigner = sdk.addRunBuildTool("apksigner");
    apksigner.addArgs(&.{ "sign", "--ks" });
    apksigner.addFileArg(self.getDebugKeystore());
    apksigner.addArgs(&.{ "--ks-pass", "pass:android", "--out" });
    const signed_apk = apksigner.addOutputFileArg(b.fmt("{s}.apk", .{options.manifest.package}));
    apksigner.addFileArg(aligned_apk);
    apksigner.step.dependOn(&zipalign.step);

    self.aligned_apk = signed_apk;
    self.resource_symbols_txt = symbols_txt;

    return self;
}
pub fn addInstallApk(self: *Application, dest_rel_path: []const u8) *std.Build.Step.InstallFile {
    const b = self.sdk.build;
    const apk_name = b.fmt("{s}.apk", .{self.manifest.package});
    const install = b.addInstallFile(self.aligned_apk, b.pathJoin(&.{ dest_rel_path, apk_name }));
    return install;
}

pub fn installApk(self: *Application, dest_rel_path: []const u8) void {
    const b = self.sdk.build;
    const install = self.addInstallApk(dest_rel_path);
    b.getInstallStep().dependOn(&install.step);
}

pub const AddLibraryOptions = struct {
    name: []const u8,
    root_module: *std.Build.Module,
    version: ?std.SemanticVersion = null,
    max_rss: usize = 0,
};

pub fn addLibrary(self: *Application, options: AddLibraryOptions) *std.Build.Step.Compile {
    const b = self.sdk.build;
    const lib = self.sdk.addLibrary(.{
        .name = options.name,
        .root_module = options.root_module,
        .linkage = .dynamic,
        .version = options.version,
        .max_rss = options.max_rss,
    });
    lib.root_module.linkSystemLibrary("c", .{});
    lib.root_module.linkSystemLibrary("log", .{});
    lib.root_module.linkSystemLibrary("android", .{});
    self.step.dependOn(&lib.step);

    const lib_path = lib.getEmittedBin();
    const target = lib.root_module.resolved_target orelse
        @panic("lib.root_module.resolved_target is null");
    const lib_dir = switch (target.result.cpu.arch) {
        .x86_64 => "x86_64",
        .aarch64 => "arm64-v8a",
        else => @panic("unsupported target"),
    };
    const lib_out_dir = b.pathJoin(&.{ "build", "lib", lib_dir, b.fmt("lib{s}.so", .{options.name}) });
    _ = self.wf.addCopyFile(lib_path, lib_out_dir);

    return lib;
}

fn make(step: *std.Build.Step, options: std.Build.Step.MakeOptions) !void {
    _ = options;
    const b = step.owner;
    const self: *Application = @fieldParentPtr("step", step);
    const wf = self.wf;

    var manifest_writer = util.AllocatingWriter.init(b.allocator);
    defer manifest_writer.deinit();
    try self.manifest.toXml(manifest_writer.writer());
    _ = wf.add("work/AndroidManifest.xml", manifest_writer.written());
}

pub fn getDebugKeystore(self: *@This()) std.Build.LazyPath {
    const b = self.sdk.build;

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
        _ = keytool.captureStdErr(.{});
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
