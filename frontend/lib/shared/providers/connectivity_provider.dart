import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final isOnlineProvider = Provider<bool>((ref) {
  // On Flutter web, connectivity_plus uses navigator.onLine which returns
  // false for local-only networks. Always treat web as online and let
  // actual API errors surface through the normal error handling path.
  if (kIsWeb) return true;

  final connectivityResult = ref.watch(connectivityProvider);
  return connectivityResult.whenOrNull(
        data: (results) =>
            results.isNotEmpty &&
            results.any((r) => r != ConnectivityResult.none),
      ) ??
      true;
});
