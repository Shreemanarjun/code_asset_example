import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:code_asset_example/add.g.dart';
import 'package:ffi/ffi.dart';

/// Enhanced Native Library Provider with FFI Memory Management
/// Handles all C function calls with proper using((Arena arena) {}) patterns
/// Now supports helper isolate for concurrent native operations
class NativeLibraryProvider {
  static NativeLibrary? _instance;
  static Isolate? _helperIsolate;
  static SendPort? _helperSendPort;
  static ReceivePort? _helperReceivePort;
  static bool _useIsolate = false;

  static NativeLibrary get instance {
    if (_instance == null) {
      print('Creating native library instance...');
      _instance = _createNativeLibrary();
      print('Native library instance created successfully');
    }
    return _instance!;
  }

  static NativeLibrary _createNativeLibrary() {
    // Try multiple possible locations for the native library
    final libraryNames = Platform.isMacOS
        ? ['libnative_add.dylib']
        : Platform.isLinux
        ? ['libnative_add.so']
        : ['native_add.dll'];

    // First try the standard system paths
    for (final libName in libraryNames) {
      try {
        return NativeLibrary(DynamicLibrary.open(libName));
      } catch (e) {
        // Continue to next location
      }
    }

    // Try relative to the current working directory
    final currentDir = Directory.current.path;
    for (final libName in libraryNames) {
      final libPath = '$currentDir/$libName';
      if (File(libPath).existsSync()) {
        try {
          return NativeLibrary(DynamicLibrary.open(libPath));
        } catch (e) {
          // Continue to next location
        }
      }
    }

    // Try in the Flutter example directory (for Flutter apps)
    // Flutter apps run in sandboxed containers, so we need to check the actual project path
    const flutterExamplePath = '/Users/shreemanarjunsahu/personal/hooks/code_asset_example/example';
    for (final libName in libraryNames) {
      final libPath = '$flutterExamplePath/$libName';
      if (File(libPath).existsSync()) {
        try {
          return NativeLibrary(DynamicLibrary.open(libPath));
        } catch (e) {
          // Continue to next location
        }
      }
    }

    // Try in the main package's directory (parent of current)
    final mainPackageDir = Directory.current.parent.path;
    for (final libName in libraryNames) {
      final libPath = '$mainPackageDir/$libName';
      if (File(libPath).existsSync()) {
        try {
          return NativeLibrary(DynamicLibrary.open(libPath));
        } catch (e) {
          // Continue to next location
        }
      }
    }

    // Try in the main package's build output directory
    final mainPackageBuildDir = '$mainPackageDir/.dart_tool/hooks_output/shared';
    if (Directory(mainPackageBuildDir).existsSync()) {
      final subdirs = Directory(mainPackageBuildDir).listSync().whereType<Directory>();
      for (final subdir in subdirs) {
        for (final libName in libraryNames) {
          final libPath = '${subdir.path}/$libName';
          if (File(libPath).existsSync()) {
            try {
              return NativeLibrary(DynamicLibrary.open(libPath));
            } catch (e) {
              // Continue to next location
            }
          }
        }
      }
    }

    // If all else fails, try the original method (will throw if not found)
    final lib = Platform.isMacOS
        ? DynamicLibrary.open('libnative_add.dylib')
        : Platform.isLinux
        ? DynamicLibrary.open('libnative_add.so')
        : DynamicLibrary.open('native_add.dll');
    return NativeLibrary(lib);
  }

  /// Initialize helper isolate for native operations
  static Future<void> initializeIsolate() async {
    if (_helperIsolate != null) return;

    _helperReceivePort = ReceivePort();
    _helperIsolate = await Isolate.spawn(_isolateEntryPoint, _helperReceivePort!.sendPort);

    // Wait for the isolate to be ready
    await for (var message in _helperReceivePort!) {
      if (message is SendPort) {
        _helperSendPort = message;
        break;
      }
    }

    _useIsolate = true;
  }

  /// Check if isolate mode is currently active
  static bool get isIsolateMode => _useIsolate;

