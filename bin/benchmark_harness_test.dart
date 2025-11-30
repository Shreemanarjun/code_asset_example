import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:code_asset_example/benchmark_harness.dart';

class BenchmarkResult {
  final String algorithm;
  final String type;
  final String mode;
  final double time;
  final bool isBatch;

  BenchmarkResult(this.algorithm, this.type, this.mode, this.time, {this.isBatch = false});

  @override
  String toString() => '$algorithm-$type-$mode${isBatch ? '-batch' : ''}: ${time.toStringAsFixed(2)} μs';
}

class BenchmarkComparator {
  final List<BenchmarkResult> results = [];

  Future<void> measureAsyncBenchmark(String name, AsyncBenchmarkBase benchmark) async {
    final time = await benchmark.measure();
    results.add(_parseResult(name, time));
  }

  void measureSyncBenchmark(String name, BenchmarkBase benchmark) {
    final time = benchmark.measure();
    results.add(_parseResult(name, time));
  }

  BenchmarkResult _parseResult(String name, double time) {
    // Parse benchmark name to extract algorithm, type, mode
    final parts = name.split('(')[0].split(',');
    final algorithm = parts[0].split('(')[0].replaceAll('Dart', '').replaceAll('Benchmark', '');
    final type = name.contains('Dart') ? 'Dart' : 'FFI';
    final mode = name.contains('isolate=true') ? 'Isolate' : 'Direct';
    final isBatch = name.contains('Batch');

    return BenchmarkResult(algorithm, type, mode, time, isBatch: isBatch);
  }

  void printComparisonTable() {
    print('\n📊 BENCHMARK HARNESS TEST - PERFORMANCE COMPARISON');
    print('=' * 80);

    // Group by algorithm and batch type
    final Map<String, List<BenchmarkResult>> grouped = {};
    for (final result in results) {
      final key = '${result.algorithm}${result.isBatch ? '_batch' : '_single'}';
      grouped.putIfAbsent(key, () => []).add(result);
    }

    for (final entry in grouped.entries) {
      final algorithmResults = entry.value;
      if (algorithmResults.isEmpty) continue;

      final algorithm = algorithmResults.first.algorithm;
      final isBatch = algorithmResults.first.isBatch;

      print('\n${isBatch ? '🔄' : '⚡'} ${algorithm.toUpperCase()} ${isBatch ? 'BATCH' : 'SINGLE'} PERFORMANCE');
      print('-' * 60);

      // Sort by time (ascending)
      algorithmResults.sort((a, b) => a.time.compareTo(b.time));

      // Calculate column widths
      const algoWidth = 15; // Fixed width for algorithm column
      const langWidth = 10;
      const modeWidth = 8;
      const timeWidth = 12;
      const ratioWidth = 9;
      const perfWidth = 13;

      // Print table header
      final header = '┌${'─' * (algoWidth + 2)}┬${'─' * (langWidth + 2)}┬${'─' * (modeWidth + 2)}┬${'─' * (timeWidth + 2)}┬${'─' * (ratioWidth + 2)}┬${'─' * (perfWidth + 2)}┐';
      final separator = '├${'─' * (algoWidth + 2)}┼${'─' * (langWidth + 2)}┼${'─' * (modeWidth + 2)}┼${'─' * (timeWidth + 2)}┼${'─' * (ratioWidth + 2)}┼${'─' * (perfWidth + 2)}┤';
      final footer = '└${'─' * (algoWidth + 2)}┴${'─' * (langWidth + 2)}┴${'─' * (modeWidth + 2)}┴${'─' * (timeWidth + 2)}┴${'─' * (ratioWidth + 2)}┴${'─' * (perfWidth + 2)}┘';

      print(header);
      print('│ ${'Algorithm'.padRight(algoWidth)} │ ${'Language'.padRight(langWidth)} │ ${'Mode'.padRight(modeWidth)} │ ${'Time (μs)'.padLeft(timeWidth)} │ ${'vs Best'.padLeft(ratioWidth)} │ ${'Performance'.padRight(perfWidth)} │');
      print(separator);

      final bestTime = algorithmResults.first.time;

      for (final result in algorithmResults) {
        final ratio = result.time / bestTime;
        final performance = _getPerformanceLabel(ratio);

        // Truncate algorithm name if too long
        final displayAlgo = algorithm.length > algoWidth ? '${algorithm.substring(0, algoWidth - 3)}...' : algorithm;

        print('│ ${displayAlgo.padRight(algoWidth)} │ ${result.type.padRight(langWidth)} │ ${result.mode.padRight(modeWidth)} │ ${result.time.toStringAsFixed(1).padLeft(timeWidth)} │ ${ratio.toStringAsFixed(1).padLeft(ratioWidth - 1)}x │ ${performance.padRight(perfWidth)} │');
      }

      print(footer);

      final winner = algorithmResults.first;
      print('🏆 WINNER: ${winner.type} (${winner.mode}) - ${winner.time.toStringAsFixed(2)} μs');
    }

    print('\n📈 SUMMARY');
    print('-' * 30);
    final totalResults = results.length;
    final dartResults = results.where((r) => r.type == 'Dart').length;
    final ffiResults = results.where((r) => r.type == 'FFI').length;
    final dartWins = results.where((r) => r.type == 'Dart' && _isWinner(r, results)).length;
    final ffiWins = results.where((r) => r.type == 'FFI' && _isWinner(r, results)).length;

    print('Total benchmarks run: $totalResults');
    print('Dart implementations: $dartResults');
    print('FFI implementations: $ffiResults');
    print('Dart wins: $dartWins');
    print('FFI wins: $ffiWins');

    if (dartWins > ffiWins) {
      print('🎯 Overall winner: Dart implementations');
    } else if (ffiWins > dartWins) {
      print('🎯 Overall winner: FFI implementations');
    } else {
      print('🤝 Tie between Dart and FFI implementations');
    }
  }

