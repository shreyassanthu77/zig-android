//! Represents the root <manifest> element in the AndroidManifest.xml file.
//! It must contain an <application> element and specify xmlns:android and package attributes.
//! @see https://developer.android.com/guide/topics/manifest/manifest-element
const std = @import("std");

const Manifest = @This();

/// The Android namespace.
xmlns_android: []const u8 = "http://schemas.android.com/apk/res/android",
/// A full Java-language-style package name for the Android app.
package: []const u8,
/// An internal version number.
android_versionCode: ?i32 = null,
/// The version number shown to users.
android_versionName: ?[]const u8 = null,
/// The default install location for the app.
android_installLocation: ?AndroidInstallLocation = null,
/// The name of a Linux user ID that will be shared with other applications.
android_sharedUserId: ?[]const u8 = null,
/// A user-readable label for the shared user ID.
android_sharedUserLabel: ?[]const u8 = null,
/// The maximum SDK version where the shared user ID is used.
android_sharedUserMaxSdkVersion: ?i32 = null,

/// Child elements
uses_sdk: ?UsesSdk = null,
application: Application,
instrumentation: ?[]const Instrumentation = null,
permission: ?[]const Permission = null,
permission_group: ?[]const PermissionGroup = null,
permission_tree: ?[]const PermissionTree = null,
queries: ?Queries = null,
supports_gl_texture: ?[]const SupportsGlTexture = null,
supports_screens: ?SupportsScreens = null,
uses_configuration: ?UsesConfiguration = null,
uses_feature: ?[]const UsesFeature = null,
uses_permission: ?[]const UsesPermission = null,
compatible_screens: ?CompatibleScreens = null,
attribution: ?[]const Attribution = null,

pub fn toXml(self: Manifest, w: anytype) !void {
    try structToXMLTag(w, "manifest", self, 0);
}

/// The default install location for the app.
pub const AndroidInstallLocation = enum {
    auto,
    internalOnly,
    preferExternal,
};

/// Represents the <application> element. Declares the application-level components.
/// @see https://developer.android.com/guide/topics/manifest/application-element
pub const Application = struct {
    android_label: ?[]const u8 = null,
    android_icon: ?[]const u8 = null,
    android_name: ?[]const u8 = null,
    android_theme: ?[]const u8 = null,
    android_allowBackup: ?bool = null,
    android_allowClearUserData: ?bool = null,
    android_allowTaskReparenting: ?bool = null,
    android_backupAgent: ?[]const u8 = null,
    android_backupInForeground: ?bool = null,
    android_banner: ?[]const u8 = null,
    android_dataExtractionRules: ?[]const u8 = null,
    android_debuggable: ?bool = null,
    android_description: ?[]const u8 = null,
    android_directBootAware: ?bool = null,
    android_enabled: ?bool = null,
    android_extractNativeLibs: ?bool = null,
    android_fullBackupContent: ?[]const u8 = null,
    android_fullBackupOnly: ?bool = null,
    android_hasCode: ?bool = null,
    android_hardwareAccelerated: ?bool = null,
    android_isGame: ?bool = null,
    android_killAfterRestore: ?bool = null,
    android_largeHeap: ?bool = null,
    android_logo: ?[]const u8 = null,
    android_manageSpaceActivity: ?[]const u8 = null,
    android_networkSecurityConfig: ?[]const u8 = null,
    android_permission: ?[]const u8 = null,
    android_persistent: ?bool = null,
    android_process: ?[]const u8 = null,
    android_restoreAnyVersion: ?bool = null,
    android_requestLegacyExternalStorage: ?bool = null,
    android_requiredForAllUsers: ?bool = null,
    android_resizeableActivity: ?bool = null,
    android_supportsRtl: ?bool = null,
    android_taskAffinity: ?[]const u8 = null,
    android_testOnly: ?bool = null,
    android_uiOptions: ?UiOptions = null,
    android_usesCleartextTraffic: ?bool = null,
    android_vmSafeMode: ?bool = null,

    activity: ?[]const Activity = null,
    activity_alias: ?[]const ActivityAlias = null,
    service: ?[]const Service = null,
    receiver: ?[]const Receiver = null,
    provider: ?[]const Provider = null,
    uses_library: ?[]const UsesLibrary = null,
    uses_native_library: ?[]const UsesNativeLibrary = null,
    meta_data: ?[]const MetaData = null,
};

/// UI options union for elements supporting android:uiOptions
pub const UiOptions = enum {
    none,
    splitActionBarWhenNarrow,
};

/// Represents the <activity> element.
/// @see https://developer.android.com/guide/topics/manifest/activity-element
pub const Activity = struct {
    android_name: []const u8,
    android_label: ?[]const u8 = null,
    android_exported: ?bool = null,
    android_launchMode: ?LaunchMode = null,
    android_allowEmbedded: ?bool = null,
    android_allowTaskReparenting: ?bool = null,
    android_alwaysRetainTaskState: ?bool = null,
    android_autoRemoveFromRecents: ?bool = null,
    android_banner: ?[]const u8 = null,
    android_clearTaskOnLaunch: ?bool = null,
    android_colorMode: ?ColorMode = null,
    android_configChanges: ?[]const ConfigChange = null,
    android_documentLaunchMode: ?DocumentLaunchMode = null,
    android_excludeFromRecents: ?bool = null,
    android_finishOnTaskLaunch: ?bool = null,
    android_hardwareAccelerated: ?bool = null,
    android_icon: ?[]const u8 = null,
    android_lockTaskMode: ?LockTaskMode = null,
    android_maxRecents: ?i32 = null,
    android_multiprocess: ?bool = null,
    android_noHistory: ?bool = null,
    android_parentActivityName: ?[]const u8 = null,
    android_permission: ?[]const u8 = null,
    android_process: ?[]const u8 = null,
    android_resizeableActivity: ?bool = null,
    android_screenOrientation: ?ScreenOrientation = null,
    android_stateNotNeeded: ?bool = null,
    android_supportsPictureInPicture: ?bool = null,
    android_taskAffinity: ?[]const u8 = null,
    android_theme: ?[]const u8 = null,
    android_uiOptions: ?UiOptions = null,
    android_windowSoftInputMode: ?[]const WindowSoftInputMode = null,

    intent_filter: ?[]const IntentFilter = null,
    meta_data: ?[]const MetaData = null,
    layout: ?[]const Layout = null,
};

