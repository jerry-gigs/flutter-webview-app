import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart' as mobile_webview;
import 'package:webview_windows/webview_windows.dart' as windows_webview;
//import 'components/header_component.dart';
import 'services/webview_services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewService webViewService;
  final urlController = TextEditingController();
  bool _isLoading = true;
  bool _isWindows = false;

  @override
  void initState() {
    super.initState();
    _isWindows = _checkIfWindows();
    webViewService = WebViewService();
    _initWebView();
  }

  bool _checkIfWindows() {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  // Handle Android back button
  Future<bool> _onWillPop() async {
    if (!_isWindows) {
      // Check if webview can go back
      final canGoBack = await (webViewService.controller as mobile_webview.WebViewController).canGoBack();
      if (canGoBack) {
        // If can go back, navigate back in webview
        await webViewService.goBack();
        return false; // Don't exit app
      }
    }
    // If can't go back or on Windows, allow exit
    return true;
  }

  Future<void> _initWebView() async {
    try {
      await webViewService.initialize();
      
      // Update _isWindows in case initialization failed and fell back to mobile
      _isWindows = webViewService.isWindows;

      // For mobile webview, enable JavaScript and set better settings
      if (!_isWindows) {
        // Access the mobile controller directly to set JavaScript mode
        final mobileController = webViewService.controller as mobile_webview.WebViewController;
        await mobileController.setJavaScriptMode(mobile_webview.JavaScriptMode.unrestricted);
        
        await mobileController.setNavigationDelegate(
          mobile_webview.NavigationDelegate(
            onPageStarted: (url) {
              setState(() {
                _isLoading = true;
              });
            },
            onPageFinished: (url) {
              setState(() {
                _isLoading = false;
                urlController.text = url;
              });
            },
            onWebResourceError: (error) {
              setState(() {
                _isLoading = false;
              });
              print('WebView Error: ${error.description}');
            },
            onProgress: (progress) {
              print('Loading progress: $progress%');
            },
          ),
        );
      } else {
        // Windows-specific listeners
        (webViewService.controller as windows_webview.WebviewController)
          .loadingState.listen((state) {
            setState(() {
              _isLoading = state == windows_webview.LoadingState.loading;
            });
          });

        (webViewService.controller as windows_webview.WebviewController)
          .url.listen((url) {
            if (url != null) {
              setState(() {
                urlController.text = url;
              });
            }
          });
      }

      // Set user agent for consistent behavior
      await webViewService.setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0'
      );

      // Load the URL with timeout
      await _loadUrlWithTimeout(
        'https://experience.4excelerate.org/auth/login?returnUrl=%2Fdashboard',
      );
    } catch (e) {
      print('WebView initialization error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUrlWithTimeout(String url) async {
    try {
      // Set a timeout for loading
      await webViewService.loadUrl(url).timeout(const Duration(seconds: 30));
    } catch (e) {
      print('Timeout loading URL: $e');
      // Fallback: Try loading without parameters
      await webViewService.loadUrl('https://experience.4excelerate.org');
    }
  }

  void _loadUrl() {
    final url = urlController.text.trim();
    if (url.isNotEmpty) {
      webViewService.loadUrl(url);
    }
  }

  /*void _clearCache() async {
    try {
      await webViewService.clearCookies();
      if (!_isWindows) {
        await webViewService.clearCache();
      }
      webViewService.reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared')),
      );
    } catch (e) {
      print('Error clearing cookies: $e');
    }
  }*/

  /*void _testGoogleSignup() {
    webViewService.loadUrl('https://accounts.google.com/signup');
  }*/

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // This handles the Android back button
      child: Scaffold(
        /*appBar: AppBar(
          title: HeaderComponent(
            webViewService: webViewService,
            urlController: urlController,
            onClearCache: _clearCache,
            onTestGoogleSignup: _testGoogleSignup,
            onLoadUrl: _loadUrl,
          ),
        ),*/
          appBar: AppBar(
            toolbarHeight: 40, // We can adjust this as need be
            backgroundColor: Colors.transparent, // We can change this as we update
            elevation: 0, // no shadow
              ),

        body: Stack(
          children: [
            _buildWebView(),
            if (_isLoading)
              const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    if (!_isWindows) {
      return mobile_webview.WebViewWidget(
        controller: webViewService.controller as mobile_webview.WebViewController,
      );
    } else {
      return ValueListenableBuilder<windows_webview.WebviewValue>(
        valueListenable: webViewService.controller as windows_webview.WebviewController,
        builder: (context, value, child) {
          if (!value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return windows_webview.Webview(
            webViewService.controller as windows_webview.WebviewController,
          );
        },
      );
    }
  }
}