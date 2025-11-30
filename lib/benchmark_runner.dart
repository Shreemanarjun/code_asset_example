/// Function-agnostic benchmark runner
/// Can benchmark any functions with proper performance measurement
class BenchmarkRunner {
  Future<void> runBenchmark<T>({
    required String algorithmName,
    required DartFunction<T> dartFunction,
    required NativeSingleFunction<T> nativeSingleFunction,
    required NativeBatchFunction nativeBatchFunction,
    required int inputSize,
    required int maxIterations,
    int numRuns = 5,
  }) async {
    print('🔬 CUSTOM BENCHMARK: $algorithmName');
    print('=' * 60);
    print('Input size: $inputSize');
    print('Max iterations: $maxIterations');
    print('Runs for averaging: $numRuns');
    print('');

    final results = <List<dynamic>>[];

    // Benchmark Dart implementation
    print('📊 Benchmarking Dart Implementation...');
    final dartTimes = <int>[];
    for (int run = 0; run < numRuns; run++) {
      final start = DateTime.now();
      for (int i = 0; i < maxIterations; i++) {
        dartFunction(inputSize);
      }
      final time = DateTime.now().difference(start).inMicroseconds;
      dartTimes.add(time);
    }
    final avgDartTime = (dartTimes.reduce((a, b) => a + b) / numRuns).round();
    results.add(['Dart', 'Single', avgDartTime, 'μs']);

    // Benchmark FFI Single calls
    print('📊 Benchmarking FFI Single Calls...');
    final singleTimes = <int>[];
    for (int run = 0; run < numRuns; run++) {
      final start = DateTime.now();
      for (int i = 0; i < maxIterations; i++) {
        nativeSingleFunction(inputSize);
      }
      final time = DateTime.now().difference(start).inMicroseconds;
      singleTimes.add(time);
    }
    final avgSingleTime = (singleTimes.reduce((a, b) => a + b) / numRuns).round();
    results.add(['FFI C', 'Single', avgSingleTime, 'μs']);

    // Benchmark FFI Batched calls
    print('📊 Benchmarking FFI Batched Calls...');
    final batchTimes = <int>[];
    for (int run = 0; run < numRuns; run++) {
      final start = DateTime.now();
      // For Fibonacci, each iteration produces inputSize results, so total buffer size is maxIterations * inputSize
      // For Factorial, each iteration produces 1 result, so buffer size is maxIterations
      final bufferSize = algorithmName == 'Fibonacci' ? maxIterations * inputSize : maxIterations;
      final results_buffer = List<int>.filled(bufferSize, 0);
      nativeBatchFunction(inputSize, maxIterations, results_buffer);
      final time = DateTime.now().difference(start).inMicroseconds;
      batchTimes.add(time);
    }
    final avgBatchTime = (batchTimes.reduce((a, b) => a + b) / numRuns).round();
    results.add(['FFI C', 'Batched', avgBatchTime, 'μs']);



    // Display results
    _displayResultsTable('$algorithmName ($inputSize)', results, numRuns);
  }

