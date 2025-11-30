import 'dart:async';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'native_library.dart';

/// Benchmark harness integration for FFI performance analysis
/// Uses the official Dart benchmark_harness package for standardized measurements

/// Fibonacci Benchmark using BenchmarkBase
class FibonacciBenchmark extends AsyncBenchmarkBase {
  final int n;
  final bool useIsolate;

  FibonacciBenchmark(this.n, {this.useIsolate = false})
      : super('Fibonacci(n=$n, isolate=$useIsolate)');

  static void main(int n, {bool useIsolate = false}) {
    if (useIsolate) {
      NativeLibraryProvider.initializeIsolate();
    }
    FibonacciBenchmark(n, useIsolate: useIsolate).report();
    if (useIsolate) {
      NativeLibraryProvider.disposeIsolate();
    }
  }

  @override
  Future<void> run() async {
    await NativeLibraryProvider.fibo(n);
  }

  @override
  Future<void> setup() async {
    // Initialize isolate if needed
    if (useIsolate && !NativeLibraryProvider.isIsolateMode) {
      await NativeLibraryProvider.initializeIsolate();
    }
  }

  @override
  Future<void> teardown() async {
    // Cleanup handled in main
  }
}

/// Factorial Benchmark using BenchmarkBase
class FactorialBenchmark extends AsyncBenchmarkBase {
  final int n;
  final bool useIsolate;

  FactorialBenchmark(this.n, {this.useIsolate = false})
      : super('Factorial(n=$n, isolate=$useIsolate)');

  static void main(int n, {bool useIsolate = false}) {
    if (useIsolate) {
      NativeLibraryProvider.initializeIsolate();
    }
    FactorialBenchmark(n, useIsolate: useIsolate).report();
    if (useIsolate) {
      NativeLibraryProvider.disposeIsolate();
    }
  }

  @override
  Future<void> run() async {
    await NativeLibraryProvider.factorial(n);
  }

  @override
  Future<void> setup() async {
    if (useIsolate && !NativeLibraryProvider.isIsolateMode) {
      await NativeLibraryProvider.initializeIsolate();
    }
  }

  @override
  Future<void> teardown() async {
    // Cleanup handled in main
  }
}

/// Batch Fibonacci Benchmark
class FibonacciBatchBenchmark extends AsyncBenchmarkBase {
  final int n;
  final int iterations;
  final bool useIsolate;

  FibonacciBatchBenchmark(this.n, this.iterations, {this.useIsolate = false})
      : super('FibonacciBatch(n=$n, iter=$iterations, isolate=$useIsolate)');

  static void main(int n, int iterations, {bool useIsolate = false}) {
    if (useIsolate) {
      NativeLibraryProvider.initializeIsolate();
    }
    FibonacciBatchBenchmark(n, iterations, useIsolate: useIsolate).report();
    if (useIsolate) {
      NativeLibraryProvider.disposeIsolate();
    }
  }

  @override
  Future<void> run() async {
    final buffer = List<int>.filled(iterations * n, 0);
    await NativeLibraryProvider.fiboBatch(n, iterations, buffer);
  }

  @override
  Future<void> setup() async {
    if (useIsolate && !NativeLibraryProvider.isIsolateMode) {
      await NativeLibraryProvider.initializeIsolate();
    }
  }

  @override
  Future<void> teardown() async {
    // Cleanup handled in main
  }
}

/// Batch Factorial Benchmark
class FactorialBatchBenchmark extends AsyncBenchmarkBase {
  final int n;
  final int iterations;
  final bool useIsolate;

  FactorialBatchBenchmark(this.n, this.iterations, {this.useIsolate = false})
      : super('FactorialBatch(n=$n, iter=$iterations, isolate=$useIsolate)');

  static void main(int n, int iterations, {bool useIsolate = false}) {
    if (useIsolate) {
      NativeLibraryProvider.initializeIsolate();
    }
    FactorialBatchBenchmark(n, iterations, useIsolate: useIsolate).report();
    if (useIsolate) {
      NativeLibraryProvider.disposeIsolate();
    }
  }

  @override
  Future<void> run() async {
    final buffer = List<int>.filled(iterations, 0);
    await NativeLibraryProvider.factorialBatch(n, iterations, buffer);
  }

