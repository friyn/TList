import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateConfig {
  final String manifestUrl;
  // Optional: key names in manifest
  const AppUpdateConfig({required this.manifestUrl});
}

class AppUpdateInfo {
  final String version; // e.g. 1.2.0+5
  final String? title;
  final String? notes;
  final String? url; // generic fallback
  final String? urlAndroid;
  final String? urlWindows;
  final String? urlWeb;
  final String? minForce; // if set and > current, force update

  AppUpdateInfo({
    required this.version,
    this.title,
    this.notes,
    this.url,
    this.urlAndroid,
    this.urlWindows,
    this.urlWeb,
    this.minForce,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> j) {
    return AppUpdateInfo(
      version: (j['version'] ?? '').toString(),
      title: j['title'] as String?,
      notes: j['notes'] as String?,
      url: j['url'] as String?,
      urlAndroid: j['url_android'] as String?,
      urlWindows: j['url_windows'] as String?,
      urlWeb: j['url_web'] as String?,
      minForce: j['min_force'] as String?,
    );
  }
}

class UpdateCheckResult {
  final String currentVersion;
  final AppUpdateInfo? info;
  final bool isNewer;
  final bool forced;

  UpdateCheckResult({
    required this.currentVersion,
    required this.info,
    required this.isNewer,
    required this.forced,
  });
}

class AppUpdate {
  static const _prefsDismissKey = 'dismissed_update_version';

  static Future<void> checkAndPrompt(
    BuildContext context, {
    required AppUpdateConfig config,
    bool silentOnError = true,
    bool ignoreDismiss = true,
  }) async {
    try {
      final info = await _fetchUpdateInfo(config.manifestUrl);
      if (info == null) return;

      final pkg = await PackageInfo.fromPlatform();
      final currentVersion = '${pkg.version}+${pkg.buildNumber}';

      final isNewer = _isRemoteNewer(currentVersion, info.version);
      if (!isNewer) return;

      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getString(_prefsDismissKey);

      final forced = info.minForce != null && _isRemoteNewer(currentVersion, info.minForce!);
      if (!forced && !ignoreDismiss && dismissed == info.version) {
        return; // already dismissed this optional version
      }

      if (!context.mounted) return;
      await _showDialog(context, info, forced: forced, onDismissRemember: () async {
        await prefs.setString(_prefsDismissKey, info.version);
      });
    } catch (e) {
      if (!silentOnError) {
        // Optionally log
        debugPrint('Update check error: $e');
      }
    }
  }

  static Future<AppUpdateInfo?> _fetchUpdateInfo(String url) async {
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final data = json.decode(res.body) as Map<String, dynamic>;
    return AppUpdateInfo.fromJson(data);
  }

  static bool _isRemoteNewer(String current, String remote) {
    // Parse like 1.2.3+45 into [1,2,3,45]
    List<int> parse(String v) {
      final parts = v.split('+');
      final ver = parts[0];
      final build = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      final nums = ver.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      while (nums.length < 3) nums.add(0);
      nums.add(build);
      return nums;
    }

    final a = parse(current);
    final b = parse(remote);
    for (int i = 0; i < a.length && i < b.length; i++) {
      if (b[i] > a[i]) return true;
      if (b[i] < a[i]) return false;
    }
    return false; // equal
  }

  /// Fetch update status along with manifest details and current version.
  static Future<UpdateCheckResult> getStatus({
    required AppUpdateConfig config,
  }) async {
    try {
      final info = await _fetchUpdateInfo(config.manifestUrl);
      final pkg = await PackageInfo.fromPlatform();
      final currentVersion = '${pkg.version}+${pkg.buildNumber}';
      final isNewer = info != null ? _isRemoteNewer(currentVersion, info.version) : false;
      final forced = info != null && info.minForce != null
          ? _isRemoteNewer(currentVersion, info.minForce!)
          : false;
      return UpdateCheckResult(
        currentVersion: currentVersion,
        info: info,
        isNewer: isNewer,
        forced: forced,
      );
    } catch (_) {
      final pkg = await PackageInfo.fromPlatform();
      return UpdateCheckResult(
        currentVersion: '${pkg.version}+${pkg.buildNumber}',
        info: null,
        isNewer: false,
        forced: false,
      );
    }
  }

  /// Returns true if a newer version than the currently installed app is available.
  static Future<bool> isUpdateAvailable({
    required AppUpdateConfig config,
  }) async {
    try {
      final info = await _fetchUpdateInfo(config.manifestUrl);
      if (info == null) return false;
      final pkg = await PackageInfo.fromPlatform();
      final currentVersion = '${pkg.version}+${pkg.buildNumber}';
      return _isRemoteNewer(currentVersion, info.version);
    } catch (_) {
      return false;
    }
  }

  static Future<void> _showDialog(
    BuildContext context,
    AppUpdateInfo info, {
    required bool forced,
    required Future<void> Function() onDismissRemember,
  }) async {
    final title = info.title ?? 'Pembaruan Tersedia';
    final notes = info.notes ?? 'Versi baru: ${info.version}';

    return showDialog(
      context: context,
      barrierDismissible: !forced,
      builder: (ctx) {
        return WillPopScope(
          onWillPop: () async => !forced,
          child: AlertDialog(
            title: Text(title),
            content: Text(notes),
            actions: [
              if (!forced)
                TextButton(
                  onPressed: () async {
                    await onDismissRemember();
                    if (context.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('Nanti'),
                ),
              ElevatedButton(
                onPressed: () async {
                  final url = info.url ?? info.urlAndroid ?? info.urlWindows ?? info.urlWeb;
                  final opened = await _openUpdateUrl(context, url);
                  if (!forced) {
                    if (context.mounted) Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<bool> _openUpdateUrl(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      _showSnack(context, 'URL update tidak tersedia');
      return false;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnack(context, 'URL update tidak valid');
      return false;
    }
    try {
      if (kIsWeb) {
        // Di web, buka tab baru agar tidak diblokir popup blocker
        return await launchUrl(uri, webOnlyWindowName: '_blank');
      } else {
        // Mobile/desktop: buka aplikasi eksternal (browser/store)
        if (await canLaunchUrl(uri)) {
          return await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (_) {}
    _showSnack(context, 'Gagal membuka tautan update');
    return false;
  }

  static void _showSnack(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