/// Activity launch modes.
pub const LaunchMode = enum {
    standard,
    singleTop,
    singleTask,
    singleInstance,
    singleInstancePerTask,
};

/// Color mode.
pub const ColorMode = enum {
    hdr,
    wideColorGamut,
};

/// Config change flags.
pub const ConfigChange = enum {
    mcc,
    mnc,
    locale,
    touchscreen,
    keyboard,
    keyboardHidden,
    navigation,
    screenLayout,
    fontScale,
    uiMode,
    orientation,
    density,
    screenSize,
    smallestScreenSize,
};

/// Document launch mode.
pub const DocumentLaunchMode = enum {
    intoExisting,
    always,
    never,
    none,
};

/// Lock task mode.
pub const LockTaskMode = enum {
    normal,
    if_whitelisted,
    always,
};

/// Screen orientation values.
pub const ScreenOrientation = enum {
    unspecified,
    behind,
    landscape,
    portrait,
    reverseLandscape,
    reversePortrait,
    sensorLandscape,
    sensorPortrait,
    userLandscape,
    userPortrait,
    sensor,
    fullSensor,
    nosensor,
    user,
    fullUser,
    locked,
};

/// Window soft input mode flags.
pub const WindowSoftInputMode = enum {
    stateUnspecified,
    stateUnchanged,
    stateHidden,
    stateAlwaysHidden,
    stateVisible,
    stateAlwaysVisible,
    adjustUnspecified,
    adjustResize,
    adjustPan,
};

/// Represents the <activity-alias> element.
/// @see https://developer.android.com/guide/topics/manifest/activity-alias-element
pub const ActivityAlias = struct {
    android_name: []const u8,
    android_targetActivity: []const u8,
    android_enabled: ?bool = null,
    android_exported: ?bool = null,
    android_icon: ?[]const u8 = null,
    android_label: ?[]const u8 = null,
    android_permission: ?[]const u8 = null,

    intent_filter: ?[]const IntentFilter = null,
    meta_data: ?[]const MetaData = null,
};

/// Represents the <service> element.
/// @see https://developer.android.com/guide/topics/manifest/service-element
pub const Service = struct {
    android_name: []const u8,
    android_exported: ?bool = null,
    android_enabled: ?bool = null,
    android_directBootAware: ?bool = null,
    android_description: ?[]const u8 = null,
    android_foregroundServiceType: ?[]const ForegroundServiceType = null,
    android_icon: ?[]const u8 = null,
    android_isolatedProcess: ?bool = null,
    android_label: ?[]const u8 = null,
    android_permission: ?[]const u8 = null,
    android_process: ?[]const u8 = null,

    intent_filter: ?[]const IntentFilter = null,
    meta_data: ?[]const MetaData = null,
};

/// Foreground service types.
pub const ForegroundServiceType = enum {
    camera,
    connectedDevice,
    dataSync,
    location,
    mediaPlayback,
    mediaProjection,
    microphone,
    phoneCall,
};

/// Represents the <receiver> element.
/// @see https://developer.android.com/guide/topics/manifest/receiver-element
pub const Receiver = struct {
    android_name: []const u8,
    android_exported: ?bool = null,
    android_enabled: ?bool = null,
    android_directBootAware: ?bool = null,
    android_description: ?[]const u8 = null,
    android_icon: ?[]const u8 = null,
    android_label: ?[]const u8 = null,
    android_permission: ?[]const u8 = null,
    android_process: ?[]const u8 = null,

    intent_filter: ?[]const IntentFilter = null,
    meta_data: ?[]const MetaData = null,
};

/// Represents the <provider> element.
/// @see https://developer.android.com/guide/topics/manifest/provider-element
pub const Provider = struct {
    android_name: []const u8,
    android_authorities: []const u8,
    android_exported: ?bool = null,
    android_enabled: ?bool = null,
    android_directBootAware: ?bool = null,
    android_grantUriPermissions: ?bool = null,
    android_icon: ?[]const u8 = null,
    android_initOrder: ?i32 = null,
    android_label: ?[]const u8 = null,
    android_multiprocess: ?bool = null,
    android_permission: ?[]const u8 = null,
    android_process: ?[]const u8 = null,
    android_readPermission: ?[]const u8 = null,
    android_syncable: ?bool = null,
    android_writePermission: ?[]const u8 = null,

    grant_uri_permission: ?[]const GrantUriPermission = null,
    meta_data: ?[]const MetaData = null,
    path_permission: ?[]const PathPermission = null,
};

/// Represents the <intent-filter> element.
/// @see https://developer.android.com/guide/topics/manifest/intent-filter-element
pub const IntentFilter = struct {
    android_icon: ?[]const u8 = null,
    android_label: ?[]const u8 = null,
    android_priority: ?i32 = null,

    action: []const Action,
    category: ?[]const Category = null,
    data: ?[]const Data = null,

    pub const main_launcher = IntentFilter{
        .action = &.{.main},
        .category = &.{.launcher},
    };
    pub const view_default = IntentFilter{
        .action = &.{.view},
        .category = &.{.default},
    };
    pub const edit_default = IntentFilter{
        .action = &.{.edit},
        .category = &.{.default},
    };
    pub const send_default = IntentFilter{
        .action = &.{.send},
        .category = &.{.default},
    };
    pub const dial_default = IntentFilter{
        .action = &.{.dial},
        .category = &.{.default},
    };
    pub const call_default = IntentFilter{
        .action = &.{.call},
        .category = &.{.default},
    };
    pub const boot_completed = IntentFilter{
        .action = &.{.bootCompleted},
    };
};

