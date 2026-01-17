import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ForceUpdateChecker extends StatefulWidget {
  final Widget child;
  final String firestoreCollection;
  final String firestoreDocument;
  final String versionField;
  final String urlField;
  
  /// Custom widget to show when update is required. 
  /// If null, a default Material/Cupertino screen will be shown.
  final Widget Function(BuildContext context, String updateUrl)? updateScreenBuilder;

  const ForceUpdateChecker({
    Key? key,
    required this.child,
    this.firestoreCollection = 'app_config',
    this.firestoreDocument = 'force_update',
    this.versionField = 'minimumVersion',
    this.urlField = 'updateUrl',
    this.updateScreenBuilder,
  }) : super(key: key);

  @override
  State<ForceUpdateChecker> createState() => _ForceUpdateCheckerState();
}

class _ForceUpdateCheckerState extends State<ForceUpdateChecker> {
  String? _currentVersion;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _currentVersion = info.version;
      });
    }
  }

  bool _isUpdateRequired(String minVersionString) {
    if (_currentVersion == null) return false;
    try {
      final current = Version.parse(_currentVersion!);
      final min = Version.parse(minVersionString);
      return current < min;
    } catch (e) {
      debugPrint('Error parsing version: $e');
      return false;
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentVersion == null) {
      // While loading version, just show child or loading? 
      // Showing child is safer to avoid blocking app start if getting version is slow.
      return widget.child;
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(widget.firestoreCollection)
          .doc(widget.firestoreDocument)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return widget.child;
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return widget.child;

        final minVersion = data[widget.versionField] as String?;
        final updateUrl = data[widget.urlField] as String? ?? '';

        if (minVersion != null && _isUpdateRequired(minVersion)) {
          // FORCE UPDATE REQUIRED
          
          if (widget.updateScreenBuilder != null) {
            return widget.updateScreenBuilder!(context, updateUrl);
          }

          return _buildDefaultUpdateScreen(updateUrl);
        }

        return widget.child;
      },
    );
  }

  Widget _buildDefaultUpdateScreen(String updateUrl) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          padding: const EdgeInsets.all(32),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update_alt, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Update Required',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'A new version of the app is available. Please update to continue using the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _launchUrl(updateUrl),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Update Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
