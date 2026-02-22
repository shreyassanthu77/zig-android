const c = @cImport({
    @cInclude("android/native_activity.h");
    @cInclude("android/log.h");
});

const TAG: [*c]const u8 = "zig-android";

fn logInfo(msg: [*c]const u8) void {
    _ = c.__android_log_print(c.ANDROID_LOG_INFO, TAG, "%s", msg);
}

export fn ANativeActivity_onCreate(
    activity: *c.ANativeActivity,
    saved_state: ?*anyopaque,
    saved_state_size: usize,
) callconv(.c) void {
    _ = saved_state;
    _ = saved_state_size;

    logInfo("ANativeActivity_onCreate called!");

    activity.callbacks.*.onStart = onStart;
    activity.callbacks.*.onResume = onResume;
    activity.callbacks.*.onPause = onPause;
    activity.callbacks.*.onStop = onStop;
    activity.callbacks.*.onDestroy = onDestroy;
    activity.callbacks.*.onNativeWindowCreated = onNativeWindowCreated;
    activity.callbacks.*.onNativeWindowDestroyed = onNativeWindowDestroyed;
}

fn onStart(_: [*c]c.ANativeActivity) callconv(.c) void {
    logInfo("onStart");
}

fn onResume(_: [*c]c.ANativeActivity) callconv(.c) void {
    logInfo("onResume");
}

fn onPause(_: [*c]c.ANativeActivity) callconv(.c) void {
    logInfo("onPause");
}

fn onStop(_: [*c]c.ANativeActivity) callconv(.c) void {
    logInfo("onStop");
}

fn onDestroy(_: [*c]c.ANativeActivity) callconv(.c) void {
    logInfo("onDestroy");
}

fn onNativeWindowCreated(_: [*c]c.ANativeActivity, _: ?*c.ANativeWindow) callconv(.c) void {
    logInfo("onNativeWindowCreated");
}

fn onNativeWindowDestroyed(_: [*c]c.ANativeActivity, _: ?*c.ANativeWindow) callconv(.c) void {
    logInfo("onNativeWindowDestroyed");
}