/// Represents the <action> element.
/// @see https://developer.android.com/guide/topics/manifest/action-element
pub const Action = struct {
    android_name: []const u8,

    pub const main = Action{
        .android_name = "android.intent.action.MAIN",
    };
    pub const view = Action{
        .android_name = "android.intent.action.VIEW",
    };
    pub const edit = Action{
        .android_name = "android.intent.action.EDIT",
    };
    pub const send = Action{
        .android_name = "android.intent.action.SEND",
    };
    pub const sendto = Action{
        .android_name = "android.intent.action.SENDTO",
    };
    pub const dial = Action{
        .android_name = "android.intent.action.DIAL",
    };
    pub const call = Action{
        .android_name = "android.intent.action.CALL",
    };
    pub const bootCompleted = Action{
        .android_name = "android.intent.action.BOOT_COMPLETED",
    };
    pub const packageAdded = Action{
        .android_name = "android.intent.action.PACKAGE_ADDED",
    };
    pub const packageRemoved = Action{
        .android_name = "android.intent.action.PACKAGE_REMOVED",
    };
};

/// Represents the <category> element.
/// @see https://developer.android.com/guide/topics/manifest/category-element
pub const Category = struct {
    android_name: []const u8,

    pub const launcher = Category{
        .android_name = "android.intent.category.LAUNCHER",
    };
    pub const default = Category{
        .android_name = "android.intent.category.DEFAULT",
    };
    pub const browsable = Category{
        .android_name = "android.intent.category.BROWSABLE",
    };
    pub const home = Category{
        .android_name = "android.intent.category.HOME",
    };
    pub const preference = Category{
        .android_name = "android.intent.category.PREFERENCE",
    };
    pub const tab = Category{
        .android_name = "android.intent.category.TAB",
    };
    pub const alternative = Category{
        .android_name = "android.intent.category.ALTERNATIVE",
    };
    pub const info = Category{
        .android_name = "android.intent.category.INFO",
    };
    pub const debug = Category{
        .android_name = "android.intent.category.DEBUG",
    };
    pub const testCategory = Category{
        .android_name = "android.intent.category.TEST",
    };
};

/// Represents the <data> element.
/// @see https://developer.android.com/guide/topics/manifest/data-element
pub const Data = struct {
    android_scheme: ?[]const u8 = null,
    android_host: ?[]const u8 = null,
    android_port: ?[]const u8 = null,
    android_path: ?[]const u8 = null,
    android_pathPattern: ?[]const u8 = null,
    android_pathPrefix: ?[]const u8 = null,
    android_mimeType: ?[]const u8 = null,
};

