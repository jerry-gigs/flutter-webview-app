import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateRequiredScreen extends StatelessWidget {
  final Map<String, dynamic> updateInfo;
  
  const UpdateRequiredScreen({super.key, required this.updateInfo});
  
  Future<void> _launchUpdateURL(BuildContext context) async {
    final url = updateInfo['update_url'];
    print('🔄 Launching URL: $url');
    
    if (url != null) {
      try {
        // Try to launch the URL directly without checking canLaunchUrl first
        final Uri uri = Uri.parse(url);
        
        bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (!launched) {
          print('❌ launchUrl returned false');
          _showErrorDialog(context, 'Could not open the download link. Please try again.');
        } else {
          print('✅ URL launched successfully');
        }
      } catch (e) {
        print('❌ Exception: $e');
        _showErrorDialog(context, 'Error opening link: $e');
      }
    } else {
      _showErrorDialog(context, 'Download URL is not available.');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(29, 30, 37, 1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.update,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                updateInfo['title'] ?? 'Update Required',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                updateInfo['message'] ?? 'Please update to the latest version to continue using the app.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (updateInfo['current_app_version'] != null && updateInfo['min_required_version'] != null)
                Column(
                  children: [
                    Text(
                      'Your version: ${updateInfo['current_app_version']}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Required version: ${updateInfo['min_required_version']}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ElevatedButton(
                onPressed: () => _launchUpdateURL(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'UPDATE NOW',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  if (updateInfo['force_update'] == true) {
                    _showExitDialog(context);
                  }
                },
                child: const Text(
                  'Not Now',
                  style: TextStyle(
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Required'),
        content: const Text('You must update the app to continue using it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchUpdateURL(context);
            },
            child: const Text('UPDATE NOW'),
          ),
        ],
      ),
    );
  }
}