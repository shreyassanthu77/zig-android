const std = @import("std");
const Sdk = @import("sdk.zig");
pub const Manifest = @import("android_manifest.zig");

const Application = @This();

sdk: *Sdk,
manifest: Manifest,
wf: *std.Build.Step.WriteFile,
step: std.Build.Step,
aligned_apk: std.Build.LazyPath,

pub const CreateOptions = struct {
    manifest: Manifest,
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
    };
    self.step.dependOn(&sdk_paths.step);
    wf.step.dependOn(&self.step);

    const wf_dir = wf.getDirectory();
    const manifest_path = wf_dir.path(b, "work/AndroidManifest.xml");

    // aapt package -f -M AndroidManifest.xml -I android.jar -F unaligned.apk <raw-dir>
    const aapt = sdk.addRunBuildTool("aapt");
    aapt.addArgs(&.{ "package", "-f" });
    aapt.addArg("-M");
    aapt.addFileArg(manifest_path);
    aapt.addArg("-I");
    aapt.addFileArg(sdk_paths.android_jar);
    aapt.addArg("-F");
    const unaligned_apk = aapt.addOutputFileArg(b.fmt("{s}.unaligned.apk", .{options.manifest.package}));
    aapt.addDirectoryArg(wf_dir.path(b, "build"));
    aapt.step.dependOn(&wf.step);

    // zipalign -f 4 unaligned.apk aligned.apk
    const zipalign = sdk.addRunBuildTool("zipalign");
    zipalign.addArgs(&.{ "-f", "4" });
    zipalign.addFileArg(unaligned_apk);
    const aligned_apk = zipalign.addOutputFileArg(b.fmt("{s}.apk", .{options.manifest.package}));
    zipalign.step.dependOn(&aapt.step);

    const apksigner = sdk.addRunBuildTool("apksigner");
    apksigner.addArgs(&.{ "sign", "--ks" });
    apksigner.addFileArg(sdk.getDebugKeystore());
    apksigner.addArgs(&.{ "--ks-pass", "pass:android", "--out" });
    const signed_apk = apksigner.addOutputFileArg(b.fmt("{s}.apk", .{options.manifest.package}));
    apksigner.addFileArg(aligned_apk);
    apksigner.step.dependOn(&zipalign.step);

    self.aligned_apk = signed_apk;

    return self;
}

pub fn installApk(self: *Application, dest_rel_path: []const u8) void {
    const b = self.sdk.build;
    const apk_name = b.fmt("{s}.apk", .{self.manifest.package});
    const install = b.addInstallFile(self.aligned_apk, b.pathJoin(&.{ dest_rel_path, apk_name }));
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

    var manifest_writer = std.Io.Writer.Allocating.init(b.allocator);
    defer manifest_writer.deinit();
    try self.manifest.toXml(&manifest_writer.writer);
    try manifest_writer.writer.flush(); // noop but not a bad idea to have it here
    _ = wf.add("work/AndroidManifest.xml", manifest_writer.written());
}