/// Represents the <uses-permission> element.
/// @see https://developer.android.com/guide/topics/manifest/uses-permission-element
pub const UsesPermission = struct {
    android_name: []const u8,
    android_maxSdkVersion: ?i32 = null,

    pub const accessBackgroundLocation = UsesPermission{ .android_name = "android.permission.ACCESS_BACKGROUND_LOCATION" };
    pub const accessCoarseLocation = UsesPermission{ .android_name = "android.permission.ACCESS_COARSE_LOCATION" };
    pub const accessFineLocation = UsesPermission{ .android_name = "android.permission.ACCESS_FINE_LOCATION" };
    pub const accessLocationExtraCommands = UsesPermission{ .android_name = "android.permission.ACCESS_LOCATION_EXTRA_COMMANDS" };
    pub const accessNetworkState = UsesPermission{ .android_name = "android.permission.ACCESS_NETWORK_STATE" };
    pub const accessNotificationPolicy = UsesPermission{ .android_name = "android.permission.ACCESS_NOTIFICATION_POLICY" };
    pub const accessWifiState = UsesPermission{ .android_name = "android.permission.ACCESS_WIFI_STATE" };
    pub const accountManager = UsesPermission{ .android_name = "android.permission.ACCOUNT_MANAGER" };
    pub const activityRecognition = UsesPermission{ .android_name = "android.permission.ACTIVITY_RECOGNITION" };
    pub const addVoicemail = UsesPermission{ .android_name = "com.android.voicemail.permission.ADD_VOICEMAIL" };
    pub const answerPhoneCalls = UsesPermission{ .android_name = "android.permission.ANSWER_PHONE_CALLS" };
    pub const authenticateAccounts = UsesPermission{ .android_name = "android.permission.AUTHENTICATE_ACCOUNTS" };
    pub const batteryStats = UsesPermission{ .android_name = "android.permission.BATTERY_STATS" };
    pub const bindAccessibilityService = UsesPermission{ .android_name = "android.permission.BIND_ACCESSIBILITY_SERVICE" };
    pub const bindAppwidget = UsesPermission{ .android_name = "android.permission.BIND_APPWIDGET" };
    pub const bindAutofillService = UsesPermission{ .android_name = "android.permission.BIND_AUTOFILL_SERVICE" };
    pub const bindCarrierMessagingService = UsesPermission{ .android_name = "android.permission.BIND_CARRIER_MESSAGING_SERVICE" };
    pub const bindCarrierServices = UsesPermission{ .android_name = "android.permission.BIND_CARRIER_SERVICES" };
    pub const bindChooserTargetService = UsesPermission{ .android_name = "android.permission.BIND_CHOOSER_TARGET_SERVICE" };
    pub const bindConditionProviderService = UsesPermission{ .android_name = "android.permission.BIND_CONDITION_PROVIDER_SERVICE" };
    pub const bindDeviceAdmin = UsesPermission{ .android_name = "android.permission.BIND_DEVICE_ADMIN" };
    pub const bindDreamService = UsesPermission{ .android_name = "android.permission.BIND_DREAM_SERVICE" };
    pub const bindIncallService = UsesPermission{ .android_name = "android.permission.BIND_INCALL_SERVICE" };
    pub const bindInputMethod = UsesPermission{ .android_name = "android.permission.BIND_INPUT_METHOD" };
    pub const bindMidiDeviceService = UsesPermission{ .android_name = "android.permission.BIND_MIDI_DEVICE_SERVICE" };
    pub const bindNfcService = UsesPermission{ .android_name = "android.permission.BIND_NFC_SERVICE" };
    pub const bindNotificationListenerService = UsesPermission{ .android_name = "android.permission.BIND_NOTIFICATION_LISTENER_SERVICE" };
    pub const bindPrintService = UsesPermission{ .android_name = "android.permission.BIND_PRINT_SERVICE" };
    pub const bindQuickAccessWalletService = UsesPermission{ .android_name = "android.permission.BIND_QUICK_ACCESS_WALLET_SERVICE" };
    pub const bindQuickSettingsTile = UsesPermission{ .android_name = "android.permission.BIND_QUICK_SETTINGS_TILE" };
    pub const bindRemoteviews = UsesPermission{ .android_name = "android.permission.BIND_REMOTEVIEWS" };
    pub const bindScreeningService = UsesPermission{ .android_name = "android.permission.BIND_SCREENING_SERVICE" };
    pub const bindTelecomConnectionService = UsesPermission{ .android_name = "android.permission.BIND_TELECOM_CONNECTION_SERVICE" };
    pub const bindTextService = UsesPermission{ .android_name = "android.permission.BIND_TEXT_SERVICE" };
    pub const bindTvInput = UsesPermission{ .android_name = "android.permission.BIND_TV_INPUT" };
    pub const bindVisualVoicemailService = UsesPermission{ .android_name = "android.permission.BIND_VISUAL_VOICEMAIL_SERVICE" };
    pub const bindVoiceInteraction = UsesPermission{ .android_name = "android.permission.BIND_VOICE_INTERACTION" };
    pub const bindVpnService = UsesPermission{ .android_name = "android.permission.BIND_VPN_SERVICE" };
    pub const bindWallpaper = UsesPermission{ .android_name = "android.permission.BIND_WALLPAPER" };
    pub const bluetooth = UsesPermission{ .android_name = "android.permission.BLUETOOTH" };
    pub const bluetoothAdmin = UsesPermission{ .android_name = "android.permission.BLUETOOTH_ADMIN" };
    pub const bluetoothAdvertise = UsesPermission{ .android_name = "android.permission.BLUETOOTH_ADVERTISE" };
    pub const bluetoothConnect = UsesPermission{ .android_name = "android.permission.BLUETOOTH_CONNECT" };
    pub const bluetoothScan = UsesPermission{ .android_name = "android.permission.BLUETOOTH_SCAN" };
    pub const bodySensors = UsesPermission{ .android_name = "android.permission.BODY_SENSORS" };
    pub const bodySensorsBackground = UsesPermission{ .android_name = "android.permission.BODY_SENSORS_BACKGROUND" };
    pub const broadcastPackageRemoved = UsesPermission{ .android_name = "android.permission.BROADCAST_PACKAGE_REMOVED" };
    pub const broadcastSms = UsesPermission{ .android_name = "android.permission.BROADCAST_SMS" };
    pub const broadcastSticky = UsesPermission{ .android_name = "android.permission.BROADCAST_STICKY" };
    pub const broadcastWapPush = UsesPermission{ .android_name = "android.permission.BROADCAST_WAP_PUSH" };
    pub const callCompanionApp = UsesPermission{ .android_name = "android.permission.CALL_COMPANION_APP" };
    pub const callPhone = UsesPermission{ .android_name = "android.permission.CALL_PHONE" };
    pub const callPrivileged = UsesPermission{ .android_name = "android.permission.CALL_PRIVILEGED" };
    pub const camera = UsesPermission{ .android_name = "android.permission.CAMERA" };
    pub const captureAudioOutput = UsesPermission{ .android_name = "android.permission.CAPTURE_AUDIO_OUTPUT" };
    pub const changeComponentEnabledState = UsesPermission{ .android_name = "android.permission.CHANGE_COMPONENT_ENABLED_STATE" };
    pub const changeConfiguration = UsesPermission{ .android_name = "android.permission.CHANGE_CONFIGURATION" };
    pub const changeNetworkState = UsesPermission{ .android_name = "android.permission.CHANGE_NETWORK_STATE" };
    pub const changeWifiMulticastState = UsesPermission{ .android_name = "android.permission.CHANGE_WIFI_MULTICAST_STATE" };
    pub const changeWifiState = UsesPermission{ .android_name = "android.permission.CHANGE_WIFI_STATE" };
    pub const clearAppCache = UsesPermission{ .android_name = "android.permission.CLEAR_APP_CACHE" };
    pub const controlLocationUpdates = UsesPermission{ .android_name = "android.permission.CONTROL_LOCATION_UPDATES" };
    pub const deleteCacheFiles = UsesPermission{ .android_name = "android.permission.DELETE_CACHE_FILES" };
    pub const deletePackages = UsesPermission{ .android_name = "android.permission.DELETE_PACKAGES" };
    pub const diagnostic = UsesPermission{ .android_name = "android.permission.DIAGNOSTIC" };
    pub const disableKeyguard = UsesPermission{ .android_name = "android.permission.DISABLE_KEYGUARD" };
    pub const dump = UsesPermission{ .android_name = "android.permission.DUMP" };
    pub const expandStatusBar = UsesPermission{ .android_name = "android.permission.EXPAND_STATUS_BAR" };
    pub const factoryTest = UsesPermission{ .android_name = "android.permission.FACTORY_TEST" };
    pub const foregroundService = UsesPermission{ .android_name = "android.permission.FOREGROUND_SERVICE" };
    pub const getAccounts = UsesPermission{ .android_name = "android.permission.GET_ACCOUNTS" };
    pub const getAccountsPrivileged = UsesPermission{ .android_name = "android.permission.GET_ACCOUNTS_PRIVILEGED" };
    pub const getPackageSize = UsesPermission{ .android_name = "android.permission.GET_PACKAGE_SIZE" };
    pub const getTasks = UsesPermission{ .android_name = "android.permission.GET_TASKS" };
    pub const globalSearch = UsesPermission{ .android_name = "android.permission.GLOBAL_SEARCH" };
    pub const hardwareTest = UsesPermission{ .android_name = "android.permission.HARDWARE_TEST" };
    pub const hideOverlayWindows = UsesPermission{ .android_name = "android.permission.HIDE_OVERLAY_WINDOWS" };
    pub const highSamplingRateSensors = UsesPermission{ .android_name = "android.permission.HIGH_SAMPLING_RATE_SENSORS" };
    pub const installLocationProvider = UsesPermission{ .android_name = "android.permission.INSTALL_LOCATION_PROVIDER" };
    pub const installPackages = UsesPermission{ .android_name = "android.permission.INSTALL_PACKAGES" };
    pub const installShortcut = UsesPermission{ .android_name = "android.permission.INSTALL_SHORTCUT" };
    pub const instantAppForegroundService = UsesPermission{ .android_name = "android.permission.INSTANT_APP_FOREGROUND_SERVICE" };
    pub const interactAcrossProfiles = UsesPermission{ .android_name = "android.permission.INTERACT_ACROSS_PROFILES" };
    pub const internet = UsesPermission{ .android_name = "android.permission.INTERNET" };
    pub const killBackgroundProcesses = UsesPermission{ .android_name = "android.permission.KILL_BACKGROUND_PROCESSES" };
    pub const launchCaptureContentActivityForNote = UsesPermission{ .android_name = "android.permission.LAUNCH_CAPTURE_CONTENT_ACTIVITY_FOR_NOTE" };
    pub const loaderUsageStats = UsesPermission{ .android_name = "android.permission.LOADER_USAGE_STATS" };
    pub const locationHardware = UsesPermission{ .android_name = "android.permission.LOCATION_HARDWARE" };
    pub const manageAccounts = UsesPermission{ .android_name = "android.permission.MANAGE_ACCOUNTS" };
    pub const manageAppTokens = UsesPermission{ .android_name = "android.permission.MANAGE_APP_TOKENS" };
    pub const manageDocuments = UsesPermission{ .android_name = "android.permission.MANAGE_DOCUMENTS" };
    pub const manageExternalStorage = UsesPermission{ .android_name = "android.permission.MANAGE_EXTERNAL_STORAGE" };
    pub const manageOwnCalls = UsesPermission{ .android_name = "android.permission.MANAGE_OWN_CALLS" };
    pub const manageWifiInterfaces = UsesPermission{ .android_name = "android.permission.MANAGE_WIFI_INTERFACES" };
    pub const masterClear = UsesPermission{ .android_name = "android.permission.MASTER_CLEAR" };
    pub const mediaContentControl = UsesPermission{ .android_name = "android.permission.MEDIA_CONTENT_CONTROL" };
    pub const modifyAudioSettings = UsesPermission{ .android_name = "android.permission.MODIFY_AUDIO_SETTINGS" };
    pub const modifyPhoneState = UsesPermission{ .android_name = "android.permission.MODIFY_PHONE_STATE" };
    pub const mountFormatFilesystems = UsesPermission{ .android_name = "android.permission.MOUNT_FORMAT_FILESYSTEMS" };
    pub const mountUnmountFilesystems = UsesPermission{ .android_name = "android.permission.MOUNT_UNMOUNT_FILESYSTEMS" };
    pub const nfc = UsesPermission{ .android_name = "android.permission.NFC" };
    pub const nfcPreferredPaymentInfo = UsesPermission{ .android_name = "android.permission.NFC_PREFERRED_PAYMENT_INFO" };
    pub const nfcTransactionEvent = UsesPermission{ .android_name = "android.permission.NFC_TRANSACTION_EVENT" };
    pub const overrideWifiConfig = UsesPermission{ .android_name = "android.permission.OVERRIDE_WIFI_CONFIG" };
    pub const packageUsageStats = UsesPermission{ .android_name = "android.permission.PACKAGE_USAGE_STATS" };
    pub const persistentActivity = UsesPermission{ .android_name = "android.permission.PERSISTENT_ACTIVITY" };
    pub const postNotifications = UsesPermission{ .android_name = "android.permission.POST_NOTIFICATIONS" };
    pub const processOutgoingCalls = UsesPermission{ .android_name = "android.permission.PROCESS_OUTGOING_CALLS" };
    pub const queryAllPackages = UsesPermission{ .android_name = "android.permission.QUERY_ALL_PACKAGES" };
    pub const readCalendar = UsesPermission{ .android_name = "android.permission.READ_CALENDAR" };
    pub const readCallLog = UsesPermission{ .android_name = "android.permission.READ_CALL_LOG" };
    pub const readContacts = UsesPermission{ .android_name = "android.permission.READ_CONTACTS" };
    pub const readExternalStorage = UsesPermission{ .android_name = "android.permission.READ_EXTERNAL_STORAGE" };
    pub const readFrameBuffer = UsesPermission{ .android_name = "android.permission.READ_FRAME_BUFFER" };
    pub const readInputState = UsesPermission{ .android_name = "android.permission.READ_INPUT_STATE" };
    pub const readLogs = UsesPermission{ .android_name = "android.permission.READ_LOGS" };
    pub const readPhoneNumbers = UsesPermission{ .android_name = "android.permission.READ_PHONE_NUMBERS" };
    pub const readPhoneState = UsesPermission{ .android_name = "android.permission.READ_PHONE_STATE" };
    pub const readProfile = UsesPermission{ .android_name = "android.permission.READ_PROFILE" };
    pub const readSms = UsesPermission{ .android_name = "android.permission.READ_SMS" };
    pub const readSocialStream = UsesPermission{ .android_name = "android.permission.READ_SOCIAL_STREAM" };
    pub const readSyncSettings = UsesPermission{ .android_name = "android.permission.READ_SYNC_SETTINGS" };
    pub const readSyncStats = UsesPermission{ .android_name = "android.permission.READ_SYNC_STATS" };
    pub const readUserDictionary = UsesPermission{ .android_name = "android.permission.READ_USER_DICTIONARY" };
    pub const readVoicemail = UsesPermission{ .android_name = "com.android.voicemail.permission.READ_VOICEMAIL" };
    pub const reboot = UsesPermission{ .android_name = "android.permission.REBOOT" };
    pub const receiveBootCompleted = UsesPermission{ .android_name = "android.permission.RECEIVE_BOOT_COMPLETED" };
    pub const receiveMms = UsesPermission{ .android_name = "android.permission.RECEIVE_MMS" };
    pub const receiveSms = UsesPermission{ .android_name = "android.permission.RECEIVE_SMS" };
    pub const receiveWapPush = UsesPermission{ .android_name = "android.permission.RECEIVE_WAP_PUSH" };
    pub const recordAudio = UsesPermission{ .android_name = "android.permission.RECORD_AUDIO" };
    pub const reorderTasks = UsesPermission{ .android_name = "android.permission.REORDER_TASKS" };
    pub const requestCompanionRunInBackground = UsesPermission{ .android_name = "android.permission.REQUEST_COMPANION_RUN_IN_BACKGROUND" };
    pub const requestCompanionUseDataInBackground = UsesPermission{ .android_name = "android.permission.REQUEST_COMPANION_USE_DATA_IN_BACKGROUND" };
    pub const requestDeletePackages = UsesPermission{ .android_name = "android.permission.REQUEST_DELETE_PACKAGES" };
    pub const requestIgnoreBatteryOptimizations = UsesPermission{ .android_name = "android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" };
    pub const requestInstallPackages = UsesPermission{ .android_name = "android.permission.REQUEST_INSTALL_PACKAGES" };
    pub const requestPasswordComplexity = UsesPermission{ .android_name = "android.permission.REQUEST_PASSWORD_COMPLEXITY" };
    pub const restartPackages = UsesPermission{ .android_name = "android.permission.RESTART_PACKAGES" };
    pub const sendRespondViaMessage = UsesPermission{ .android_name = "android.permission.SEND_RESPOND_VIA_MESSAGE" };
    pub const sendSms = UsesPermission{ .android_name = "android.permission.SEND_SMS" };
    pub const setActivityWatcher = UsesPermission{ .android_name = "android.permission.SET_ACTIVITY_WATCHER" };
    pub const setAlarm = UsesPermission{ .android_name = "android.permission.SET_ALARM" };
    pub const setAlwaysFinish = UsesPermission{ .android_name = "android.permission.SET_ALWAYS_FINISH" };
    pub const setAnimationScale = UsesPermission{ .android_name = "android.permission.SET_ANIMATION_SCALE" };
    pub const setDebugApp = UsesPermission{ .android_name = "android.permission.SET_DEBUG_APP" };
    pub const setOrientation = UsesPermission{ .android_name = "android.permission.SET_ORIENTATION" };
    pub const setPointerSpeed = UsesPermission{ .android_name = "android.permission.SET_POINTER_SPEED" };
    pub const setPreferredApplications = UsesPermission{ .android_name = "android.permission.SET_PREFERRED_APPLICATIONS" };
    pub const setProcessLimit = UsesPermission{ .android_name = "android.permission.SET_PROCESS_LIMIT" };
    pub const setTime = UsesPermission{ .android_name = "android.permission.SET_TIME" };
    pub const setTimeZone = UsesPermission{ .android_name = "android.permission.SET_TIME_ZONE" };
    pub const setWallpaper = UsesPermission{ .android_name = "android.permission.SET_WALLPAPER" };
    pub const setWallpaperHints = UsesPermission{ .android_name = "android.permission.SET_WALLPAPER_HINTS" };
    pub const signalPersistentProcesses = UsesPermission{ .android_name = "android.permission.SIGNAL_PERSISTENT_PROCESSES" };
    pub const smsFinancialTransactions = UsesPermission{ .android_name = "android.permission.SMS_FINANCIAL_TRANSACTIONS" };
    pub const startForegroundServicesFromBackground = UsesPermission{ .android_name = "android.permission.START_FOREGROUND_SERVICES_FROM_BACKGROUND" };
    pub const startViewPermissionUsage = UsesPermission{ .android_name = "android.permission.START_VIEW_PERMISSION_USAGE" };
    pub const statusBar = UsesPermission{ .android_name = "android.permission.STATUS_BAR" };
    pub const systemAlertWindow = UsesPermission{ .android_name = "android.permission.SYSTEM_ALERT_WINDOW" };
    pub const transmitIr = UsesPermission{ .android_name = "android.permission.TRANSMIT_IR" };
    pub const uninstallShortcut = UsesPermission{ .android_name = "android.permission.UNINSTALL_SHORTCUT" };
    pub const updateDeviceStats = UsesPermission{ .android_name = "android.permission.UPDATE_DEVICE_STATS" };
    pub const useBiometric = UsesPermission{ .android_name = "android.permission.USE_BIOMETRIC" };
    pub const useFingerprint = UsesPermission{ .android_name = "android.permission.USE_FINGERPRINT" };
    pub const useFullScreenIntent = UsesPermission{ .android_name = "android.permission.USE_FULL_SCREEN_INTENT" };
    pub const useSip = UsesPermission{ .android_name = "android.permission.USE_SIP" };
    pub const vibrate = UsesPermission{ .android_name = "android.permission.VIBRATE" };
    pub const wakeLock = UsesPermission{ .android_name = "android.permission.WAKE_LOCK" };
    pub const writeApnSettings = UsesPermission{ .android_name = "android.permission.WRITE_APN_SETTINGS" };
    pub const writeCalendar = UsesPermission{ .android_name = "android.permission.WRITE_CALENDAR" };
    pub const writeCallLog = UsesPermission{ .android_name = "android.permission.WRITE_CALL_LOG" };
    pub const writeContacts = UsesPermission{ .android_name = "android.permission.WRITE_CONTACTS" };
    pub const writeExternalStorage = UsesPermission{ .android_name = "android.permission.WRITE_EXTERNAL_STORAGE" };
    pub const writeGservices = UsesPermission{ .android_name = "android.permission.WRITE_GSERVICES" };
    pub const writeProfile = UsesPermission{ .android_name = "android.permission.WRITE_PROFILE" };
    pub const writeSecureSettings = UsesPermission{ .android_name = "android.permission.WRITE_SECURE_SETTINGS" };
    pub const writeSettings = UsesPermission{ .android_name = "android.permission.WRITE_SETTINGS" };
    pub const writeSms = UsesPermission{ .android_name = "android.permission.WRITE_SMS" };
    pub const writeSocialStream = UsesPermission{ .android_name = "android.permission.WRITE_SOCIAL_STREAM" };
    pub const writeSyncSettings = UsesPermission{ .android_name = "android.permission.WRITE_SYNC_SETTINGS" };
    pub const writeUserDictionary = UsesPermission{ .android_name = "android.permission.WRITE_USER_DICTIONARY" };
    pub const writeVoicemail = UsesPermission{ .android_name = "com.android.voicemail.permission.WRITE_VOICEMAIL" };
};