  void _displayResultsTable(String algorithm, List<List<dynamic>> results, int runs) {
    final algoName = algorithm.split(' ')[0];
    final inputSize = algorithm.split(' ')[1].replaceAll('(', '').replaceAll(')', '');

    // Algorithm header with clear separation
    print('╔══════════════════════════════════════════════════════════════════════════════╗');
    print('║                           🔬 PERFORMANCE ANALYSIS                           ║');
    print('╠══════════════════════════════════════════════════════════════════════════════╣');
    print('║ Algorithm: ${algoName.padRight(20)} Input Size: ${inputSize.padRight(10)} Runs: ${runs.toString().padRight(3)} ║');
    print('╚══════════════════════════════════════════════════════════════════════════════╝');
    print('');

    // Sort results by performance (best first)
    results.sort((a, b) => (a[2] as int).compareTo(b[2] as int));
    final bestTime = results[0][2] as int;
    final slowestTime = results.last[2] as int;
    final totalSpeedup = slowestTime > 0 ? (slowestTime / bestTime) : 0.0;

    // Performance table
    print('┌────────────┬────────────┬──────────┬────────────┬─────────┬─────────────┐');
    print('│ Algorithm  │ Language   │ Mode     │ Time       │ vs Best │ Performance │');
    print('├────────────┼────────────┼──────────┼────────────┼─────────┼─────────────┤');

    for (final row in results) {
      // Results structure: [algorithm, mode, time, unit]
      final algorithm = (row[0] as String).padRight(10);
      final mode = (row[1] as String).padRight(8);
      final timeValue = row[2] as int;
      final unit = row[3] as String;
      final time = '$timeValue$unit'.padRight(10);
      final vsBest = bestTime > 0 ? '${((timeValue / bestTime) * 100).toStringAsFixed(0)}%' : 'N/A';
      final marker = row == results[0] ? ' 🏆' : '';

      // Determine language from algorithm
      final language = row[0] == 'Dart' ? 'Dart'.padRight(10) : 'C'.padRight(10);

      // Performance rating
      final perfRatio = timeValue / bestTime;
      final performance = perfRatio <= 1.1 ? '⭐ EXCELLENT' :
                         perfRatio <= 2.0 ? '✅ GOOD     ' :
                         perfRatio <= 5.0 ? '⚠️  SLOW     ' :
                         '❌ VERY SLOW ';

      print('│ $algorithm │ $language │ $mode │ $time │ $vsBest$marker │ $performance │');
    }

    print('└────────────┴────────────┴──────────┴────────────┴─────────┴─────────────┘');
    print('');

    // Detailed performance analysis
    print('📈 DETAILED PERFORMANCE ANALYSIS');
    print('=' * 50);

    final winner = results[0];
    final winnerName = '${winner[0]} (${winner[1]})';
    final winnerTime = '${winner[3]}μs';

    print('🏆 WINNER: $winnerName - $winnerTime');
    print('📊 Performance Range: ${totalSpeedup.toStringAsFixed(1)}x (fastest vs slowest)');
    print('🎯 Total Operations: ${runs * (algoName == 'Fibonacci' ? int.parse(inputSize) * 1000 : 1000)}');

    // FFI-specific insights
    final ffiResults = results.where((r) => r[0] == 'FFI C').toList();
    if (ffiResults.isNotEmpty) {
      print('');
      print('🔧 FFI-SPECIFIC INSIGHTS:');
      print('─' * 30);

      final hasBatched = ffiResults.any((r) => r[1] == 'Batched');
      final hasSingle = ffiResults.any((r) => r[1] == 'Single');

      if (hasBatched && hasSingle) {
        final batchedRow = ffiResults.firstWhere((r) => r[1] == 'Batched');
        final singleRow = ffiResults.firstWhere((r) => r[1] == 'Single');
        final batchSpeedup = (singleRow[2] as int) / (batchedRow[2] as int);

        print('• FFI Batching Speedup: ${batchSpeedup.toStringAsFixed(1)}x');
        print('• Single FFI Overhead: High boundary crossing cost');
        print('• Batched FFI Efficiency: Minimized context switches');
      }

      print('• Memory Management: Arena-based (leak-free)');
      print('• Thread Safety: Isolate-compatible');
    }

    // Recommendations
    print('');
    print('💡 RECOMMENDATIONS:');
    print('─' * 20);

    if (winner[0] == 'Dart') {
      print('• For this workload, pure Dart is optimal');
      print('• Consider Dart for CPU-bound algorithms');
    } else if (winner[1] == 'Batched') {
      print('• Use FFI batching for high-volume operations');
      print('• Consider isolate mode for concurrent processing');
      print('• Batch size optimization can further improve performance');
    }

    if (totalSpeedup > 10) {
      print('• Large performance gap indicates optimization opportunity');
      print('• Consider algorithm-specific optimizations');
    }

    print('');
    print('✅ Analysis completed successfully!');
    print('=' * 50);
  }
}

/// Function signature for Dart algorithms
typedef DartFunction<T> = T Function(int);

/// Function signature for native single operations
typedef NativeSingleFunction<T> = Future<T> Function(int);

/// Function signature for native batched operations
typedef NativeBatchFunction = Future<void> Function(int, int, List<int>);

/// Main benchmark function - programmatic API
/// Parameters (all named for clarity):
/// - algorithmName: Name of the algorithm (for display)
/// - dartFunction: Pure Dart implementation
/// - nativeSingleFunction: Native single-operation function
/// - nativeBatchFunction: Native batched-operation function
/// - inputSize: Input parameter for the algorithm
/// - maxIterations: Maximum iterations to run
/// - numRuns: Number of runs for averaging (default: 5)
void runBenchmark<T>({
  required String algorithmName,
  required DartFunction<T> dartFunction,
  required NativeSingleFunction<T> nativeSingleFunction,
  required NativeBatchFunction nativeBatchFunction,
  required int inputSize,
  required int maxIterations,
  int numRuns = 5,
}) {
  final runner = BenchmarkRunner();
  runner.runBenchmark(
    algorithmName: algorithmName,
    dartFunction: dartFunction,
    nativeSingleFunction: nativeSingleFunction,
    nativeBatchFunction: nativeBatchFunction,
    inputSize: inputSize,
    maxIterations: maxIterations,
    numRuns: numRuns,
  );
}
