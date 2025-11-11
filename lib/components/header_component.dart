/*

import 'package:flutter/material.dart';
import '../services/webview_services.dart';

class HeaderComponent extends StatelessWidget {
  final WebViewService webViewService;
  final TextEditingController urlController;
  final VoidCallback onClearCache;
  final VoidCallback onTestGoogleSignup;
  final VoidCallback onLoadUrl;

  const HeaderComponent({
    super.key,
    required this.webViewService,
    required this.urlController,
    required this.onClearCache,
    required this.onTestGoogleSignup,
    required this.onLoadUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => webViewService.goBack(),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward, color: Colors.grey),
          onPressed: () => webViewService.goForward(),
        ),
        Expanded(
          child: TextField(
            controller: urlController,
            decoration: InputDecoration(
              hintText: 'Enter url',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Colors.grey,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.green,
                  width: 2.0,
                ),
              ),
            ),
            onSubmitted: (_) => onLoadUrl(),
            textInputAction: TextInputAction.go,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.clear_all, color: Colors.grey),
          onPressed: onClearCache,
          tooltip: 'Clear Cache',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.grey),
          onPressed: () => webViewService.reload(),
          tooltip: 'Reload page',
        ),
        IconButton(
          icon: const Icon(Icons.mail, color: Colors.grey),
          onPressed: onTestGoogleSignup,
          tooltip: 'Google Signup',
        ),
      ],
    );
  }
}
*/