/// Represents the <permission> element.
/// @see https://developer.android.com/guide/topics/manifest/permission-element
pub const Permission = struct {
    android_name: []const u8,
    android_label: []const u8,
    android_description: ?[]const u8 = null,
    android_icon: ?[]const u8 = null,
    android_permissionGroup: ?[]const u8 = null,
    android_protectionLevel: ?ProtectionLevel = null,
};

/// Permission protection levels.
pub const ProtectionLevel = enum {
    normal,
    dangerous,
    signature,
    signatureOrSystem,
};

/// Represents the <uses-feature> element.
/// @see https://developer.android.com/guide/topics/manifest/uses-feature-element
pub const UsesFeature = struct {
    android_name: ?[]const u8 = null,
    android_glEsVersion: ?i32 = null,
    android_required: ?bool = null,
};

/// Represents the <uses-sdk> element.
/// @see https://developer.android.com/guide/topics/manifest/uses-sdk-element
pub const UsesSdk = struct {
    android_minSdkVersion: ?i32 = null,
    android_targetSdkVersion: ?i32 = null,
    android_maxSdkVersion: ?i32 = null,
};

/// Represents the <uses-library> element.
/// @see https://developer.android.com/guide/topics/manifest/uses-library-element
pub const UsesLibrary = struct {
    android_name: []const u8,
    android_required: ?bool = null,
};

