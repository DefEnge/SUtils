import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:process_run/process_run.dart';
import 'package:sutils/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:win32_registry/win32_registry.dart';

abstract class Updater {
    static Future<Map<String, dynamic>> get latestRelease async {
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String release = await HTTP.get('https://api.github.com/repos/StronzLabs/${packageInfo.appName}/releases/latest');
        return jsonDecode(release);
    }

    static Future<Stream<double>?> update() async {
        return Updater.create().doUpdate();
    }

    static Future<String> get platformUrl async {
        String platform;
        if(Platform.isAndroid)
            platform = ".apk";
        else if(Platform.isWindows)
            platform = ".msi";
        else if(Platform.isLinux)
            platform = ".AppImage";
        else if(Platform.isMacOS)
            platform = "MacOS";
        else
            throw Exception("Unsupported platform");

        List<Map<String, dynamic>> assets = (await Updater.latestRelease)['assets']
            .map<Map<String, dynamic>>((dynamic asset) => asset as Map<String, dynamic>).toList();

        for (Map<String, dynamic> asset in assets) {
            if(asset['name'].toString().contains(platform)) {
                String url = asset['browser_download_url'];
                return url;
            }
        }

        throw Exception("No asset found for platform ${platform}");
    }

    Future<Stream<double>?> doUpdate();

    static Updater create() {
        if(Platform.isAndroid)
            return AndroidUpdater();
        else if(Platform.isWindows)
            return WindowsUpdater();
        else
            return GenericUpdater();
    }

    static Future<Stream<double>?> downloadPlatformFile(Function(TaskStatusUpdate result) then) async {
        DownloadTask task = DownloadTask(
            url: await Updater.platformUrl,
            baseDirectory: BaseDirectory.temporary
        );

        StreamController<double> progressController = StreamController<double>.broadcast();

        FileDownloader().download(task,
            onProgress: (progress) => progressController.add(progress)
        ).then(then);

        return progressController.stream;
    }
}

class AndroidUpdater extends Updater {
    @override
    Future<Stream<double>?> doUpdate() async {
        return Updater.downloadPlatformFile((result) async {
            await FileDownloader().openFile(task: result.task);
        });
    }
}

class WindowsUpdater extends Updater {
    Future<bool> _isPortable() async {
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String appName = packageInfo.appName;
        try {
            RegistryKey key = Registry.openPath(RegistryHive.currentUser, path: "Software\\${appName}");
            key.close();
            return false;
        } catch(_) {}
        return true;
    }

    Future<Stream<double>?> _msiUpdate() async  {
        return Updater.downloadPlatformFile((result) async {
            String path = await result.task.filePath();
            String command = 'msiexec /i "${path}" /qb /norestart';
            try {
                await Shell().run(command);
            } catch (_) {}
            exit(0);
        });
    }

    @override
    Future<Stream<double>?> doUpdate() async {
        if(await this._isPortable())
            return GenericUpdater().doUpdate(); 

        return this._msiUpdate();
    }
}

class GenericUpdater extends Updater {
    @override
    Future<Stream<double>?> doUpdate() async {
        Uri uri = Uri.parse(await Updater.platformUrl);
        if (await canLaunchUrl(uri))
            await launchUrl(uri);
        else
            throw Exception("Could not launch ${uri}");

        return null;
    }
}
