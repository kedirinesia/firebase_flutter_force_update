import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

class VersionUtils {
  /// Check if the [currentVersion] is less than the [minVersion].
  static bool isUpdateRequired(String currentVersion, String minVersion) {
    try {
      final current = Version.parse(currentVersion);
      final min = Version.parse(minVersion);
      return current < min;
    } catch (e) {
      // If parsing fails, rely on direct string comparison or assume no update to be safe
      return false; 
    }
  }

  /// Get the current app version.
  static Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
