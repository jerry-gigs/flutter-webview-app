import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateRequiredScreen extends StatefulWidget {
  final Map<String, dynamic> updateInfo;
  final VoidCallback? onRetry; // Optional retry callback
  
  const UpdateRequiredScreen({
    super.key, 
    required this.updateInfo,
    this.onRetry,
  });
  
  @override
  State<UpdateRequiredScreen> createState() => _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends State<UpdateRequiredScreen> {
  bool _isLaunching = false;
  
  Future<void> _launchUpdateURL() async {
    final url = widget.updateInfo['update_url'];
    print('🔄 Launching URL: $url');
    
    // Enhanced URL validation
    if (url == null || url.toString().isEmpty) {
      _showErrorDialog('Download link is not available. Please contact support.');
      return;
    }
    
    if (_isLaunching) return;
    
    setState(() => _isLaunching = true);
    
    try {
      final Uri uri = Uri.parse(url.toString());
      
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        print('❌ launchUrl returned false');
        _showErrorDialog('Could not open the download link. Please try again.');
      } else {
        print('✅ URL launched successfully');
      }
    } catch (e) {
      print('❌ Exception: $e');
      _showErrorDialog('Error opening link: $e');
    } finally {
      setState(() => _isLaunching = false);
    }
  }

  void _showErrorDialog(String message) {
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
  
  void _showExitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Required'),
        content: const Text('You must update the app to continue using it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchUpdateURL();
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  void _retryVersionCheck() {
    if (widget.onRetry != null) {
      widget.onRetry!();
    } else {
      // Fallback: try to launch the URL again
      _launchUpdateURL();
    }
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
                widget.updateInfo['title'] ?? 'Update Required',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                widget.updateInfo['message'] ?? 'Please update to the latest version to continue using the app.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Enhanced version information
              if (widget.updateInfo['current_app_version'] != null && 
                  widget.updateInfo['min_required_version'] != null)
                Column(
                  children: [
                    Text(
                      'Your version: ${widget.updateInfo['current_app_version']}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Required version: ${widget.updateInfo['min_required_version']}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                    // Show latest available version if available
                    if (widget.updateInfo['current_remote_version'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Latest version: ${widget.updateInfo['min_required_version']}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              
              // Update button with loading state
              ElevatedButton(
                onPressed: _isLaunching ? null : _launchUpdateURL,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  minimumSize: const Size(200, 50),
                ),
                child: _isLaunching
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'UPDATE NOW',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              
              // Not Now button (only shows if force_update is false)
              if (widget.updateInfo['force_update'] != true)
                TextButton(
                  onPressed: () {
                    // Allow user to continue if update is not forced
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Not Now',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                ),
              
              // Exit App button (shows when force_update is true)
              if (widget.updateInfo['force_update'] == true)
                TextButton(
                  onPressed: _showExitDialog,
                  child: const Text(
                    'Not Now',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                ),
              
              // Retry button (shows when there's an error)
              if (widget.updateInfo['error'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton(
                    onPressed: _retryVersionCheck,
                    child: const Text(
                      'Retry Check',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              
              // Show error message if exists
              if (widget.updateInfo['error'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Error: ${widget.updateInfo['error']}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}