  /// Cleanup helper isolate
  static void disposeIsolate() {
    try {
      _helperIsolate?.kill(priority: Isolate.immediate);
      _helperIsolate = null;
      _helperSendPort = null;
      _helperReceivePort?.close();
      _helperReceivePort = null;
      _useIsolate = false;
    } catch (e) {
      // Ignore cleanup errors as the process might be terminating
    }
  }

  /// Helper isolate entry point
  static void _isolateEntryPoint(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    // Create native library instance in the isolate using the same logic
    // Note: This creates a separate instance for the isolate, not affecting the main thread's singleton
    NativeLibrary? nativeLib;
    try {
      nativeLib = _createNativeLibrary();
    } catch (e) {
      // If library can't be loaded in isolate, we'll handle errors gracefully
      nativeLib = null;
    }

    receivePort.listen((message) async {
      if (message is Map<String, dynamic>) {
        final operation = message['operation'];
        final args = message['args'];
        final replyPort = message['replyPort'] as SendPort;

        try {
          if (nativeLib == null) {
            throw StateError('Native library not available in isolate');
          }

          dynamic result;
          switch (operation) {
            case 'fibo':
              result = _isolateFibo(nativeLib, args['n'] as int);
              break;
            case 'fiboBatch':
              result = _isolateFiboBatch(nativeLib, args['n'] as int, args['iterations'] as int);
              break;
            case 'factorial':
              result = nativeLib.factorial(args['n'] as int);
              break;
            case 'factorialBatch':
              result = _isolateFactorialBatch(nativeLib, args['n'] as int, args['iterations'] as int);
              break;
            case 'monteCarloPi':
              result = nativeLib.monte_carlo_pi(args['numSamples'] as int);
              break;
            case 'monteCarloPiBatch':
              result = _isolateMonteCarloPiBatch(nativeLib, args['numSamples'] as int, args['iterations'] as int);
              break;
            case 'matrixMultiply':
              result = _isolateMatrixMultiply(nativeLib, args['m'] as int, args['k'] as int, args['n'] as int, args['A'] as List<double>, args['B'] as List<double>);
              break;
            case 'matrixMultiplyBatch':
              result = _isolateMatrixMultiplyBatch(nativeLib, args['m'] as int, args['k'] as int, args['n'] as int, args['A'] as List<double>, args['B'] as List<double>, args['iterations'] as int);
              break;
            default:
              throw UnsupportedError('Unknown operation: $operation');
          }
          replyPort.send({'success': true, 'result': result});
        } catch (e) {
          replyPort.send({'success': false, 'error': e.toString()});
        }
      }
    });
  }

  /// Isolate implementation of fibo
  static List<int> _isolateFibo(NativeLibrary nativeLib, int n) {
    final result = <int>[];
    final buffer = calloc<Int32>(n);
    try {
      nativeLib.fibo(n, buffer);
      for (int i = 0; i < n; i++) {
        result.add(buffer[i]);
      }
    } finally {
      calloc.free(buffer);
    }
    return result;
  }

  /// Isolate implementation of fiboBatch
  static List<int> _isolateFiboBatch(NativeLibrary nativeLib, int n, int iterations) {
    final result = <int>[];
    final buffer = calloc<Int32>(iterations * n);
    try {
      nativeLib.fibo_batch(n, iterations, buffer);
      for (int i = 0; i < iterations * n; i++) {
        result.add(buffer[i]);
      }
    } finally {
      calloc.free(buffer);
    }
    return result;
  }

  /// Isolate implementation of factorialBatch
  static List<int> _isolateFactorialBatch(NativeLibrary nativeLib, int n, int iterations) {
    final result = <int>[];
    final buffer = calloc<Int64>(iterations);
    try {
      nativeLib.factorial_batch(n, iterations, buffer);
      for (int i = 0; i < iterations; i++) {
        result.add(buffer[i]);
      }
    } finally {
      calloc.free(buffer);
    }
    return result;
  }

