const std = @import("std");
pub const Sdk = @import("src/sdk.zig");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});

    const example = try buildExample(b, optimize);
    const example_apk = example.addInstallApk(".");
    const example_step = b.step("example", "Build the example app");
    example_step.dependOn(&example_apk.step);
}

fn buildExample(b: *std.Build, optimize: std.builtin.OptimizeMode) !*Sdk.Application {
    var sdk = Sdk.init(b, 29);
    const example = try sdk.createApp(.{
        .manifest = .{
            .package = "com.example.app",
            .uses_sdk = .{
                .android_minSdkVersion = 24,
                .android_targetSdkVersion = 29,
            },
            .application = .{
                .android_label = "@string/app_name",
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
        .res_dir = b.path("example/res"),
    });

    const targets: []const std.Target.Query = &.{
        .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .android },
        .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .android },
    };

    for (targets) |target_query| {
        _ = example.addLibrary(.{
            .name = "main",
            .root_module = b.createModule(.{
                .root_source_file = b.path("example/main.zig"),
                .target = b.resolveTargetQuery(target_query),
                .optimize = optimize,
            }),
        });
    }

    return example;
}
