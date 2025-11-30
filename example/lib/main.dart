import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:code_asset_example/native_library.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NativeLibraryProvider.instance;
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String _fibonacciResult =
      'Ready to benchmark - Click "🚀 Run Benchmarks" to start';
  String _factorialResult =
      'Ready to benchmark - Click "🚀 Run Benchmarks" to start';
  String _batchResult =
      'Ready to benchmark - Click "🚀 Run Benchmarks" to start';
  String _monteCarloResult =
      'Ready to benchmark - Click "🚀 Run Benchmarks" to start';
  String _performanceResult =
      'Ready to benchmark - Click "🚀 Run Benchmarks" to start';
  bool _nativeAvailable = false;

  // Algorithm selection
  String _selectedAlgorithm =
      'factorial'; // 'fibonacci', 'factorial', 'matrix', 'montecarlo'

  // Configurable parameters
  int _fibonacciN = 20;
  int _factorialN = 40;
  int _batchSize = 50;
  int _monteCarloSamples = 100000;

  // Matrix multiplication parameters
  int _matrixM = 5;
  int _matrixK = 8;
  int _matrixN = 10;

  // Performance data for charts
  double _ffiFibTime = 0;
  double _dartFibTime = 0;
  double _ffiFactTime = 0;
  double _dartFactTime = 0;
  double _ffiBatchTime = 0;
  double _ffiIsolateFibTime = 0;
  double _ffiIsolateFactTime = 0;

  // Matrix multiplication performance data
  double _ffiMatrixTime = 0;
  double _dartMatrixTime = 0;

  // Monte Carlo Pi performance data
  double _ffiMonteCarloTime = 0;
  double _dartMonteCarloTime = 0;

  // Real-time chart data
  final List<FlSpot> _ffiSinglePoints = [];
  final List<FlSpot> _ffiBatchPoints = [];
  final List<FlSpot> _dartSinglePoints = [];
  final List<FlSpot> _dartBatchPoints = [];
  double _chartTime = 0;
  Timer? _performanceTimer;
  final int _maxDataPoints = 50;
  bool _isMonitoringActive = false;

  @override
  void initState() {
    super.initState();
    _initializeLibrary();
    _startRealTimeMonitoring();
  }

  @override
  void dispose() {
    _performanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLibrary() async {
    try {
      // Test if native library is available
      await NativeLibraryProvider.fibo(5);
      setState(() => _nativeAvailable = true);

      // Run a quick initialization benchmark to get baseline data for real-time monitoring
      // This is much lighter than the full benchmark and won't cause lag
      await _runQuickInitializationBenchmark();
    } catch (e) {
      // For demo purposes, show that library loading was attempted
      // In a real app, you would handle this more gracefully
      setState(() {
        _nativeAvailable = false;
        _fibonacciResult =
            '❌ Library loading failed (expected in sandboxed environment)\nError: $e';
        _factorialResult =
            '❌ Library loading failed (expected in sandboxed environment)\nError: $e';
        _batchResult =
            '❌ Library loading failed (expected in sandboxed environment)\nError: $e';
        _performanceResult =
            '❌ Library loading failed (expected in sandboxed environment)\n\nNote: This demo shows how to integrate native libraries with Flutter. In production, libraries should be bundled with the app.';
      });
    }
  }

  Future<void> _runQuickInitializationBenchmark() async {
    if (!_nativeAvailable) return;

    try {
      // Quick benchmark with minimal iterations to get baseline timing data
      final stopwatch = Stopwatch();

      // Reset timing data for the selected algorithm
      if (_selectedAlgorithm == 'fibonacci') {
        // Get basic FFI timing for Fibonacci (just a few iterations)
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < 5; i++) {
          await NativeLibraryProvider.fibo(_fibonacciN);
        }
        stopwatch.stop();
        _ffiFibTime = stopwatch.elapsedMicroseconds / 5.0;

        // Get basic Dart timing for Fibonacci
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < 50; i++) {
          fiboDart(_fibonacciN);
        }
        stopwatch.stop();
        _dartFibTime = stopwatch.elapsedMicroseconds / 50.0;

        // Get basic batch timing
        stopwatch.reset();
        stopwatch.start();
        final batchBuffer = List<int>.filled(_fibonacciN * _batchSize, 0);
        for (int i = 0; i < 3; i++) {
          await NativeLibraryProvider.fiboBatch(
            _fibonacciN,
            _batchSize,
            batchBuffer,
          );
        }
        stopwatch.stop();
        _ffiBatchTime = stopwatch.elapsedMicroseconds / 3.0;
      } else if (_selectedAlgorithm == 'factorial') {
        // Get basic FFI timing for Factorial
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < 5; i++) {
          await NativeLibraryProvider.factorial(_factorialN);
        }
        stopwatch.stop();
        _ffiFactTime = stopwatch.elapsedMicroseconds / 5.0;

        // Get basic Dart timing for Factorial
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < 50; i++) {
          factorialDart(_factorialN);
        }
        stopwatch.stop();
        _dartFactTime = stopwatch.elapsedMicroseconds / 50.0;

        // Get basic batch timing (using fiboBatch with factorial n)
        stopwatch.reset();
        stopwatch.start();
        final batchBuffer = List<int>.filled(_factorialN * _batchSize, 0);
        for (int i = 0; i < 3; i++) {
          await NativeLibraryProvider.fiboBatch(
            _factorialN,
            _batchSize,
            batchBuffer,
          );
        }
        stopwatch.stop();
        _ffiBatchTime = stopwatch.elapsedMicroseconds / 3.0;
      } else if (_selectedAlgorithm == 'matrix') {
        // Get basic FFI timing for Matrix multiplication
        final A = List<double>.generate(_matrixM * _matrixK, (_) => 1.0);
        final B = List<double>.generate(_matrixK * _matrixN, (_) => 1.0);

        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < 5; i++) {
          await NativeLibraryProvider.matrixMultiply(
            _matrixM,
            _matrixK,
            _matrixN,
            A,
            B,
          );
        }
        stopwatch.stop();
        _ffiMatrixTime = stopwatch.elapsedMicroseconds / 5.0;

        // Get basic Dart timing for Matrix multiplication
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < 50; i++) {
          matrixMultiplyDart(_matrixM, _matrixK, _matrixN, A, B);
        }
        stopwatch.stop();
        _dartMatrixTime = stopwatch.elapsedMicroseconds / 50.0;
      } else if (_selectedAlgorithm == 'montecarlo') {
        // Get basic FFI timing for Monte Carlo Pi
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < 5; i++) {
          await NativeLibraryProvider.monteCarloPi(_monteCarloSamples);
        }
        stopwatch.stop();
        _ffiMonteCarloTime = stopwatch.elapsedMicroseconds / 5.0;

        // Get basic Dart timing for Monte Carlo Pi
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < 50; i++) {
          monteCarloPiDart(_monteCarloSamples);
        }
        stopwatch.stop();
        _dartMonteCarloTime = stopwatch.elapsedMicroseconds / 50.0;
      }

      // Update display with quick results
      _updateDisplayResults();

      debugPrint(
        'Quick initialization benchmark completed for $_selectedAlgorithm: FFI=${_ffiFibTime.toStringAsFixed(1)}μs, Dart=${_dartFibTime.toStringAsFixed(1)}μs',
      );
    } catch (e) {
      debugPrint('Quick initialization benchmark failed: $e');
      // Continue anyway - real-time monitoring can work with default values
    }
  }

  void _onAlgorithmChanged(String? newAlgorithm) {
    if (newAlgorithm == null || newAlgorithm == _selectedAlgorithm) return;

    // Stop and clear real-time monitoring
    _stopRealTimeMonitoring();
    _resetRealTimeMonitoring();

    // Update selected algorithm
    setState(() => _selectedAlgorithm = newAlgorithm);

    // Run quick benchmark for the new algorithm
    _runQuickInitializationBenchmark();
  }

  Future<void> _runBenchmarks() async {
    setState(() {
      _fibonacciResult = 'Running...';
      _factorialResult = 'Running...';
      _batchResult = 'Running...';
      _monteCarloResult = 'Running...';
      _performanceResult = 'Running...';
      _ffiFibTime = 0;
      _dartFibTime = 0;
      _ffiFactTime = 0;
      _dartFactTime = 0;
      _ffiIsolateFibTime = 0;
      _ffiIsolateFactTime = 0;
    });

    // Run benchmarks asynchronously to avoid blocking UI
    // Use compute to run benchmarks in background isolate
    await compute(_runBenchmarksInIsolate, {
          'selectedAlgorithm': _selectedAlgorithm,
          'fibonacciN': _fibonacciN,
          'factorialN': _factorialN,
          'batchSize': _batchSize,
          'monteCarloSamples': _monteCarloSamples,
          'matrixM': _matrixM,
          'matrixK': _matrixK,
          'matrixN': _matrixN,
        })
        .then((results) {
          setState(() {
            // Reset all timing data first
            _ffiFibTime = 0;
            _dartFibTime = 0;
            _ffiFactTime = 0;
            _dartFactTime = 0;
            _ffiBatchTime = 0;
            _ffiMatrixTime = 0;
            _dartMatrixTime = 0;

            // Update only the results for the selected algorithm
            if (_selectedAlgorithm == 'fibonacci') {
              _ffiFibTime = results['ffiFibTime'] ?? 0.0;
              _dartFibTime = results['dartFibTime'] ?? 0.0;
              _ffiBatchTime = results['ffiBatchTime'] ?? 0.0;
            } else if (_selectedAlgorithm == 'factorial') {
              _ffiFactTime = results['ffiFactTime'] ?? 0.0;
              _dartFactTime = results['dartFactTime'] ?? 0.0;
              _ffiBatchTime = results['ffiBatchTime'] ?? 0.0;
            } else if (_selectedAlgorithm == 'matrix') {
              _ffiMatrixTime = results['ffiMatrixTime'] ?? 0.0;
              _dartMatrixTime = results['dartMatrixTime'] ?? 0.0;
            } else if (_selectedAlgorithm == 'montecarlo') {
              // Monte Carlo doesn't have batch operations in the same way
              _ffiMonteCarloTime = results['ffiMonteCarloTime'] ?? 0.0;
              _dartMonteCarloTime = results['dartMonteCarloTime'] ?? 0.0;
            }

            // Update display results
            _updateDisplayResults();
          });
        })
        .catchError((error) {
          setState(() {
            _fibonacciResult = 'Error: $error';
            _factorialResult = 'Error: $error';
            _batchResult = 'Error: $error';
            _performanceResult = 'Error: $error';
          });
        });
  }

  static Future<Map<String, double>> _runBenchmarksInIsolate(
    Map<String, dynamic> params,
  ) async {
    // Extract parameters
    final selectedAlgorithm = params['selectedAlgorithm'] as String;
    final fibonacciN = params['fibonacciN'] as int;
    final factorialN = params['factorialN'] as int;
    final batchSize = params['batchSize'] as int;
    final monteCarloSamples = params['monteCarloSamples'] as int;
    final matrixM = params['matrixM'] as int;
    final matrixK = params['matrixK'] as int;
    final matrixN = params['matrixN'] as int;

    // Initialize results map
    final results = <String, double>{};

    try {
      // Test if native library is available
      await NativeLibraryProvider.fibo(5);

      final stopwatch = Stopwatch();
      final random = Random(42);

      // Only benchmark the selected algorithm
      if (selectedAlgorithm == 'fibonacci') {
        // Benchmark Fibonacci
        const int iterations = 50;
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < iterations; i++) {
          await NativeLibraryProvider.fibo(fibonacciN);
        }
        stopwatch.stop();
        results['ffiFibTime'] = stopwatch.elapsedMicroseconds / iterations;

        // Benchmark Dart Fibonacci
        const int dartIterations = 5000;
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < dartIterations; i++) {
          fiboDart(fibonacciN);
        }
        stopwatch.stop();
        results['dartFibTime'] = stopwatch.elapsedMicroseconds / dartIterations;

        // Benchmark Batch Fibonacci
        stopwatch.reset();
        stopwatch.start();
        final batchBuffer = List<int>.filled(fibonacciN * batchSize, 0);
        for (int i = 0; i < iterations; i++) {
          await NativeLibraryProvider.fiboBatch(
            fibonacciN,
            batchSize,
            batchBuffer,
          );
        }
        stopwatch.stop();
        results['ffiBatchTime'] = stopwatch.elapsedMicroseconds / iterations;
      } else if (selectedAlgorithm == 'factorial') {
        // Benchmark Factorial
        const int iterations = 50;
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < iterations; i++) {
          await NativeLibraryProvider.factorial(factorialN);
        }
        stopwatch.stop();
        results['ffiFactTime'] = stopwatch.elapsedMicroseconds / iterations;

        // Benchmark Dart Factorial
        const int dartIterations = 5000;
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < dartIterations; i++) {
          factorialDart(factorialN);
        }
        stopwatch.stop();
        results['dartFactTime'] =
            stopwatch.elapsedMicroseconds / dartIterations;

        // Benchmark Batch Factorial (using fiboBatch with factorial n)
        stopwatch.reset();
        stopwatch.start();
        final batchBuffer = List<int>.filled(factorialN * batchSize, 0);
        for (int i = 0; i < iterations; i++) {
          await NativeLibraryProvider.fiboBatch(
            factorialN,
            batchSize,
            batchBuffer,
          );
        }
        stopwatch.stop();
        results['ffiBatchTime'] = stopwatch.elapsedMicroseconds / iterations;
      } else if (selectedAlgorithm == 'matrix') {
        // Benchmark Matrix Multiplication
        final A = List<double>.generate(
          matrixM * matrixK,
          (_) => random.nextDouble(),
        );
        final B = List<double>.generate(
          matrixK * matrixN,
          (_) => random.nextDouble(),
        );

        const int iterations = 50;
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < iterations; i++) {
          await NativeLibraryProvider.matrixMultiply(
            matrixM,
            matrixK,
            matrixN,
            A,
            B,
          );
        }
        stopwatch.stop();
        results['ffiMatrixTime'] = stopwatch.elapsedMicroseconds / iterations;

        // Benchmark Dart Matrix Multiplication
        const int dartIterations = 5000;
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < dartIterations; i++) {
          matrixMultiplyDart(matrixM, matrixK, matrixN, A, B);
        }
        stopwatch.stop();
        results['dartMatrixTime'] =
            stopwatch.elapsedMicroseconds / dartIterations;

        // Benchmark Matrix Batch
        stopwatch.reset();
        stopwatch.start();
        final matrixBatchBuffer = List<double>.filled(
          iterations * matrixM * matrixN,
          0.0,
        );
        for (int i = 0; i < iterations; i++) {
          await NativeLibraryProvider.matrixMultiplyBatch(
            matrixM,
            matrixK,
            matrixN,
            A,
            B,
            iterations,
            matrixBatchBuffer,
          );
        }
        stopwatch.stop();
        results['ffiMatrixBatchTime'] =
            stopwatch.elapsedMicroseconds / iterations;
      } else if (selectedAlgorithm == 'montecarlo') {
        // Benchmark Monte Carlo Pi
        const int iterations = 50;
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < iterations; i++) {
          await NativeLibraryProvider.monteCarloPi(monteCarloSamples);
        }
        stopwatch.stop();
        results['ffiMonteCarloTime'] =
            stopwatch.elapsedMicroseconds / iterations;

        // Benchmark Dart Monte Carlo Pi
        const int dartIterations = 5000;
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < dartIterations; i++) {
          monteCarloPiDart(monteCarloSamples);
        }
        stopwatch.stop();
        results['dartMonteCarloTime'] =
            stopwatch.elapsedMicroseconds / dartIterations;
      }
    } catch (e) {
      // Return empty results on error
      results['ffiFibTime'] = 0;
      results['dartFibTime'] = 0;
      results['ffiFactTime'] = 0;
      results['dartFactTime'] = 0;
      results['ffiBatchTime'] = 0;
      results['ffiMatrixTime'] = 0;
      results['dartMatrixTime'] = 0;
      results['ffiMatrixBatchTime'] = 0;
      results['ffiMonteCarloTime'] = 0;
      results['dartMonteCarloTime'] = 0;
    }

    return results;
  }

  void _updateDisplayResults() {
    // Update display strings with benchmark results based on selected algorithm
    if (_selectedAlgorithm == 'fibonacci') {
      _fibonacciResult =
          '🔵 FFI (Direct): Loading... (${_ffiFibTime.toStringAsFixed(1)} μs)\n'
          '🟠 Dart: Loading... (${_dartFibTime.toStringAsFixed(1)} μs)\n'
          '🏆 Winner: ${(_dartFibTime > _ffiFibTime && _ffiFibTime > 0) ? '🔵 FFI ${(_dartFibTime / _ffiFibTime).toStringAsFixed(1)}x faster' : '🟠 Dart ${(_ffiFibTime / _dartFibTime).toStringAsFixed(1)}x faster'}';
      _factorialResult = 'Not selected - Choose Factorial to benchmark';
      _batchResult = 'Not selected - Choose Factorial to benchmark';
      _monteCarloResult = 'Not selected - Choose Monte Carlo Pi to benchmark';
    } else if (_selectedAlgorithm == 'factorial') {
      _fibonacciResult = 'Not selected - Choose Fibonacci to benchmark';
      _factorialResult =
          '🔵 FFI (Direct): Loading... (${_ffiFactTime.toStringAsFixed(1)} μs)\n'
          '🟠 Dart: Loading... (${_dartFactTime.toStringAsFixed(1)} μs)\n'
          '🏆 Winner: ${(_dartFactTime > _ffiFactTime && _ffiFactTime > 0) ? '🔵 FFI ${(_dartFactTime / _ffiFactTime).toStringAsFixed(1)}x faster' : '🟠 Dart ${(_ffiFactTime / _dartFactTime).toStringAsFixed(1)}x faster'}';
      _batchResult = 'Not selected - Choose Factorial to benchmark';
      _monteCarloResult = 'Not selected - Choose Monte Carlo Pi to benchmark';
    } else if (_selectedAlgorithm == 'matrix') {
      _fibonacciResult = 'Not selected - Choose Fibonacci to benchmark';
      _factorialResult = 'Not selected - Choose Factorial to benchmark';
      _batchResult = 'Not selected - Choose Factorial to benchmark';
      _monteCarloResult =
          '🔵 FFI (C): Loading... (${_ffiMatrixTime.toStringAsFixed(1)} μs)\n'
          '🟠 Dart: Loading... (${_dartMatrixTime.toStringAsFixed(1)} μs)\n'
          '🏆 Winner: ${(_dartMatrixTime > _ffiMatrixTime && _ffiMatrixTime > 0) ? '🔵 FFI ${(_dartMatrixTime / _ffiMatrixTime).toStringAsFixed(1)}x faster' : '🟠 Dart ${(_ffiMatrixTime / _dartMatrixTime).toStringAsFixed(1)}x faster'}\n'
          'Matrix Size: $_matrixM×$_matrixK × $_matrixK×$_matrixN';
    } else if (_selectedAlgorithm == 'montecarlo') {
      _fibonacciResult = 'Not selected - Choose Fibonacci to benchmark';
      _factorialResult = 'Not selected - Choose Factorial to benchmark';
      _batchResult = 'Not selected - Choose Factorial to benchmark';
      _monteCarloResult =
          '🔵 FFI (C): Loading... (${_ffiMonteCarloTime.toStringAsFixed(1)} μs)\n'
          '🟠 Dart: Loading... (${_dartMonteCarloTime.toStringAsFixed(1)} μs)\n'
          '🏆 Winner: ${(_dartMonteCarloTime > _ffiMonteCarloTime && _ffiMonteCarloTime > 0) ? '🔵 FFI ${(_dartMonteCarloTime / _ffiMonteCarloTime).toStringAsFixed(1)}x faster' : '🟠 Dart ${(_ffiMonteCarloTime / _dartMonteCarloTime).toStringAsFixed(1)}x faster'}\n'
          'Samples: $_monteCarloSamples, π ≈ 3.1415926535';
    }

    _performanceResult =
        '🏆 Performance Comparison for ${_getAlgorithmDisplayName(_selectedAlgorithm)}:\n'
        '${_selectedAlgorithm == 'fibonacci' ? '• Fibonacci: ${(_dartFibTime > _ffiFibTime && _ffiFibTime > 0) ? '🔵 FFI ${(_dartFibTime / _ffiFibTime).toStringAsFixed(1)}x faster' : '🟠 Dart ${(_ffiFibTime / _dartFibTime).toStringAsFixed(1)}x faster'}' : ''}'
        '${_selectedAlgorithm == 'factorial' ? '• Factorial: ${(_dartFactTime > _ffiFactTime && _ffiFactTime > 0) ? '🔵 FFI ${(_dartFactTime / _ffiFactTime).toStringAsFixed(1)}x faster' : '🟠 Dart ${(_ffiFactTime / _dartFactTime).toStringAsFixed(1)}x faster'}' : ''}'
        '${_selectedAlgorithm == 'matrix' ? '• Matrix Multiply: ${(_dartMatrixTime > _ffiMatrixTime && _ffiMatrixTime > 0) ? '🔵 FFI ${(_dartMatrixTime / _ffiMatrixTime).toStringAsFixed(1)}x faster' : '🟠 Dart ${(_ffiMatrixTime / _dartMatrixTime).toStringAsFixed(1)}x faster'} ($_matrixM×$_matrixK × $_matrixK×$_matrixN)' : ''}'
        '${_selectedAlgorithm == 'montecarlo' ? '• Monte Carlo Pi: ${(_dartMonteCarloTime > _ffiMonteCarloTime && _ffiMonteCarloTime > 0) ? '🔵 FFI ${(_dartMonteCarloTime / _ffiMonteCarloTime).toStringAsFixed(1)}x faster' : '🟠 Dart ${(_ffiMonteCarloTime / _dartMonteCarloTime).toStringAsFixed(1)}x faster'} ($_monteCarloSamples samples)' : ''}';
  }

  String _getAlgorithmDisplayName(String algorithm) {
    switch (algorithm) {
      case 'fibonacci':
        return '🐰 Fibonacci Sequence';
      case 'factorial':
        return '🔢 Factorial Calculation';
      case 'matrix':
        return '📊 Matrix Multiplication';
      case 'montecarlo':
        return '🎯 Monte Carlo Pi';
      default:
        return 'Unknown Algorithm';
    }
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Asset Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Code Assets Demo'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _nativeAvailable ? Icons.check_circle : Icons.error,
                        color: _nativeAvailable ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _nativeAvailable
                            ? '✅ Native Library Loaded Successfully'
                            : '❌ Native Library Not Available',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Algorithm Selection Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.select_all, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            '🎯 Algorithm Selection',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Choose which algorithm to benchmark:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          RadioMenuButton<String>(
                            value: 'fibonacci',
                            groupValue: _selectedAlgorithm,
                            onChanged: _onAlgorithmChanged,
                            child: const Text('🐰 Fibonacci'),
                          ),
                          RadioMenuButton<String>(
                            value: 'factorial',
                            groupValue: _selectedAlgorithm,
                            onChanged: _onAlgorithmChanged,
                            child: const Text('🔢 Factorial'),
                          ),
                          RadioMenuButton<String>(
                            value: 'matrix',
                            groupValue: _selectedAlgorithm,
                            onChanged: _onAlgorithmChanged,
                            child: const Text('📊 Matrix Multiply'),
                          ),
                          RadioMenuButton<String>(
                            value: 'montecarlo',
                            groupValue: _selectedAlgorithm,
                            onChanged: _onAlgorithmChanged,
                            child: const Text('🎯 Monte Carlo Pi'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Selected: ${_getAlgorithmDisplayName(_selectedAlgorithm)} - This will benchmark only the selected algorithm and show focused performance charts.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Configuration Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.settings, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            '⚙️ Benchmark Configuration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Fibonacci n:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: _fibonacciN.toString(),
                                      ),
                                      onChanged: (value) {
                                        final newValue = int.tryParse(value);
                                        if (newValue != null &&
                                            newValue > 0 &&
                                            newValue <= 50) {
                                          setState(
                                            () => _fibonacciN = newValue,
                                          );
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: '10',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Factorial n:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: _factorialN.toString(),
                                      ),
                                      onChanged: (value) {
                                        final newValue = int.tryParse(value);
                                        if (newValue != null &&
                                            newValue >= 0 &&
                                            newValue <= 20) {
                                          setState(
                                            () => _factorialN = newValue,
                                          );
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: '8',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Batch Size:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: _batchSize.toString(),
                                      ),
                                      onChanged: (value) {
                                        final newValue = int.tryParse(value);
                                        if (newValue != null &&
                                            newValue > 0 &&
                                            newValue <= 50) {
                                          setState(() => _batchSize = newValue);
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: '20',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Monte Carlo Samples:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: _monteCarloSamples.toString(),
                                      ),
                                      onChanged: (value) {
                                        final newValue = int.tryParse(value);
                                        if (newValue != null &&
                                            newValue > 0 &&
                                            newValue <= 10000000) {
                                          setState(
                                            () => _monteCarloSamples = newValue,
                                          );
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: '100000',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Matrix M (rows):',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: _matrixM.toString(),
                                      ),
                                      onChanged: (value) {
                                        final newValue = int.tryParse(value);
                                        if (newValue != null &&
                                            newValue > 0 &&
                                            newValue <= 100) {
                                          setState(() => _matrixM = newValue);
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: '20',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Matrix K (inner):',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: _matrixK.toString(),
                                      ),
                                      onChanged: (value) {
                                        final newValue = int.tryParse(value);
                                        if (newValue != null &&
                                            newValue > 0 &&
                                            newValue <= 100) {
                                          setState(() => _matrixK = newValue);
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: '40',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Matrix N (cols):',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: _matrixN.toString(),
                                      ),
                                      onChanged: (value) {
                                        final newValue = int.tryParse(value);
                                        if (newValue != null &&
                                            newValue > 0 &&
                                            newValue <= 100) {
                                          setState(() => _matrixN = newValue);
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: '50',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Configure parameters and run benchmarks to see results',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Performance Comparison Section (moved to top)
              _buildResultCard(
                '⚡ Performance Comparison',
                _performanceResult,
                Icons.speed,
              ),

              const SizedBox(height: 16),

              // Run Benchmarks Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: _nativeAvailable ? _runBenchmarks : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('🚀 Run Benchmarks'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Fibonacci Section
              _buildResultCard(
                '🐰 Fibonacci Sequence (n=$_fibonacciN)',
                _fibonacciResult,
                Icons.functions,
              ),

              const SizedBox(height: 16),

              // Factorial Section
              _buildResultCard(
                '🔢 Factorial Calculation (n=$_factorialN)',
                _factorialResult,
                Icons.calculate,
              ),

              const SizedBox(height: 16),

              // Batch Operations Section
              _buildResultCard(
                '📊 Batch Fibonacci (n=$_factorialN, $_batchSize operations)',
                _batchResult,
                Icons.batch_prediction,
              ),

              const SizedBox(height: 16),

              // Monte Carlo Pi Section
              _buildResultCard(
                '🎯 Monte Carlo Pi (samples=$_monteCarloSamples)',
                _monteCarloResult,
                Icons.pie_chart,
              ),

              const SizedBox(height: 16),

              // Performance Chart Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bar_chart, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            '📈 Performance Visualization',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: _nativeAvailable && _hasValidTimingData()
                            ? _buildPerformanceChart()
                            : const Center(
                                child: Text(
                                  'Run benchmarks to see performance chart',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Lower bars = Better performance (fewer microseconds)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Batch vs Single Operations Chart
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.compare_arrows, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            '⚡ Batch vs Single Operations',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: _nativeAvailable && _hasValidTimingData()
                            ? _buildBatchVsSingleChart()
                            : const Center(
                                child: Text(
                                  'Run benchmarks to see batch vs single comparison',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Batch operations can be more efficient for multiple calculations',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Isolate vs Direct Operations Chart
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.call_split, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            '🔄 Isolate vs Direct Operations',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child:
                            _nativeAvailable &&
                                _ffiIsolateFibTime > 0 &&
                                _ffiFibTime > 0
                            ? _buildIsolateVsDirectChart()
                            : const Center(
                                child: Text(
                                  'Run benchmarks to see isolate vs direct comparison',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Isolates add overhead but enable concurrent processing',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Real-time Performance Chart
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.show_chart, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            '📊 Real-time Performance Monitoring',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Control Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _nativeAvailable
                                ? _toggleRealTimeMonitoring
                                : null,
                            icon: Icon(
                              _isMonitoringActive
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            label: Text(
                              _isMonitoringActive ? '⏸️ Pause' : '▶️ Start',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isMonitoringActive
                                  ? Colors.orange
                                  : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _resetRealTimeMonitoring,
                            icon: const Icon(Icons.refresh),
                            label: const Text('🔄 Reset'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ffiSinglePoints.isNotEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 12),
                                Text(
                                  'Time: ${(_chartTime * 1000).toStringAsFixed(0)} ms',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // FFI Operations Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2196F3)
                                            .withValues(
                                              alpha: 0.1,
                                            ), // Bright Blue background
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFF2196F3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        '🔵 FFI Single: ${_ffiSinglePoints.last.y.toStringAsFixed(1)} μs',
                                        style: const TextStyle(
                                          color: Color(
                                            0xFF2196F3,
                                          ), // Bright Blue text
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF009688)
                                            .withValues(
                                              alpha: 0.1,
                                            ), // Teal background
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFF009688),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        '🟢 FFI Batch: ${_ffiBatchPoints.last.y.toStringAsFixed(1)} μs',
                                        style: const TextStyle(
                                          color: Color(0xFF009688), // Teal text
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Dart Operations Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF9800)
                                            .withValues(
                                              alpha: 0.1,
                                            ), // Orange background
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFFF9800),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        '🟠 Dart Single: ${_dartSinglePoints.last.y.toStringAsFixed(1)} μs',
                                        style: const TextStyle(
                                          color: Color(
                                            0xFFFF9800,
                                          ), // Orange text
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF5722)
                                            .withValues(
                                              alpha: 0.1,
                                            ), // Deep Orange background
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFFF5722),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        '🔴 Dart Batch: ${_dartBatchPoints.last.y.toStringAsFixed(1)} μs',
                                        style: const TextStyle(
                                          color: Color(
                                            0xFFFF5722,
                                          ), // Deep Orange text
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Performance Winner Section - Single vs Batch Operations
                                Builder(
                                  builder: (context) {
                                    // Single Operations Winner
                                    final singleValues = [
                                      _ffiSinglePoints.last.y,
                                      _dartSinglePoints.last.y,
                                    ];
                                    final singleMin = singleValues.reduce(
                                      (a, b) => a < b ? a : b,
                                    );
                                    final singleMax = singleValues.reduce(
                                      (a, b) => a > b ? a : b,
                                    );

                                    String singleWinnerText;
                                    String singleWinnerEmoji;
                                    Color singleWinnerColor;

                                    if (singleMin == _ffiSinglePoints.last.y) {
                                      singleWinnerText =
                                          '🏆 Single: FFI wins (${singleMin.toStringAsFixed(1)} μs)';
                                      singleWinnerEmoji = '🔵';
                                      singleWinnerColor = const Color(
                                        0xFF2196F3,
                                      );
                                    } else {
                                      singleWinnerText =
                                          '🏆 Single: Dart wins (${singleMin.toStringAsFixed(1)} μs)';
                                      singleWinnerEmoji = '🟠';
                                      singleWinnerColor = const Color(
                                        0xFFFF9800,
                                      );
                                    }

                                    final singleGap = singleMax / singleMin;

                                    // Batch Operations Winner
                                    final batchValues = [
                                      _ffiBatchPoints.last.y,
                                      _dartBatchPoints.last.y,
                                    ];
                                    final batchMin = batchValues.reduce(
                                      (a, b) => a < b ? a : b,
                                    );
                                    final batchMax = batchValues.reduce(
                                      (a, b) => a > b ? a : b,
                                    );

                                    String batchWinnerText;
                                    String batchWinnerEmoji;
                                    Color batchWinnerColor;

                                    if (batchMin == _ffiBatchPoints.last.y) {
                                      batchWinnerText =
                                          '🏆 Batch: FFI wins (${batchMin.toStringAsFixed(1)} μs)';
                                      batchWinnerEmoji = '🟢';
                                      batchWinnerColor = const Color(
                                        0xFF009688,
                                      );
                                    } else {
                                      batchWinnerText =
                                          '🏆 Batch: Dart wins (${batchMin.toStringAsFixed(1)} μs)';
                                      batchWinnerEmoji = '🔴';
                                      batchWinnerColor = const Color(
                                        0xFFFF5722,
                                      );
                                    }

                                    final batchGap = batchMax / batchMin;

                                    return Column(
                                      children: [
                                        // Single Operations Winner
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          margin: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: singleWinnerColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: singleWinnerColor,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                singleWinnerText,
                                                style: TextStyle(
                                                  color: singleWinnerColor,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$singleWinnerEmoji ${singleGap.toStringAsFixed(1)}x faster than opponent',
                                                style: TextStyle(
                                                  color: singleWinnerColor
                                                      .withValues(alpha: 0.8),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Batch Operations Winner
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: batchWinnerColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: batchWinnerColor,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                batchWinnerText,
                                                style: TextStyle(
                                                  color: batchWinnerColor,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$batchWinnerEmoji ${batchGap.toStringAsFixed(1)}x faster than opponent',
                                                style: TextStyle(
                                                  color: batchWinnerColor
                                                      .withValues(alpha: 0.8),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                AspectRatio(
                                  aspectRatio: 1.5,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 24.0,
                                    ),
                                    child: LineChart(
                                      LineChartData(
                                        minY: 0,
                                        maxY: _getMaxYValue(),
                                        minX: _ffiSinglePoints.first.x,
                                        maxX: _ffiSinglePoints.last.x,
                                        lineTouchData: LineTouchData(
                                          enabled: true,
                                          touchTooltipData: LineTouchTooltipData(
                                            getTooltipItems: (touchedSpots) {
                                              return touchedSpots.map((
                                                touchedSpot,
                                              ) {
                                                final lineIndex =
                                                    touchedSpot.barIndex;
                                                final value = touchedSpot.y;
                                                final time = touchedSpot.x;

                                                String lineName;
                                                switch (lineIndex) {
                                                  case 0:
                                                    lineName = 'FFI Single';
                                                    break;
                                                  case 1:
                                                    lineName = 'FFI Batch';
                                                    break;
                                                  case 2:
                                                    lineName = 'Dart Single';
                                                    break;
                                                  case 3:
                                                    lineName = 'Dart Batch';
                                                    break;
                                                  default:
                                                    lineName = 'Unknown';
                                                }

                                                return LineTooltipItem(
                                                  '$lineName\n${value.toStringAsFixed(1)} μs\nTime: ${(time * 1000).toStringAsFixed(0)} ms',
                                                  const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                );
                                              }).toList();
                                            },
                                          ),
                                        ),
                                        clipData: const FlClipData.all(),
                                        gridData: const FlGridData(
                                          show: true,
                                          drawVerticalLine: false,
                                        ),
                                        borderData: FlBorderData(show: false),
                                        lineBarsData: [
                                          _ffiSingleLine(_ffiSinglePoints),
                                          _ffiBatchLine(_ffiBatchPoints),
                                          _dartSingleLine(_dartSinglePoints),
                                          _dartBatchLine(_dartBatchPoints),
                                        ],
                                        titlesData: const FlTitlesData(
                                          show: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Center(
                              child: Text(
                                'Click "▶️ Start" to begin real-time monitoring',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                      const SizedBox(height: 8),
                      Text(
                        _isMonitoringActive
                            ? '🟢 Monitoring Active - Tracking performance in real-time'
                            : '🔴 Monitoring Paused - Click Start to resume',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isMonitoringActive
                              ? Colors.green
                              : Colors.red,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Info Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ℹ️ About This Demo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This app demonstrates the use of native C code compiled with Dart\'s '
                        'build hooks system. It compares performance between Dart implementations '
                        'and native FFI calls for mathematical computations.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Key Features:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Automatic native library compilation\n'
                        '• Cross-platform C code integration\n'
                        '• Real-time performance comparison\n'
                        '• Batch operation processing\n'
                        '• Isolate-based concurrent execution\n'
                        '• Monte Carlo Pi approximation',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    // Get timing data based on selected algorithm
    double ffiTime = 0.0;
    double dartTime = 0.0;
    String algorithmName = '';
    String algorithmDisplayName = '';

    switch (_selectedAlgorithm) {
      case 'fibonacci':
        ffiTime = _ffiFibTime;
        dartTime = _dartFibTime;
        algorithmName = 'Fibonacci';
        algorithmDisplayName = '🐰 Fibonacci';
        break;
      case 'factorial':
        ffiTime = _ffiFactTime;
        dartTime = _dartFactTime;
        algorithmName = 'Factorial';
        algorithmDisplayName = '🔢 Factorial';
        break;
      case 'matrix':
        ffiTime = _ffiMatrixTime;
        dartTime = _dartMatrixTime;
        algorithmName = 'Matrix Multiplication';
        algorithmDisplayName = '📊 Matrix Multiply';
        break;
      case 'montecarlo':
        ffiTime = _ffiMonteCarloTime;
        dartTime = _dartMonteCarloTime;
        algorithmName = 'Monte Carlo Pi';
        algorithmDisplayName = '🎯 Monte Carlo Pi';
        break;
      default:
        return const Center(
          child: Text(
            'Unknown algorithm selected',
            style: TextStyle(color: Colors.grey),
          ),
        );
    }

    // Check if we have valid timing data
    if (ffiTime <= 0 || dartTime <= 0) {
      return const Center(
        child: Text(
          'Run benchmarks to see performance chart',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final timings = [ffiTime, dartTime];
    final validTimings = timings.where((t) => t > 0).toList();

    if (validTimings.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for benchmark data...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final maxTiming = validTimings.reduce((a, b) => a > b ? a : b);
    // Limit the maximum Y value to prevent bars from growing too large and overflowing
    final chartMaxY = maxTiming > 1000
        ? 1000.0
        : max(
            maxTiming * 1.2,
            2.0,
          ); // Cap at 1000μs, otherwise add 20% padding, ensure minimum of 2.0

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMaxY > 0 ? chartMaxY : 10.0, // Ensure minimum maxY
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final implementation = groupIndex == 0 ? 'FFI (C)' : 'Dart';
              final time = groupIndex == 0 ? ffiTime : dartTime;
              return BarTooltipItem(
                '$implementation - $algorithmName\n${time.toStringAsFixed(1)} μs',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return Text(
                      '🔵 FFI (C)\n$algorithmDisplayName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10),
                    );
                  case 1:
                    return Text(
                      '🟠 Dart\n$algorithmDisplayName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10),
                    );
                  default:
                    return const Text('');
                }
              },
              reservedSize: 50,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toStringAsFixed(0)}μs');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        barGroups: [
          // FFI Implementation - Bright Blue
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: (ffiTime > 0 ? ffiTime : 0.1).clamp(0.1, chartMaxY),
                color: const Color(0xFF2196F3), // Bright Blue
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          // Dart Implementation - Orange
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: (dartTime > 0 ? dartTime : 0.1).clamp(0.1, chartMaxY),
                color: const Color(0xFFFF9800), // Orange
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBatchVsSingleChart() {
    // Get timing data based on selected algorithm
    double ffiSingleTime = 0.0;
    double ffiBatchTime = 0.0;
    double dartSingleTime = 0.0;
    double dartBatchTime = 0.0;
    String algorithmName = '';
    String algorithmDisplayName = '';

    switch (_selectedAlgorithm) {
      case 'fibonacci':
        ffiSingleTime = _ffiFibTime;
        ffiBatchTime = _ffiBatchTime / _batchSize; // Per operation
        dartSingleTime = _dartFibTime;
        dartBatchTime = _dartFibTime; // Dart batch is same as single for this algorithm
        algorithmName = 'Fibonacci';
        algorithmDisplayName = '🐰 Fibonacci';
        break;
      case 'factorial':
        ffiSingleTime = _ffiFactTime;
        ffiBatchTime = _ffiBatchTime / _batchSize; // Per operation
        dartSingleTime = _dartFactTime;
        dartBatchTime = _dartFactTime; // Dart batch is same as single for this algorithm
        algorithmName = 'Factorial';
        algorithmDisplayName = '🔢 Factorial';
        break;
      case 'matrix':
        ffiSingleTime = _ffiMatrixTime;
        ffiBatchTime = _ffiMatrixTime; // Matrix operations are already per operation
        dartSingleTime = _dartMatrixTime;
        dartBatchTime = _dartMatrixTime; // Matrix operations are already per operation
        algorithmName = 'Matrix Multiplication';
        algorithmDisplayName = '📊 Matrix Multiply';
        break;
      case 'montecarlo':
        ffiSingleTime = _ffiMonteCarloTime;
        ffiBatchTime = _ffiMonteCarloTime;
        dartSingleTime = _dartMonteCarloTime;
        dartBatchTime = _dartMonteCarloTime;
        algorithmName = 'Monte Carlo Pi';
        algorithmDisplayName = '🎯 Monte Carlo Pi';
        break;
      default:
        return const Center(
          child: Text(
            'Unknown algorithm selected',
            style: TextStyle(color: Colors.grey),
          ),
        );
    }

    // Ensure we have valid timing data
    final timings = [ffiSingleTime, ffiBatchTime, dartSingleTime, dartBatchTime];
    final validTimings = timings.where((t) => t > 0).toList();

    if (validTimings.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for benchmark data...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final maxTiming = validTimings.reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxTiming * 1.2; // Add 20% padding

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMaxY > 0 ? chartMaxY : 10.0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final implementation = groupIndex < 2 ? 'FFI (C)' : 'Dart';
              final operationType = groupIndex % 2 == 0 ? 'Single' : 'Batch (per op)';
              final time = groupIndex == 0 ? ffiSingleTime :
                          groupIndex == 1 ? ffiBatchTime :
                          groupIndex == 2 ? dartSingleTime : dartBatchTime;
              return BarTooltipItem(
                '$implementation - $algorithmName $operationType\n${time.toStringAsFixed(1)} μs',
                const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return Text(
                      '🔵 FFI (C)\n$algorithmDisplayName\nSingle',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10),
                    );
                  case 1:
                    return Text(
                      '🟢 FFI (C)\n$algorithmDisplayName\nBatch (per op)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10),
                    );
                  case 2:
                    return Text(
                      '🟠 Dart\n$algorithmDisplayName\nSingle',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10),
                    );
                  case 3:
                    return Text(
                      '🔴 Dart\n$algorithmDisplayName\nBatch (per op)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10),
                    );
                  default:
                    return const Text('');
                }
              },
              reservedSize: 70,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toStringAsFixed(0)}μs');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withValues(alpha: 0.3), strokeWidth: 1);
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: ffiSingleTime > 0 ? ffiSingleTime : 0.1,
                color: const Color(0xFF2196F3), // Bright Blue - FFI Single
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: ffiBatchTime > 0 ? ffiBatchTime : 0.1,
                color: const Color(0xFF009688), // Teal - FFI Batch
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: dartSingleTime > 0 ? dartSingleTime : 0.1,
                color: const Color(0xFFFF9800), // Orange - Dart Single
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [
              BarChartRodData(
                toY: dartBatchTime > 0 ? dartBatchTime : 0.1,
                color: const Color(0xFFFF5722), // Deep Orange - Dart Batch
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIsolateVsDirectChart() {
    // Ensure we have valid timing data for both direct and isolate
    final timings = [
      _ffiFibTime,
      _ffiIsolateFibTime,
      _ffiFactTime,
      _ffiIsolateFactTime,
    ];
    final validTimings = timings.where((t) => t > 0).toList();

    if (validTimings.isEmpty || _ffiIsolateFibTime == 0 || _ffiFibTime == 0) {
      return const Center(
        child: Text(
          'Waiting for benchmark data...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final maxTiming = validTimings.reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxTiming * 1.2; // Add 20% padding

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMaxY > 0 ? chartMaxY : 10.0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final algorithm = groupIndex < 2 ? 'Fibonacci' : 'Factorial';
              final executionMode = rodIndex == 0 ? 'Direct' : 'Isolate';
              final implementation =
                  'FFI (C)'; // This chart is specifically for FFI
              final time = rodIndex == 0
                  ? (groupIndex < 2 ? _ffiFibTime : _ffiFactTime)
                  : (groupIndex < 2 ? _ffiIsolateFibTime : _ffiIsolateFactTime);
              return BarTooltipItem(
                '$implementation - $algorithm $executionMode\n${time.toStringAsFixed(1)} μs',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Text(
                      '🔵 FFI (C)\nFibonacci\nDirect',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11),
                    );
                  case 1:
                    return const Text(
                      '🟣 FFI (C)\nFibonacci\nIsolate',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11),
                    );
                  case 2:
                    return const Text(
                      '🔵 FFI (C)\nFactorial\nDirect',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11),
                    );
                  case 3:
                    return const Text(
                      '🟣 FFI (C)\nFactorial\nIsolate',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11),
                    );
                  default:
                    return const Text('');
                }
              },
              reservedSize: 60,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toStringAsFixed(0)}μs');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: _ffiFibTime > 0 ? _ffiFibTime : 0.1,
                color: Colors.blue,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: _ffiIsolateFibTime > 0 ? _ffiIsolateFibTime : 0.1,
                color: Colors.purple,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: _ffiFactTime > 0 ? _ffiFactTime : 0.1,
                color: Colors.blue,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [
              BarChartRodData(
                toY: _ffiIsolateFactTime > 0 ? _ffiIsolateFactTime : 0.1,
                color: Colors.purple,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String title, String content, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  void _startRealTimeMonitoring() {
    if (_isMonitoringActive) return; // Already monitoring

    _isMonitoringActive = true;
    _performanceTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) {
      if (_ffiSinglePoints.length > _maxDataPoints) {
        _ffiSinglePoints.removeAt(0);
        _ffiBatchPoints.removeAt(0);
        _dartSinglePoints.removeAt(0);
        _dartBatchPoints.removeAt(0);
      }

      // Add new performance data points (simulate real-time data) based on selected algorithm
      if (_nativeAvailable && _hasValidTimingData()) {
        setState(() {
          _chartTime += 0.2; // Increment time by 200ms
          // Add some variation to simulate real performance fluctuations
          final variation = (DateTime.now().microsecond % 100) / 100.0;

          // Get timing data based on selected algorithm
          final timingData = _getCurrentTimingData();
          final ffiSingleTime = timingData['ffiSingle'] ?? 0.0;
          final ffiBatchTime = timingData['ffiBatch'] ?? 0.0;
          final dartSingleTime = timingData['dartSingle'] ?? 0.0;
          final dartBatchTime = timingData['dartBatch'] ?? 0.0;

          // FFI Single operation
          final ffiSingleValue = ffiSingleTime * (0.8 + variation * 0.4);
          // FFI Batch operation (per operation)
          final ffiBatchValue = ffiBatchTime * (0.8 + variation * 0.4);
          // Dart Single operation
          final dartSingleValue = dartSingleTime * (0.8 + variation * 0.4);
          // Dart Batch operation (per operation)
          final dartBatchValue = dartBatchTime * (0.8 + variation * 0.4);

          _ffiSinglePoints.add(FlSpot(_chartTime, ffiSingleValue));
          _ffiBatchPoints.add(FlSpot(_chartTime, ffiBatchValue));
          _dartSinglePoints.add(FlSpot(_chartTime, dartSingleValue));
          _dartBatchPoints.add(FlSpot(_chartTime, dartBatchValue));
        });
      }
    });
  }

  bool _hasValidTimingData() {
    switch (_selectedAlgorithm) {
      case 'fibonacci':
        return _ffiFibTime > 0 && _dartFibTime > 0;
      case 'factorial':
        return _ffiFactTime > 0 && _dartFactTime > 0;
      case 'matrix':
        return _ffiMatrixTime > 0 && _dartMatrixTime > 0;
      case 'montecarlo':
        return _ffiMonteCarloTime > 0 && _dartMonteCarloTime > 0;
      default:
        return false;
    }
  }

  Map<String, double> _getCurrentTimingData() {
    switch (_selectedAlgorithm) {
      case 'fibonacci':
        return {
          'ffiSingle': _ffiFibTime,
          'ffiBatch': _ffiBatchTime / _batchSize, // Per operation
          'dartSingle': _dartFibTime,
          'dartBatch':
              _dartFibTime, // Dart batch is same as single for this algorithm
        };
      case 'factorial':
        return {
          'ffiSingle': _ffiFactTime,
          'ffiBatch': _ffiBatchTime / _batchSize, // Per operation
          'dartSingle': _dartFactTime,
          'dartBatch':
              _dartFactTime, // Dart batch is same as single for this algorithm
        };
      case 'matrix':
        return {
          'ffiSingle': _ffiMatrixTime,
          'ffiBatch':
              _ffiMatrixTime, // Matrix operations are already per operation
          'dartSingle': _dartMatrixTime,
          'dartBatch':
              _dartMatrixTime, // Matrix operations are already per operation
        };
      case 'montecarlo':
        return {
          'ffiSingle': _ffiMonteCarloTime,
          'ffiBatch': _ffiMonteCarloTime,
          'dartSingle': _dartMonteCarloTime,
          'dartBatch': _dartMonteCarloTime,
        };
      default:
        return {
          'ffiSingle': 0.0,
          'ffiBatch': 0.0,
          'dartSingle': 0.0,
          'dartBatch': 0.0,
        };
    }
  }

  void _stopRealTimeMonitoring() {
    _isMonitoringActive = false;
    _performanceTimer?.cancel();
    _performanceTimer = null;
  }

  void _toggleRealTimeMonitoring() {
    if (_isMonitoringActive) {
      _stopRealTimeMonitoring();
    } else {
      _startRealTimeMonitoring();
    }
  }

  void _resetRealTimeMonitoring() {
    _stopRealTimeMonitoring();
    setState(() {
      _ffiSinglePoints.clear();
      _ffiBatchPoints.clear();
      _dartSinglePoints.clear();
      _dartBatchPoints.clear();
      _chartTime = 0;
    });
  }

  double _getMaxYValue() {
    final allPoints = [
      ..._ffiSinglePoints,
      ..._ffiBatchPoints,
      ..._dartSinglePoints,
      ..._dartBatchPoints,
    ];

    if (allPoints.isEmpty) {
      return 10.0;
    }

    final maxY = allPoints
        .map((point) => point.y)
        .reduce((a, b) => a > b ? a : b);
    return maxY * 1.2; // Add 20% padding
  }

  LineChartBarData _ffiSingleLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: const FlDotData(show: false),
      gradient: LinearGradient(
        colors: [
          const Color(0xFF2196F3).withValues(alpha: 0),
          const Color(0xFF2196F3),
        ], // Bright Blue
        stops: const [0.1, 1.0],
      ),
      barWidth: 2,
      isCurved: true,
      curveSmoothness: 0.2,
    );
  }

  LineChartBarData _ffiBatchLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: const FlDotData(show: false),
      gradient: LinearGradient(
        colors: [
          const Color(0xFF009688).withValues(alpha: 0),
          const Color(0xFF009688),
        ], // Teal
        stops: const [0.1, 1.0],
      ),
      barWidth: 2,
      isCurved: true,
      curveSmoothness: 0.2,
    );
  }

  LineChartBarData _dartSingleLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: const FlDotData(show: false),
      gradient: LinearGradient(
        colors: [
          const Color(0xFFFF9800).withValues(alpha: 0),
          const Color(0xFFFF9800),
        ], // Orange
        stops: const [0.1, 1.0],
      ),
      barWidth: 2,
      isCurved: true,
      curveSmoothness: 0.2,
    );
  }

  LineChartBarData _dartBatchLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: const FlDotData(show: false),
      gradient: LinearGradient(
        colors: [
          const Color(0xFFFF5722).withValues(alpha: 0),
          const Color(0xFFFF5722),
        ], // Deep Orange
        stops: const [0.1, 1.0],
      ),
      barWidth: 2,
      isCurved: true,
      curveSmoothness: 0.2,
    );
  }
}

// Dart implementations for comparison
List<int> fiboDart(int n) {
  if (n <= 0) return [];
  if (n == 1) return [0];
  if (n == 2) return [0, 1];

  List<int> result = List.filled(n, 0);
  result[0] = 0;
  result[1] = 1;

  for (int i = 2; i < n; i++) {
    result[i] = result[i - 1] + result[i - 2];
  }

  return result;
}

int factorialDart(int n) {
  if (n < 0) return 0;
  if (n == 0 || n == 1) return 1;

  int result = 1;
  for (int i = 2; i <= n; i++) {
    result *= i;
  }
  return result;
}

// Monte Carlo Pi calculation using Dart's Random class
double monteCarloPiDart(int numSamples) {
  if (numSamples <= 0) return 0.0;

  int pointsInsideCircle = 0;
  final random = Random(12345); // Fixed seed for reproducible results

  for (int i = 0; i < numSamples; i++) {
    double x = random.nextDouble();
    double y = random.nextDouble();

    // Check if point (x,y) is inside the quarter circle (x² + y² ≤ 1)
    if (x * x + y * y <= 1.0) {
      pointsInsideCircle++;
    }
  }

  // Pi approximation: 4 * (points_inside_circle / total_points)
  return 4.0 * pointsInsideCircle / numSamples;
}

// Matrix multiplication using Dart
// A is m x k, B is k x n, C is m x n
List<double> matrixMultiplyDart(
  int m,
  int k,
  int n,
  List<double> A,
  List<double> B,
) {
  if (m <= 0 || k <= 0 || n <= 0 || A.length != m * k || B.length != k * n) {
    return [];
  }

  final C = List<double>.filled(m * n, 0.0);

  // Perform matrix multiplication
  for (int i = 0; i < m; i++) {
    for (int j = 0; j < n; j++) {
      double sum = 0.0;
      for (int p = 0; p < k; p++) {
        sum += A[i * k + p] * B[p * n + j];
      }
      C[i * n + j] = sum;
    }
  }

  return C;
}