/// Represents the <uses-native-library> element.
/// @see https://developer.android.com/guide/topics/manifest/uses-native-library-element
pub const UsesNativeLibrary = struct {
    android_name: []const u8,
    android_required: ?bool = null,
};

/// Represents the <meta-data> element.
/// @see https://developer.android.com/guide/topics/manifest/meta-data-element
pub const MetaData = struct {
    android_name: []const u8,
    android_value: ?[]const u8 = null,
    android_resource: ?[]const u8 = null,
};

/// Represents the <permission-group> element.
/// @see https://developer.android.com/guide/topics/manifest/permission-group-element
pub const PermissionGroup = struct {
    android_name: []const u8,
    android_label: []const u8,
    android_description: ?[]const u8 = null,
    android_icon: ?[]const u8 = null,
};

/// Represents the <permission-tree> element.
/// @see https://developer.android.com/guide/topics/manifest/permission-tree-element
pub const PermissionTree = struct {
    android_name: []const u8,
    android_icon: ?[]const u8 = null,
    android_label: ?[]const u8 = null,
};

/// Represents the <instrumentation> element.
/// @see https://developer.android.com/guide/topics/manifest/instrumentation-element
pub const Instrumentation = struct {
    android_name: []const u8,
    android_targetPackage: []const u8,
    android_functionalTest: ?bool = null,
    android_handleProfiling: ?bool = null,
    android_icon: ?[]const u8 = null,
    android_label: ?[]const u8 = null,
    android_targetProcesses: ?[]const u8 = null,
};

