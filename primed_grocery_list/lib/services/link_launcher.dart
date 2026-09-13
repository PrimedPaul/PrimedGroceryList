import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the external browser and reports failures via a SnackBar.
///
/// Deliberately skips `canLaunchUrl`: on Android 11+ that preflight returns
/// false unless the manifest declares a matching `<queries>` intent, even when
/// a browser is installed. `launchUrl`'s own result is the reliable signal.
Future<void> openExternalLink(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  var launched = false;
  try {
    launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on PlatformException {
    launched = false;
  }
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open link')),
    );
  }
}
