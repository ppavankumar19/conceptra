import 'package:flutter_test/flutter_test.dart';

import 'package:conceptra/features/simulations/providers/simulation_provider.dart';

void main() {
  group('SimulationState', () {
    test('initial state has empty parameters', () {
      const state = SimulationState();
      expect(state.parameters, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.result, isNull);
      expect(state.error, isNull);
      expect(state.isOfflineQueued, isFalse);
    });

    test('copyWith updates parameters correctly', () {
      const state = SimulationState(parameters: {'speed': 10.0});
      final updated = state.copyWith(
        parameters: {'speed': 20.0, 'time': 5.0},
      );
      expect(updated.parameters['speed'], 20.0);
      expect(updated.parameters['time'], 5.0);
      expect(updated.isLoading, isFalse);
    });

    test('copyWith clearError resets error to null', () {
      const state = SimulationState(error: 'Some error');
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    test('copyWith clearResult resets result to null', () {
      const result = SimulationResult(
        resultValue: 42.0,
        resultUnit: 'm/s',
        resultLabel: 'Speed',
        formula: 'v = d/t',
        substitution: 'v = 100/2',
        conclusion: 'The speed is 50 m/s',
        graphData: [],
        sessionId: 'test-session-id',
        topic: '',
      );
      const state = SimulationState(result: result);
      final cleared = state.copyWith(clearResult: true);
      expect(cleared.result, isNull);
    });

    test('copyWith preserves unmodified fields', () {
      const state = SimulationState(
        parameters: {'distance': 100.0},
        isLoading: false,
        error: null,
        isOfflineQueued: false,
      );
      final updated = state.copyWith(isLoading: true);
      expect(updated.parameters['distance'], 100.0);
      expect(updated.isLoading, isTrue);
    });
  });

  group('SimulationResult', () {
    test('fromJson parses correctly', () {
      final json = {
        'result_value': 50.0,
        'result_unit': 'm/s',
        'result_label': 'Speed',
        'topic': 'speed',
        'explanation': {
          'formula': 'v = d/t',
          'substitution': 'v = 100/2 = 50',
          'conclusion': 'The object moves at 50 m/s',
        },
        'graph_data': [
          {'x': 0.0, 'y': 0.0},
          {'x': 1.0, 'y': 50.0},
          {'x': 2.0, 'y': 100.0},
        ],
        'session_id': 'abc-123',
      };

      final result = SimulationResult.fromJson(json);

      expect(result.resultValue, 50.0);
      expect(result.resultUnit, 'm/s');
      expect(result.resultLabel, 'Speed');
      expect(result.topic, 'speed');
      expect(result.formula, 'v = d/t');
      expect(result.substitution, 'v = 100/2 = 50');
      expect(result.conclusion, 'The object moves at 50 m/s');
      expect(result.graphData.length, 3);
      expect(result.sessionId, 'abc-123');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'result_value': 25.5,
      };

      final result = SimulationResult.fromJson(json);

      expect(result.resultValue, 25.5);
      expect(result.resultUnit, '');
      expect(result.resultLabel, 'Result');
      expect(result.formula, '');
      expect(result.conclusion, '');
      expect(result.graphData, isEmpty);
      expect(result.sessionId, '');
    });

    test('toJson serializes correctly', () {
      const result = SimulationResult(
        resultValue: 10.0,
        resultUnit: 'km/h',
        resultLabel: 'Velocity',
        formula: 'v = d/t',
        substitution: '',
        conclusion: 'Fast',
        graphData: [GraphPoint(0, 0), GraphPoint(1, 10)],
        sessionId: 'xyz',
        topic: '',
      );

      final json = result.toJson();

      expect(json['result_value'], 10.0);
      expect(json['result_unit'], 'km/h');
      expect(json['graph_data'], hasLength(2));
    });
  });

  group('GraphPoint', () {
    test('fromJson parses x and y correctly', () {
      final point = GraphPoint.fromJson({'x': 3.5, 'y': 7.0});
      expect(point.x, 3.5);
      expect(point.y, 7.0);
    });

    test('toJson serializes correctly', () {
      const point = GraphPoint(2.0, 4.0);
      final json = point.toJson();
      expect(json['x'], 2.0);
      expect(json['y'], 4.0);
    });
  });
}
