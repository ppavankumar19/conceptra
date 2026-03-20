import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants.dart';
import 'api_client.dart';

class PendingSimulation {
  final String id;
  final String moduleId;
  final Map<String, double> parameters;
  final DateTime queuedAt;

  PendingSimulation({
    required this.id,
    required this.moduleId,
    required this.parameters,
    required this.queuedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'module_id': moduleId,
        'parameters': parameters,
        'queued_at': queuedAt.toIso8601String(),
      };

  factory PendingSimulation.fromJson(Map<String, dynamic> json) =>
      PendingSimulation(
        id: json['id'] as String,
        moduleId: json['module_id'] as String,
        parameters: Map<String, double>.from(json['parameters'] as Map),
        queuedAt: DateTime.parse(json['queued_at'] as String),
      );
}

class OfflineSyncService {
  final Dio _dio;
  Box? _syncBox;
  StreamSubscription? _connectivitySubscription;

  OfflineSyncService(this._dio);

  Future<void> initialize() async {
    _syncBox = await Hive.openBox(AppConstants.syncQueueBoxName);
    _startConnectivityListener();
  }

  void _startConnectivityListener() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        syncPendingSimulations();
      }
    });
  }

  Future<void> queueSimulation(PendingSimulation simulation) async {
    final box = _syncBox;
    if (box == null) return;
    await box.put(simulation.id, jsonEncode(simulation.toJson()));
  }

  Future<void> syncPendingSimulations() async {
    final box = _syncBox;
    if (box == null || box.isEmpty) return;

    final keys = box.keys.toList();
    for (final key in keys) {
      try {
        final raw = box.get(key) as String?;
        if (raw == null) continue;

        final sim = PendingSimulation.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);

        await _dio.post(
          '/simulate',
          data: {
            'module_id': sim.moduleId,
            'parameters': sim.parameters,
          },
        );

        await box.delete(key);
      } catch (_) {
        // Keep in queue for next sync attempt
      }
    }
  }

  int get pendingCount => _syncBox?.length ?? 0;

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _syncBox?.close();
  }
}

final offlineSyncProvider = Provider<OfflineSyncService>((ref) {
  final dio = ref.watch(apiClientProvider);
  final service = OfflineSyncService(dio);
  ref.onDispose(() => service.dispose());
  return service;
});
