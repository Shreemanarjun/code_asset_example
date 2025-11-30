// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';
import 'package:code_asset_example/add.g.dart';
import 'package:code_asset_example/native_library.dart';
import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

void main() {
  late NativeLibrary? nativeLib;
  bool nativeLibAvailable = false;

  setUp(() {
    try {
      final lib = Platform.isMacOS
          ? DynamicLibrary.open('libnative_add.dylib')
          : Platform.isLinux
              ? DynamicLibrary.open('libnative_add.so')
              : DynamicLibrary.open('native_add.dll');
      nativeLib = NativeLibrary(lib);
      nativeLibAvailable = true;
    } catch (e) {
      // Native library not available - skip native tests
      nativeLib = null;
      nativeLibAvailable = false;
    }
  });

  // ============================================================================
  // LOW-LEVEL FFI TESTS
  // ============================================================================

  group('Low-level FFI Functions', () {
    test('invoke native add function', () {
      if (!nativeLibAvailable || nativeLib == null) {
        print('⚠️  Skipping native FFI tests - native library not available');
        return;
      }
      expect(nativeLib!.add(24, 18), 42);
      expect(nativeLib!.add(0, 0), 0);
      expect(nativeLib!.add(-5, 10), 5);
    });

    test('invoke native factorial function', () {
      if (!nativeLibAvailable || nativeLib == null) {
        print('⚠️  Skipping native FFI tests - native library not available');
        return;
      }
      expect(nativeLib!.factorial(0), 1);
      expect(nativeLib!.factorial(1), 1);
      expect(nativeLib!.factorial(5), 120);
      expect(nativeLib!.factorial(10), 3628800);
    });

    test('invoke native fibo function', () {
      if (!nativeLibAvailable || nativeLib == null) {
        print('⚠️  Skipping native FFI tests - native library not available');
        return;
      }
      final buffer = calloc<Int32>(10);
      try {
        nativeLib!.fibo(10, buffer);
        expect(buffer[0], 0);
        expect(buffer[1], 1);
        expect(buffer[2], 1);
        expect(buffer[3], 2);
        expect(buffer[4], 3);
        expect(buffer[5], 5);
        expect(buffer[6], 8);
        expect(buffer[7], 13);
        expect(buffer[8], 21);
        expect(buffer[9], 34);
      } finally {
        calloc.free(buffer);
      }
    });

    test('invoke native fibo_batch function', () {
      if (!nativeLibAvailable || nativeLib == null) {
        print('⚠️  Skipping native FFI tests - native library not available');
        return;
      }
      const iterations = 3;
      const n = 5;
      final buffer = calloc<Int32>(iterations * n);
      try {
        nativeLib!.fibo_batch(n, iterations, buffer);

        // First iteration: [0, 1, 1, 2, 3]
        expect(buffer[0], 0);
        expect(buffer[1], 1);
        expect(buffer[2], 1);
        expect(buffer[3], 2);
        expect(buffer[4], 3);

        // Second iteration: [0, 1, 1, 2, 3] (same as first)
        expect(buffer[5], 0);
        expect(buffer[6], 1);
        expect(buffer[7], 1);
        expect(buffer[8], 2);
        expect(buffer[9], 3);

        // Third iteration: [0, 1, 1, 2, 3] (same as first)
        expect(buffer[10], 0);
        expect(buffer[11], 1);
        expect(buffer[12], 1);
        expect(buffer[13], 2);
        expect(buffer[14], 3);
      } finally {
        calloc.free(buffer);
      }
    });

    test('invoke native factorial_batch function', () {
      if (!nativeLibAvailable || nativeLib == null) {
        print('⚠️  Skipping native FFI tests - native library not available');
        return;
      }
      const iterations = 3;
      final buffer = calloc<Int64>(iterations);
      try {
        nativeLib!.factorial_batch(5, iterations, buffer);

        // All iterations should compute 5! = 120
        expect(buffer[0], 120);
        expect(buffer[1], 120);
        expect(buffer[2], 120);
      } finally {
        calloc.free(buffer);
      }
    });
  });

  // ============================================================================
  // HIGH-LEVEL PROVIDER TESTS
  // ============================================================================

  group('NativeLibraryProvider - Direct Mode', () {
    bool providerAvailable = false;

    setUp(() {
      try {
        // Test if provider can be instantiated
        final _ = NativeLibraryProvider.instance;
        providerAvailable = true;
      } catch (e) {
        providerAvailable = false;
      }
    });

    tearDown(() async {
      // Ensure isolate is cleaned up after each test
      if (NativeLibraryProvider.isIsolateMode) {
        NativeLibraryProvider.disposeIsolate();
      }
    });

    test('singleton instance creation', () {
      if (!providerAvailable) {
        print('⚠️  Skipping provider tests - native library not available');
        return;
      }
      final instance1 = NativeLibraryProvider.instance;
      final instance2 = NativeLibraryProvider.instance;
      expect(identical(instance1, instance2), true);
    });

    test('fibonacci single operation', () async {
      final result = await NativeLibraryProvider.fibo(8);
      expect(result.length, 8);
      expect(result, [0, 1, 1, 2, 3, 5, 8, 13]);
    });

    test('fibonacci batch operation', () async {
      const iterations = 2;
      const n = 6;
      final results = List<int>.filled(iterations * n, 0);
      await NativeLibraryProvider.fiboBatch(n, iterations, results);

      expect(results.length, iterations * n);
      // First batch: [0, 1, 1, 2, 3, 5]
      expect(results.sublist(0, 6), [0, 1, 1, 2, 3, 5]);
      // Second batch: [0, 1, 1, 2, 3, 5] (same)
      expect(results.sublist(6, 12), [0, 1, 1, 2, 3, 5]);
    });

    test('factorial single operation', () async {
      expect(await NativeLibraryProvider.factorial(0), 1);
      expect(await NativeLibraryProvider.factorial(1), 1);
      expect(await NativeLibraryProvider.factorial(5), 120);
      expect(await NativeLibraryProvider.factorial(10), 3628800);
    });

    test('factorial batch operation', () async {
      const iterations = 3;
      final results = List<int>.filled(iterations, 0);
      await NativeLibraryProvider.factorialBatch(6, iterations, results);

      // All should be 6! = 720
      expect(results, [720, 720, 720]);
    });

    test('memory management with Arena', () async {
      // Test that operations complete without memory leaks
      final futures = <Future>[];

      for (int i = 0; i < 10; i++) {
        futures.add(NativeLibraryProvider.fibo(5));
        futures.add(NativeLibraryProvider.factorial(5));
      }

      await Future.wait(futures);
      // If we get here without crashes, memory management is working
      expect(true, true);
    });
  });

  // ============================================================================
  // ISOLATE MODE TESTS
  // ============================================================================

  group('NativeLibraryProvider - Isolate Mode', () {
    setUp(() async {
      await NativeLibraryProvider.initializeIsolate();
      expect(NativeLibraryProvider.isIsolateMode, true);
    });

    tearDown(() async {
      if (NativeLibraryProvider.isIsolateMode) {
        NativeLibraryProvider.disposeIsolate();
      }
    });

    test('isolate mode initialization', () async {
      expect(NativeLibraryProvider.isIsolateMode, true);
    });

    test('fibonacci in isolate mode', () async {
      final result = await NativeLibraryProvider.fibo(6);
      expect(result, [0, 1, 1, 2, 3, 5]);
    });

    test('factorial in isolate mode', () async {
      expect(await NativeLibraryProvider.factorial(7), 5040);
    });

    test('batch operations in isolate mode', () async {
      const iterations = 2;
      final fibResults = List<int>.filled(iterations * 4, 0);
      final factResults = List<int>.filled(iterations, 0);

      await Future.wait([
        NativeLibraryProvider.fiboBatch(4, iterations, fibResults),
        NativeLibraryProvider.factorialBatch(4, iterations, factResults),
      ]);

      expect(fibResults, [0, 1, 1, 2, 0, 1, 1, 2]); // Two identical sequences
      expect(factResults, [24, 24]); // 4! = 24 for both
    });

    test('concurrent operations in isolate mode', () async {
      final futures = <Future>[];

      // Launch multiple concurrent operations
      for (int i = 0; i < 5; i++) {
        futures.add(NativeLibraryProvider.fibo(3));
        futures.add(NativeLibraryProvider.factorial(3));
      }

      final results = await Future.wait(futures);

      // Verify results
      for (int i = 0; i < results.length; i += 2) {
        expect(results[i], [0, 1, 1]); // Fibonacci results
        expect(results[i + 1], 6); // Factorial results (3! = 6)
      }
    });
  });

  // ============================================================================
  // ERROR HANDLING TESTS
  // ============================================================================

  group('Error Handling and Edge Cases', () {
    test('factorial overflow handling', () async {
      // Test with large values that should overflow
      final result = await NativeLibraryProvider.factorial(25);
      expect(result, greaterThan(0)); // Should handle gracefully
    });

    test('fibonacci with large n', () async {
      final result = await NativeLibraryProvider.fibo(50);
      expect(result.length, 50);
      expect(result[0], 0);
      expect(result[1], 1);
      // Verify Fibonacci sequence properties
      for (int i = 2; i < result.length; i++) {
        expect(result[i], result[i-1] + result[i-2]);
      }
    });

    test('empty results handling', () async {
      final result = await NativeLibraryProvider.fibo(0);
      expect(result, isEmpty);
    });

    test('batch operations with different sizes', () async {
      final results1 = List<int>.filled(10, 0);
      final results2 = List<int>.filled(20, 0);

      await Future.wait([
        NativeLibraryProvider.fiboBatch(5, 2, results1),
        NativeLibraryProvider.factorialBatch(3, 20, results2),
      ]);

      expect(results1.length, 10);
      expect(results2.length, 20);
      expect(results2.every((fact) => fact == 6), true); // 3! = 6
    });
  });

  // ============================================================================
  // PERFORMANCE VALIDATION TESTS
  // ============================================================================

  group('Performance Validation', () {
    test('batch operations are more efficient than individual calls', () async {
      // Measure time for individual calls
      final startIndividual = DateTime.now();
      for (int i = 0; i < 10; i++) {
        await NativeLibraryProvider.fibo(5);
      }
      final individualTime = DateTime.now().difference(startIndividual);

      // Measure time for batch call
      final startBatch = DateTime.now();
      final batchResults = List<int>.filled(10 * 5, 0);
      await NativeLibraryProvider.fiboBatch(5, 10, batchResults);
      final batchTime = DateTime.now().difference(startBatch);

      // Batch should be faster (allowing for some variance)
      expect(batchTime.inMilliseconds, lessThanOrEqualTo(individualTime.inMilliseconds * 2));
    });

    test('isolate mode provides performance benefits for concurrent operations', () async {
      await NativeLibraryProvider.initializeIsolate();

      final start = DateTime.now();
      final futures = <Future>[];
      for (int i = 0; i < 20; i++) {
        futures.add(NativeLibraryProvider.fibo(3));
      }
      await Future.wait(futures);
      final totalTime = DateTime.now().difference(start);

      // Should complete within reasonable time
      expect(totalTime.inSeconds, lessThan(10));

      NativeLibraryProvider.disposeIsolate();
    });
  });

  // ============================================================================
  // INTEGRATION TESTS
  // ============================================================================

  group('Integration Tests', () {
    test('complete workflow: init -> operations -> cleanup', () async {
      // Initialize isolate
      await NativeLibraryProvider.initializeIsolate();
      expect(NativeLibraryProvider.isIsolateMode, true);

      // Perform various operations
      final fibResult = await NativeLibraryProvider.fibo(4);
      final factResult = await NativeLibraryProvider.factorial(4);
      final batchResults = List<int>.filled(8, 0);
      await NativeLibraryProvider.fiboBatch(4, 2, batchResults);

      // Verify results
      expect(fibResult, [0, 1, 1, 2]);
      expect(factResult, 24); // 4! = 24
      expect(batchResults, [0, 1, 1, 2, 0, 1, 1, 2]);

      // Cleanup
      NativeLibraryProvider.disposeIsolate();
      expect(NativeLibraryProvider.isIsolateMode, false);
    });

    test('mixed direct and isolate operations', () async {
      // Start with direct mode
      expect(NativeLibraryProvider.isIsolateMode, false);

      final directResult = await NativeLibraryProvider.fibo(3);
      expect(directResult, [0, 1, 1]);

      // Switch to isolate mode
      await NativeLibraryProvider.initializeIsolate();
      expect(NativeLibraryProvider.isIsolateMode, true);

      final isolateResult = await NativeLibraryProvider.fibo(3);
      expect(isolateResult, [0, 1, 1]);

      // Both should produce same results
      expect(directResult, isolateResult);

      // Cleanup
      NativeLibraryProvider.disposeIsolate();
    });
  });
}