/// Represents the <queries> element.
/// @see https://developer.android.com/guide/topics/manifest/queries-element
pub const Queries = struct {
    package: ?[]const struct { android_name: []const u8 } = null,
    intent: ?[]const IntentFilter = null,
    provider: ?[]const struct { android_authorities: []const u8 } = null,
};

/// Represents the <supports-screens> element.
/// @see https://developer.android.com/guide/topics/manifest/supports-screens-element
pub const SupportsScreens = struct {
    android_resizeable: ?bool = null,
    android_smallScreens: ?bool = null,
    android_normalScreens: ?bool = null,
    android_largeScreens: ?bool = null,
    android_xlargeScreens: ?bool = null,
    android_anyDensity: ?bool = null,
    android_requiresSmallestWidthDp: ?i32 = null,
    android_compatibleWidthLimitDp: ?i32 = null,
    android_largestWidthLimitDp: ?i32 = null,
};

/// Represents the <layout> element inside an <activity>.
/// @see https://developer.android.com/guide/topics/manifest/layout-element
pub const Layout = struct {
    android_defaultWidth: ?[]const u8 = null,
    android_defaultHeight: ?[]const u8 = null,
    android_gravity: ?[]const u8 = null,
    android_minWidth: ?[]const u8 = null,
    android_minHeight: ?[]const u8 = null,
};

/// Other elements
pub const SupportsGlTexture = struct { android_name: []const u8 };

pub const UsesConfiguration = struct {
    android_reqFiveWayNav: ?bool = null,
    android_reqHardKeyboard: ?bool = null,
    android_reqKeyboardType: ?ReqKeyboardType = null,
    android_reqNavigation: ?ReqNavigation = null,
    android_reqTouchScreen: ?ReqTouchScreen = null,
};

