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
    _instance ??= _createNativeLibrary();
    return _instance!;
  }

  static NativeLibrary _createNativeLibrary() {
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

  /// Generic batch operation wrapper
  static void batchOperation(void Function(Pointer<Int32>) operation, int size, List<int> results) {
    using((Arena arena) {
      final buffer = arena<Int32>(size);
      operation(buffer);
      for (int i = 0; i < size; i++) {
        results[i] = buffer[i];
      }
    });
  }
}