  /// Isolate implementation of monteCarloPiBatch
  static List<double> _isolateMonteCarloPiBatch(NativeLibrary nativeLib, int numSamples, int iterations) {
    final result = <double>[];
    final buffer = calloc<Double>(iterations);
    try {
      nativeLib.monte_carlo_pi_batch(numSamples, iterations, buffer);
      for (int i = 0; i < iterations; i++) {
        result.add(buffer[i]);
      }
    } finally {
      calloc.free(buffer);
    }
    return result;
  }

  /// Isolate implementation of matrixMultiply
  static List<double> _isolateMatrixMultiply(NativeLibrary nativeLib, int m, int k, int n, List<double> A, List<double> B) {
    final result = <double>[];
    final aBuffer = calloc<Double>(m * k);
    final bBuffer = calloc<Double>(k * n);
    final cBuffer = calloc<Double>(m * n);

    try {
      // Copy input matrices to native memory
      for (int i = 0; i < m * k; i++) {
        aBuffer[i] = A[i];
      }
      for (int i = 0; i < k * n; i++) {
        bBuffer[i] = B[i];
      }

      nativeLib.matrix_multiply(m, k, n, aBuffer, bBuffer, cBuffer);

      // Copy result back to Dart list
      for (int i = 0; i < m * n; i++) {
        result.add(cBuffer[i]);
      }
    } finally {
      calloc.free(aBuffer);
      calloc.free(bBuffer);
      calloc.free(cBuffer);
    }
    return result;
  }

  /// Isolate implementation of matrixMultiplyBatch
  static List<double> _isolateMatrixMultiplyBatch(NativeLibrary nativeLib, int m, int k, int n, List<double> A, List<double> B, int iterations) {
    final result = <double>[];
    final aBuffer = calloc<Double>(m * k);
    final bBuffer = calloc<Double>(k * n);
    final resultsBuffer = calloc<Double>(iterations * m * n);

    try {
      // Copy input matrices to native memory
      for (int i = 0; i < m * k; i++) {
        aBuffer[i] = A[i];
      }
      for (int i = 0; i < k * n; i++) {
        bBuffer[i] = B[i];
      }

      nativeLib.matrix_multiply_batch(m, k, n, aBuffer, bBuffer, iterations, resultsBuffer);

      // Copy results back to Dart list
      for (int i = 0; i < iterations * m * n; i++) {
        result.add(resultsBuffer[i]);
      }
    } finally {
      calloc.free(aBuffer);
      calloc.free(bBuffer);
      calloc.free(resultsBuffer);
    }
    return result;
  }

  /// Send operation to helper isolate and wait for result
  static Future<T> _sendToIsolate<T>(String operation, Map<String, dynamic> args) async {
    if (!_useIsolate || _helperSendPort == null) {
      throw StateError('Helper isolate not initialized');
    }

    final replyPort = ReceivePort();
    _helperSendPort!.send({
      'operation': operation,
      'args': args,
      'replyPort': replyPort.sendPort,
    });

    final response = await replyPort.first as Map<String, dynamic>;
    replyPort.close();

    if (response['success'] == true) {
      return response['result'] as T;
    } else {
      throw Exception(response['error']);
    }
  }

  /// Fibonacci single operation with memory management
  static Future<List<int>> fibo(int n) async {
    if (_useIsolate) {
      return await _sendToIsolate<List<int>>('fibo', {'n': n});
    }
    return using((Arena arena) {
      final result = arena<Int32>(n);
      instance.fibo(n, result);
      return List<int>.generate(n, (i) => result[i]);
    });
  }

  /// Fibonacci batch operation with memory management
  static Future<void> fiboBatch(int n, int iterations, List<int> results) async {
    if (_useIsolate) {
      final isolateResults = await _sendToIsolate<List<int>>('fiboBatch', {'n': n, 'iterations': iterations});
      for (int i = 0; i < isolateResults.length; i++) {
        results[i] = isolateResults[i];
      }
      return;
    }
    using((Arena arena) {
      final buffer = arena<Int32>(iterations * n);
      instance.fibo_batch(n, iterations, buffer);
      for (int i = 0; i < iterations * n; i++) {
        results[i] = buffer[i];
      }
    });
  }

  /// Factorial single operation with memory management
  static Future<int> factorial(int n) async {
    if (_useIsolate) {
      return await _sendToIsolate<int>('factorial', {'n': n});
    }
    return using((Arena arena) {
      return instance.factorial(n);
    });
  }

