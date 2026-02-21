const std = @import("std");

export fn add(a: i32, b: i32) callconv(.c) i32 {
    return a + b;
}
