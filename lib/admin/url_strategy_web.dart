import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Disables Flutter's browser-history integration. The dashboard is opened
/// from a local launcher file whose `<base>` points at the Supabase function
/// origin; history.replaceState against a cross-origin URL throws a
/// SecurityError loop, and the dashboard has no deep links to preserve.
void disableUrlHistory() => setUrlStrategy(null);
