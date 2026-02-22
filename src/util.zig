const std = @import("std");

pub const DirIterator = struct {
    const has_io = @hasDecl(std, "Io") and @hasDecl(std.Io, "Dir");
    const Dir = if (has_io) std.Io.Dir else std.fs.Dir;
    const Iter = Dir.Iterator;

    b: *std.Build,
    dir: Dir,
    it: Iter,

    pub fn init(b: *std.Build, path: []const u8) !DirIterator {
        const dir = if (has_io) try std.Io.Dir.openDirAbsolute(b.graph.io, path, .{
            .iterate = true,
            .access_sub_paths = false,
        }) else try std.fs.openDirAbsolute(path, .{
            .iterate = true,
            .access_sub_paths = false,
        });

        return .{
            .b = b,
            .dir = dir,
            .it = dir.iterate(),
        };
    }

    pub fn deinit(self: *DirIterator) void {
        if (has_io) {
            self.dir.close(self.b.graph.io);
        } else {
            self.dir.close();
        }
    }

    pub fn next(self: *DirIterator) !?Dir.Entry {
        if (has_io) {
            return try self.it.next(self.b.graph.io);
        }
        return try self.it.next();
    }
};

pub fn addDirectoryFileInputs(run: *std.Build.Step.Run, dir: std.Build.LazyPath) !void {
    switch (dir) {
        .generated => return,
        else => {},
    }

    const b = run.step.owner;
    _ = try run.step.addDirectoryWatchInput(dir);

    var to_visit: std.ArrayList([]const u8) = .empty;
    defer to_visit.deinit(b.allocator);
    try to_visit.append(b.allocator, dir.getPath(b));

    while (to_visit.pop()) |current_dir| {
        var it = try DirIterator.init(b, current_dir);
        defer it.deinit();

        while (try it.next()) |entry| {
            const entry_path = b.pathResolve(&.{ current_dir, entry.name });
            switch (entry.kind) {
                .file => run.addFileInput(.{ .cwd_relative = entry_path }),
                .directory => try to_visit.append(b.allocator, entry_path),
                else => {},
            }
        }
    }
}
