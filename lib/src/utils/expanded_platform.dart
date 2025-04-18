import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final class EPlatform {
    EPlatform._();

    static bool get isWeb => kIsWeb;
    static bool get isDesktop => !EPlatform.isTV && !EPlatform.isWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    static bool get isMobile => !EPlatform.isTV && !EPlatform.isWeb && (Platform.isAndroid || Platform.isIOS);

    static bool get isMobileWeb => EPlatform.isWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
    static bool get isDesktopWeb => EPlatform.isWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS);

    static bool get isTablet => EPlatform.isMobile && MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.single).size.shortestSide >= 600;

    static late final bool isAndroidTV;
    static late final bool isTizenTV;
    static bool get isTV => EPlatform.isAndroidTV || EPlatform.isTizenTV;
}