  bool _isWinner(BenchmarkResult result, List<BenchmarkResult> allResults) {
    final sameAlgorithm = allResults.where((r) =>
      r.algorithm == result.algorithm && r.isBatch == result.isBatch);
    final minTime = sameAlgorithm.map((r) => r.time).reduce((a, b) => a < b ? a : b);
    return result.time == minTime;
  }

  String _getPerformanceLabel(double ratio) {
    if (ratio <= 1.1) return '⭐ EXCELLENT';
    if (ratio <= 2.0) return '✅ GOOD';
    if (ratio <= 5.0) return '⚠️  SLOW';
    return '❌ VERY SLOW';
  }
}

void main() async {
  final comparator = BenchmarkComparator();

  print('🧪 BENCHMARK HARNESS TEST');
  print('=' * 40);

  // Test individual benchmarks with measurement
  print('Testing individual benchmarks...');

  print('\n1. Dart Fibonacci:');
  comparator.measureSyncBenchmark('DartFibonacci(n=20)', DartFibonacciBenchmark(20));

  print('\n2. Dart Factorial:');
  comparator.measureSyncBenchmark('DartFactorial(n=15)', DartFactorialBenchmark(15));

  print('\n3. FFI Fibonacci (Direct):');
  await runBenchmarkSafely(() => comparator.measureAsyncBenchmark('Fibonacci(n=20, isolate=false)', FibonacciBenchmark(20, useIsolate: false)));

  print('\n4. FFI Factorial (Direct):');
  await runBenchmarkSafely(() => comparator.measureAsyncBenchmark('Factorial(n=15, isolate=false)', FactorialBenchmark(15, useIsolate: false)));

  print('\n5. FFI Fibonacci (Isolate):');
  await runBenchmarkSafely(() => comparator.measureAsyncBenchmark('Fibonacci(n=20, isolate=true)', FibonacciBenchmark(20, useIsolate: true)));

  print('\n6. FFI Factorial (Isolate):');
  await runBenchmarkSafely(() => comparator.measureAsyncBenchmark('Factorial(n=15, isolate=true)', FactorialBenchmark(15, useIsolate: true)));

  print('\n7. Dart Fibonacci Batch:');
  comparator.measureSyncBenchmark('DartFibonacciBatch(n=20, iter=50)', DartFibonacciBatchBenchmark(20, 50));

  print('\n8. FFI Fibonacci Batch (Direct):');
  await runBenchmarkSafely(() => comparator.measureAsyncBenchmark('FibonacciBatch(n=20, iter=50, isolate=false)', FibonacciBatchBenchmark(20, 50, useIsolate: false)));

  print('\n9. FFI Fibonacci Batch (Isolate):');
  await runBenchmarkSafely(() => comparator.measureAsyncBenchmark('FibonacciBatch(n=20, iter=50, isolate=true)', FibonacciBatchBenchmark(20, 50, useIsolate: true)));

  print('\n10. Dart Factorial Batch:');
  comparator.measureSyncBenchmark('DartFactorialBatch(n=15, iter=50)', DartFactorialBatchBenchmark(15, 50));

  print('\n11. FFI Factorial Batch (Direct):');
  await runBenchmarkSafely(() => comparator.measureAsyncBenchmark('FactorialBatch(n=15, iter=50, isolate=false)', FactorialBatchBenchmark(15, 50, useIsolate: false)));

  print('\n12. FFI Factorial Batch (Isolate):');
  await runBenchmarkSafely(() => comparator.measureAsyncBenchmark('FactorialBatch(n=15, iter=50, isolate=true)', FactorialBatchBenchmark(15, 50, useIsolate: true)));

  print('\n✅ Individual benchmark tests completed!');

  // Print comparison table
  comparator.printComparisonTable();

  // Test comprehensive suite
  print('\n🚀 Testing comprehensive suite...');
  runBenchmarkSafelySync(() => ComprehensiveBenchmarkSuite.runAll(useIsolate: false, n: 15, iterations: 50));

  print('\n🎉 All benchmark harness tests completed successfully!');
}

Future<void> runBenchmarkSafely(Future<void> Function() benchmark) async {
  try {
    await benchmark();
  } catch (e) {
    if (e.toString().contains('Native library not available')) {
      print('⚠️  Skipping benchmark - native library not available');
    } else {
      print('❌ Benchmark failed: $e');
    }
  }
}

void runBenchmarkSafelySync(void Function() benchmark) {
  try {
    benchmark();
  } catch (e) {
    if (e.toString().contains('Native library not available')) {
      print('⚠️  Skipping benchmark - native library not available');
    } else {
      print('❌ Benchmark failed: $e');
    }
  }
}