pub const ReqKeyboardType = enum {
    undefined,
    nokeys,
    qwerty,
    twelvekey,
};

pub const ReqNavigation = enum {
    undefined,
    nonav,
    dpad,
    trackball,
    wheel,
};

pub const ReqTouchScreen = enum {
    undefined,
    notouch,
    stylus,
    finger,
};

pub const CompatibleScreens = struct {
    screen: []const struct {
        android_screenSize: ScreenSize,
        android_screenDensity: ScreenDensity,
    },
};

pub const ScreenSize = enum {
    small,
    normal,
    large,
    xlarge,
};

pub const ScreenDensity = enum {
    ldpi,
    mdpi,
    hdpi,
    xhdpi,
};

pub const Attribution = struct { android_label: []const u8 };

pub const GrantUriPermission = struct {
    android_path: ?[]const u8 = null,
    android_pathPattern: ?[]const u8 = null,
    android_pathPrefix: ?[]const u8 = null,
};

pub const PathPermission = struct {
    android_path: ?[]const u8 = null,
    android_pathPattern: ?[]const u8 = null,
    android_pathPrefix: ?[]const u8 = null,
    android_permission: ?[]const u8 = null,
    android_readPermission: ?[]const u8 = null,
    android_writePermission: ?[]const u8 = null,
};

fn structToXMLTag(w: anytype, comptime name: []const u8, value: anytype, comptime depth: u32) !void {
    const V = @TypeOf(value);
    const v_info = @typeInfo(V);
    switch (v_info) {
        .optional => if (value) |v| try structToXMLTag(w, name, v, depth),
        .pointer => |info| switch (info.size) {
            .slice => for (value) |v| try structToXMLTag(w, name, v, depth),
            else => @compileError(std.fmt.comptimePrint("unhandled pointer type {s}", .{@typeName(V)})),
        },
        .@"struct" => |struct_info| {
            var transformed_name: [name.len]u8 = undefined;
            inline for (name, 0..) |c, i| {
                transformed_name[i] = switch (c) {
                    '_' => '-',
                    else => c,
                };
            }
            try splatByte(w, ' ', depth * 2);
            try w.print("<{s}", .{transformed_name});
            inline for (struct_info.fields) |*field| {
                const FieldType = field.type;
                const field_info = @typeInfo(FieldType);
                const is_element = switch (field_info) {
                    .@"struct" => true,
                    .pointer => |ptr| ptr.size == .slice and @typeInfo(ptr.child) == .@"struct",
                    .optional => |opt| switch (@typeInfo(opt.child)) {
                        .@"struct" => true,
                        .pointer => |ptr| ptr.size == .slice and @typeInfo(ptr.child) == .@"struct",
                        else => false,
                    },
                    else => false,
                };
                if (!is_element) {
                    try writeAttribute(w, field.name, @field(value, field.name), depth + 1);
                }
            }
            try w.writeAll(">\n");
            inline for (struct_info.fields) |*field| {
                const FieldType = field.type;
                const field_info = @typeInfo(FieldType);
                const is_element = switch (field_info) {
                    .@"struct" => true,
                    .pointer => |ptr| ptr.size == .slice and @typeInfo(ptr.child) == .@"struct",
                    .optional => |opt| switch (@typeInfo(opt.child)) {
                        .@"struct" => true,
                        .pointer => |ptr| ptr.size == .slice and @typeInfo(ptr.child) == .@"struct",
                        else => false,
                    },
                    else => false,
                };
                if (is_element) {
                    try structToXMLTag(w, field.name, @field(value, field.name), depth + 1);
                }
            }
            try splatByte(w, ' ', depth * 2);
            try w.print("</{s}>\n", .{transformed_name});
        },
        else => @compileError(std.fmt.comptimePrint("expected struct, found {s}", .{@typeName(V)})),
    }
}

fn writeAttribute(w: anytype, comptime name: []const u8, value: anytype, depth: u32) !void {
    comptime var transformed_name: [name.len]u8 = undefined;
    inline for (name, 0..) |c, i| {
        transformed_name[i] = switch (c) {
            '_' => ':',
            else => c,
        };
    }

    const V = @TypeOf(value);
    switch (V) {
        []const u8,
        [:0]const u8,
        => {
            try w.writeByte('\n');
            try splatByte(w, ' ', depth * 2);
            try w.print("{s}=\"{s}\"", .{ transformed_name, value });
        },
        i32, bool => {
            try w.writeByte('\n');
            try splatByte(w, ' ', depth * 2);
            try w.print("{s}=\"{}\"", .{ transformed_name, value });
        },
        else => {
            const value_info = @typeInfo(V);
            switch (value_info) {
                .optional => if (value) |v| try writeAttribute(w, name, v, depth),
                .@"enum" => try writeAttribute(w, name, @tagName(value), depth),
                .pointer => |info| switch (info.size) {
                    .slice => {
                        try w.writeByte('\n');
                        try splatByte(w, ' ', depth * 2);
                        try w.print("{s}=\"", .{transformed_name});
                        for (value, 0..) |v, i| {
                            if (i != 0) try w.print("|", .{});
                            switch (@TypeOf(v)) {
                                []const u8, [:0]const u8 => try w.print("{s}", .{v}),
                                else => |_V| switch (@typeInfo(_V)) {
                                    .@"enum" => try w.print("{s}", .{@tagName(v)}),
                                    else => @compileError(std.fmt.comptimePrint("unhandled attribute {s} of type {s}", .{ name, @typeName(V) })),
                                },
                            }
                        }
                        try w.writeByte('"');
                    },
                    else => @compileError(std.fmt.comptimePrint("unhandled attribute {s} of type {s}", .{ name, @typeName(V) })),
                },
                else => @compileError(std.fmt.comptimePrint("unhandled type {s}", .{@typeName(V)})),
            }
        },
    }
}

fn splatByte(w: anytype, byte: u8, count: u32) !void {
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        try w.writeByte(byte);
    }
}