  /// Factorial batch operation with memory management
  static Future<void> factorialBatch(int n, int iterations, List<int> results) async {
    if (_useIsolate) {
      final isolateResults = await _sendToIsolate<List<int>>('factorialBatch', {'n': n, 'iterations': iterations});
      for (int i = 0; i < isolateResults.length; i++) {
        results[i] = isolateResults[i];
      }
      return;
    }
    using((Arena arena) {
      final buffer = arena<Int64>(iterations);
      instance.factorial_batch(n, iterations, buffer);
      for (int i = 0; i < iterations; i++) {
        results[i] = buffer[i];
      }
    });
  }

  /// Generic single operation wrapper
  static T singleOperation<T>(T Function() operation) {
    return using((Arena arena) => operation());
  }

  /// Monte Carlo Pi single operation with memory management
  static Future<double> monteCarloPi(int numSamples) async {
    if (_useIsolate) {
      return await _sendToIsolate<double>('monteCarloPi', {'numSamples': numSamples});
    }
    return using((Arena arena) {
      return instance.monte_carlo_pi(numSamples);
    });
  }

  /// Monte Carlo Pi batch operation with memory management
  static Future<void> monteCarloPiBatch(int numSamples, int iterations, List<double> results) async {
    if (_useIsolate) {
      final isolateResults = await _sendToIsolate<List<double>>('monteCarloPiBatch', {'numSamples': numSamples, 'iterations': iterations});
      for (int i = 0; i < isolateResults.length; i++) {
        results[i] = isolateResults[i];
      }
      return;
    }
    using((Arena arena) {
      final buffer = arena<Double>(iterations);
      instance.monte_carlo_pi_batch(numSamples, iterations, buffer);
      for (int i = 0; i < iterations; i++) {
        results[i] = buffer[i];
      }
    });
  }

  /// Matrix multiplication with memory management
  static Future<List<double>> matrixMultiply(int m, int k, int n, List<double> A, List<double> B) async {
    if (_useIsolate) {
      return await _sendToIsolate<List<double>>('matrixMultiply', {'m': m, 'k': k, 'n': n, 'A': A, 'B': B});
    }
    return using((Arena arena) {
      final aBuffer = arena<Double>(m * k);
      final bBuffer = arena<Double>(k * n);
      final cBuffer = arena<Double>(m * n);

      // Copy input matrices to native memory
      for (int i = 0; i < m * k; i++) {
        aBuffer[i] = A[i];
      }
      for (int i = 0; i < k * n; i++) {
        bBuffer[i] = B[i];
      }

      instance.matrix_multiply(m, k, n, aBuffer, bBuffer, cBuffer);

      // Copy result back to Dart list
      return List<double>.generate(m * n, (i) => cBuffer[i]);
    });
  }

  /// Matrix multiplication batch operation with memory management
  static Future<void> matrixMultiplyBatch(int m, int k, int n, List<double> A, List<double> B, int iterations, List<double> results) async {
    if (_useIsolate) {
      final isolateResults = await _sendToIsolate<List<double>>('matrixMultiplyBatch', {'m': m, 'k': k, 'n': n, 'A': A, 'B': B, 'iterations': iterations});
      for (int i = 0; i < isolateResults.length; i++) {
        results[i] = isolateResults[i];
      }
      return;
    }
    using((Arena arena) {
      final aBuffer = arena<Double>(m * k);
      final bBuffer = arena<Double>(k * n);
      final resultsBuffer = arena<Double>(iterations * m * n);

      // Copy input matrices to native memory
      for (int i = 0; i < m * k; i++) {
        aBuffer[i] = A[i];
      }
      for (int i = 0; i < k * n; i++) {
        bBuffer[i] = B[i];
      }

      instance.matrix_multiply_batch(m, k, n, aBuffer, bBuffer, iterations, resultsBuffer);

      // Copy results back to Dart list
      for (int i = 0; i < iterations * m * n; i++) {
        results[i] = resultsBuffer[i];
      }
    });
  }
}
