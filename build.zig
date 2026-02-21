const std = @import("std");
pub const Sdk = @import("sdk.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var sdk = Sdk.init(b, target, 29) catch {
        std.log.err("Unsupported target, only x86_64-linux-android and aarch64-linux-android are supported", .{});
        return;
    };

    const example = sdk.addLibrary(.{
        .name = "example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("example.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const example_step = b.step("example", "Build example");
    example_step.dependOn(&b.addInstallArtifact(example, .{}).step);
}
