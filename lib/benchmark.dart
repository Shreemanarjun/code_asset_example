import 'benchmark_runner.dart';
import 'native_library.dart';

// Export the main classes for external use
export 'benchmark_runner.dart' show BenchmarkRunner, runBenchmark;
export 'native_library.dart' show NativeLibraryProvider;

/// Comprehensive FFI Performance Benchmark Library
/// Demonstrates proper FFI usage with using() and Arena
/// Compares: Single FFI vs Batched FFI vs Pure Dart
/// Supports Fibonacci and Factorial algorithms

/// Benchmark configuration class
class BenchmarkConfig {
  final String algorithm;
  final int inputSize;
  final int iterations;
  final int runs;

  BenchmarkConfig(this.algorithm, this.inputSize, this.iterations, this.runs);

  static BenchmarkConfig parse(List<String> args) {
    String algorithm = 'both';
    int inputSize = 40;
    int iterations = 1000;
    int runs = 5;

    for (int i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--algorithm':
        case '-a':
          if (i + 1 < args.length) {
            algorithm = args[i + 1].toLowerCase();
            i++;
          }
          break;
        case '--size':
        case '-s':
          if (i + 1 < args.length) {
            inputSize = int.tryParse(args[i + 1]) ?? inputSize;
            i++;
          }
          break;
        case '--iterations':
        case '-i':
          if (i + 1 < args.length) {
            iterations = int.tryParse(args[i + 1]) ?? iterations;
            i++;
          }
          break;
        case '--runs':
        case '-r':
          if (i + 1 < args.length) {
            runs = int.tryParse(args[i + 1]) ?? runs;
            i++;
          }
          break;
        case '--demo':
          BenchmarkDemo.run();
          return BenchmarkConfig('demo', 0, 0, 0); // Special case for demo
        case '--help':
        case '-h':
          _printHelp();
          return BenchmarkConfig('help', 0, 0, 0); // Special case for help
      }
    }

    if (algorithm != 'fibonacci' && algorithm != 'factorial' && algorithm != 'both') {
      print('Error: Algorithm must be "fibonacci", "factorial", or "both"');
      return BenchmarkConfig('error', 0, 0, 0);
    }

    return BenchmarkConfig(algorithm, inputSize, iterations, runs);
  }

  static void _printHelp() {
    print('Usage: dart run bin/comprehensive_benchmark.dart [options]');
    print('');
    print('Options:');
    print('  -a, --algorithm <name>    Algorithm to benchmark (fibonacci, factorial, both) [default: both]');
    print('  -s, --size <number>       Input size for algorithm [default: 40]');
    print('  -i, --iterations <number> Number of iterations per run [default: 1000]');
    print('  -r, --runs <number>       Number of runs for averaging [default: 5]');
    print('  -I, --isolate             Use isolate mode for concurrent FFI operations');
    print('  -D, --direct              Use direct mode for FFI calls (default)');
    print('  --no-isolate              Same as --direct');
    print('  -h, --help               Show this help message');
    print('');
    print('Execution Modes:');
    print('  Direct Mode (default): FFI calls execute in main isolate');
    print('  Isolate Mode: FFI calls execute in separate isolate for concurrency');
    print('                Better for batched operations, higher overhead for single calls');
    print('');
    print('Examples:');
    print('  dart run bin/comprehensive_benchmark.dart');
    print('  dart run bin/comprehensive_benchmark.dart -a fibonacci -s 30');
    print('  dart run bin/comprehensive_benchmark.dart -a factorial -s 15 -i 500 -r 10');
    print('  dart run bin/comprehensive_benchmark.dart --isolate  # Use isolate mode');
    print('  dart run bin/comprehensive_benchmark.dart --direct   # Use direct mode (explicit)');
  }
}

/// Algorithm-specific benchmark runners
class AlgorithmBenchmarks {
  final BenchmarkRunner _runner;

  AlgorithmBenchmarks() : _runner = BenchmarkRunner();

  Future<void> runFibonacciBenchmark(BenchmarkConfig config) async {
    final n = config.inputSize;
    final iterations = config.iterations;
    final runs = config.runs;

    print('🐰 FIBONACCI SEQUENCE PERFORMANCE TABLE');
    print('=' * 60);
    print('Input: Generate first $n Fibonacci numbers');
    print('Iterations per run: $iterations');
    print('Number of runs: $runs (averaged)');
    print('');

    await _runner.runBenchmark(
      algorithmName: 'Fibonacci',
      dartFunction: fiboDart,
      nativeSingleFunction: (n) => NativeLibraryProvider.fibo(n),
      nativeBatchFunction: (n, iterations, buffer) => NativeLibraryProvider.fiboBatch(n, iterations, buffer),
      inputSize: n,
      maxIterations: iterations,
      numRuns: runs,
    );
  }

  Future<void> runFactorialBenchmark(BenchmarkConfig config) async {
    // Use smaller input size for factorial to avoid integer overflow
    final n = config.inputSize > 20 ? 15 : config.inputSize;
    final iterations = config.iterations;
    final runs = config.runs;

    print('🔢 FACTORIAL PERFORMANCE TABLE');
    print('=' * 60);
    print('Input: Calculate $n!');
    print('Iterations per run: $iterations');
    print('Number of runs: $runs (averaged)');
    if (config.inputSize > 20) {
      print('Note: Using n=15 for factorial (n>20 causes integer overflow)');
    }
    print('');

    await _runner.runBenchmark(
      algorithmName: 'Factorial',
      dartFunction: factorialDart,
      nativeSingleFunction: (input) => NativeLibraryProvider.factorial(input),
      nativeBatchFunction: (input, iters, buffer) => NativeLibraryProvider.factorialBatch(input, iters, buffer),
      inputSize: n,
      maxIterations: iterations,
      numRuns: runs,
    );
  }
}

/// Demo class for programmatic API
class BenchmarkDemo {
  static void run() {
    print('\n🎯 DEMONSTRATION: Programmatic Benchmark API');
    print('=' * 60);

    final runner = BenchmarkRunner();

    // Example 1: Fibonacci benchmark
    print('Example 1: Fibonacci Benchmark');
    runner.runBenchmark(
      algorithmName: 'Fibonacci',
      dartFunction: fiboDart,
      nativeSingleFunction: (n) => NativeLibraryProvider.fibo(n),
      nativeBatchFunction: (n, iterations, buffer) => NativeLibraryProvider.fiboBatch(n, iterations, buffer),
      inputSize: 30,
      maxIterations: 100,
      numRuns: 3,
    );

    print('\n${'=' * 80}');

    // Example 2: Factorial benchmark
    print('\nExample 2: Factorial Benchmark');
    runner.runBenchmark(
      algorithmName: 'Factorial',
      dartFunction: factorialDart,
      nativeSingleFunction: (n) => NativeLibraryProvider.factorial(n),
      nativeBatchFunction: (n, iterations, buffer) => NativeLibraryProvider.factorialBatch(n, iterations, buffer),
      inputSize: 15,
      maxIterations: 200,
      numRuns: 3,
    );

    print('\n💡 Note: These examples use actual native FFI functions.');
    print('   The benchmark compares Dart vs C implementations.');
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
