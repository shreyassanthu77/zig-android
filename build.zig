const std = @import("std");
pub const Sdk = @import("src/sdk.zig");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    var sdk = Sdk.init(b, 28);

    const example = try sdk.createApp(.{
        .manifest = .{
            .package = "com.example.app",
            .uses_sdk = .{
                .android_minSdkVersion = 24,
                .android_targetSdkVersion = 29,
            },
            .application = .{
                .android_label = "Example App",
                .android_hasCode = false,
                .activity = &.{
                    Sdk.Application.Manifest.Activity{
                        .android_name = "android.app.NativeActivity",
                        .android_exported = true,
                        .meta_data = &.{
                            Sdk.Application.Manifest.MetaData{
                                .android_name = "android.app.lib_name",
                                .android_value = "main",
                            },
                        },
                        .intent_filter = &.{.main_launcher},
                    },
                },
            },
        },
    });

    const targets: []const std.Target.Query = &.{
        .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .android },
        .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .android },
    };

    for (targets) |target_query| {
        _ = example.addLibrary(.{
            .name = "main",
            .root_module = b.createModule(.{
                .root_source_file = b.path("example.zig"),
                .target = b.resolveTargetQuery(target_query),
                .optimize = optimize,
            }),
        });
    }

    example.installApk(".");
}
