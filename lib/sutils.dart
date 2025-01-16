import 'dart:async';

import 'src/plugin/desktop_plugin.dart' as desktop;
import 'src/plugin/android_plugin.dart' as android;

final class SUtils {
    static late Future<void> Function() _initializer;
    static Future<void> ensureInitialized() => SUtils._initializer();
}

final class EPlatformAndroid {
    EPlatformAndroid._();
    static void registerWith() => SUtils._initializer = android.registerWith;
}

final class SUtilsDesktop {
    SUtilsDesktop._();
    static void registerWith() => SUtils._initializer = desktop.registerWith;
}