  @override
  Future<void> setup() async {
    if (useIsolate && !NativeLibraryProvider.isIsolateMode) {
      await NativeLibraryProvider.initializeIsolate();
    }
  }

  @override
  Future<void> teardown() async {
    // Cleanup handled in main
  }
}

/// Dart implementation benchmarks for comparison
class DartFibonacciBenchmark extends BenchmarkBase {
  final int n;

  DartFibonacciBenchmark(this.n) : super('DartFibonacci(n=$n)');

  static void main(int n) {
    DartFibonacciBenchmark(n).report();
  }

  @override
  void run() {
    fiboDart(n);
  }
}

class DartFactorialBenchmark extends BenchmarkBase {
  final int n;

  DartFactorialBenchmark(this.n) : super('DartFactorial(n=$n)');

  static void main(int n) {
    DartFactorialBenchmark(n).report();
  }

  @override
  void run() {
    factorialDart(n);
  }
}

/// Dart batch implementation benchmarks for direct comparison
class DartFibonacciBatchBenchmark extends BenchmarkBase {
  final int n;
  final int iterations;

  DartFibonacciBatchBenchmark(this.n, this.iterations) : super('DartFibonacciBatch(n=$n, iter=$iterations)');

  static void main(int n, int iterations) {
    DartFibonacciBatchBenchmark(n, iterations).report();
  }

  @override
  void run() {
    // Simulate batch operation by computing multiple Fibonacci sequences
    for (int i = 0; i < iterations; i++) {
      fiboDart(n);
    }
  }
}

class DartFactorialBatchBenchmark extends BenchmarkBase {
  final int n;
  final int iterations;

  DartFactorialBatchBenchmark(this.n, this.iterations) : super('DartFactorialBatch(n=$n, iter=$iterations)');

  static void main(int n, int iterations) {
    DartFactorialBatchBenchmark(n, iterations).report();
  }

  @override
  void run() {
    // Simulate batch operation by computing multiple factorials
    for (int i = 0; i < iterations; i++) {
      factorialDart(n);
    }
  }
}

// Dart implementation of Fibonacci sequence
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

// Dart implementation of factorial
int factorialDart(int n) {
  if (n < 0) return 0;
  if (n == 0 || n == 1) return 1;

  int result = 1;
  for (int i = 2; i <= n; i++) {
    result *= i;
  }
  return result;
}

/// Comprehensive benchmark suite using harness
class ComprehensiveBenchmarkSuite {
  static void runAll({bool useIsolate = false, int n = 20, int iterations = 100}) async {
    print('🚀 COMPREHENSIVE FFI BENCHMARK SUITE (Harness-based)');
    print('=' * 60);
    print('Using benchmark_harness for standardized measurements');
    print('Mode: ${useIsolate ? 'Isolate' : 'Direct'}');
    print('Input size: $n, Iterations: $iterations');
    print('');

    // Initialize isolate if needed
    if (useIsolate) {
      await NativeLibraryProvider.initializeIsolate();
    }

    try {
      print('🐰 FIBONACCI BENCHMARKS');
      print('-' * 30);

      // Dart Fibonacci single
      DartFibonacciBenchmark.main(n);

      // Dart Fibonacci batch (for direct comparison)
      DartFibonacciBatchBenchmark.main(n, iterations);

      // FFI Fibonacci single
      FibonacciBenchmark.main(n, useIsolate: useIsolate);

      // FFI Fibonacci batch
      FibonacciBatchBenchmark.main(n, iterations, useIsolate: useIsolate);

      print('');
      print('🔢 FACTORIAL BENCHMARKS');
      print('-' * 30);

      // Adjust n for factorial to avoid overflow
      final factorialN = n > 15 ? 15 : n;

      // Dart Factorial single
      DartFactorialBenchmark.main(factorialN);

      // Dart Factorial batch (for direct comparison)
      DartFactorialBatchBenchmark.main(factorialN, iterations);

      // FFI Factorial single
      FactorialBenchmark.main(factorialN, useIsolate: useIsolate);

      // FFI Factorial batch
      FactorialBatchBenchmark.main(factorialN, iterations, useIsolate: useIsolate);

      print('');
      print('✅ Benchmark harness suite completed successfully!');

    } finally {
      if (useIsolate) {
        NativeLibraryProvider.disposeIsolate();
      }
    }
  }
}
