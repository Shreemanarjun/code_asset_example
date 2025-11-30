# Code Asset Example

A comprehensive Dart package demonstrating **Foreign Function Interface (FFI)** integration with native C code, featuring automated build hooks, performance benchmarking, and cross-platform native library compilation.

This package serves as a complete reference implementation for developers looking to integrate native code performance with Dart applications using modern Dart build tools and FFI capabilities.

## 🚀 Features

### Core Functionality
- **Native C Library Integration**: Seamless compilation and linking of C code with Dart
- **Automated Build Hooks**: Automatic native library building during package compilation
- **Cross-Platform Support**: Native code compilation for macOS, Windows, and Linux
- **Isolate Support**: Concurrent native operations using Dart isolates
- **Multiple Algorithm Implementations**: Fibonacci, Factorial, Monte Carlo Pi, and Matrix Multiplication
- **Batch Processing**: High-performance bulk computations for data processing workloads

### Benchmarking Suite
- **Comprehensive Performance Analysis**: Compare Dart vs FFI implementations
- **JIT vs AOT Mode Testing**: Performance validation across different compilation modes
- **Batch Operation Benchmarks**: Measure performance for bulk computations
- **Statistical Reporting**: Detailed performance metrics with winner identification

### Developer Experience
- **Hot-Reload Compatible**: Build hooks work with Dart's development workflow
- **Error Handling**: Graceful fallback when native libraries aren't available
- **Debugging Support**: Built-in logging and intermediate file inspection
- **Professional Output**: Formatted benchmark tables with performance ratings

## 📦 What's Included

- **Native C Implementation**: Optimized algorithms including Fibonacci, Factorial, Monte Carlo Pi estimation, and Matrix Multiplication
- **Dart FFI Bindings**: Complete FFI integration with type-safe interfaces
- **Build Hook System**: Automatic native library compilation via `hooks/build.dart`
- **Benchmark Harness**: Comprehensive performance testing suite
- **Cross-Platform Scripts**: Build configurations for multiple operating systems

## 🛠️ Getting Started

### Prerequisites
- Dart SDK (3.0+)
- C compiler (GCC/Clang on Unix, MSVC on Windows)
- For AOT testing: Full Dart SDK installation

### Installation
```bash
# Clone the repository
git clone <repository-url>
cd code_asset_example

# Install dependencies
dart pub get
```

### Quick Test
```bash
# Run basic functionality test
dart run bin/code_asset_example.dart

# Run benchmark suite (JIT mode)
dart run bin/benchmark_harness_test.dart

# Run benchmark suite (AOT mode) - Recommended for accurate performance measurement
dart run benchmark_harness:bench --flavor aot --target bin/benchmark_harness_test.dart

# Run Flutter example app (demonstrates UI integration)
cd example && flutter run
```

## 📊 Performance Benchmarking

### Benchmark Categories
- **Fibonacci Sequence**: Single value and batch computation
- **Factorial Calculation**: Single value and batch computation
- **Monte Carlo Pi Estimation**: Statistical computation using random sampling
- **Matrix Multiplication**: Linear algebra operations for scientific computing
- **Execution Modes**: Direct calls vs Isolate-based concurrent execution

### Sample Benchmark Output
```
📊 BENCHMARK HARNESS TEST - PERFORMANCE COMPARISON

⚡ FIBONACCI SINGLE PERFORMANCE
------------------------------------------------------------
┌─────────────────┬────────────┬──────────┬──────────────┬───────────┬───────────────┐
│ Algorithm       │ Language   │ Mode     │    Time (μs) │   vs Best │ Performance   │
├─────────────────┼────────────┼──────────┼──────────────┼───────────┼───────────────┤
│ Fibonacci       │ FFI        │ Direct   │          0.5 │      1.0x │ ⭐ EXCELLENT   │
│ Fibonacci       │ Dart       │ Direct   │          0.6 │      1.1x │ ✅ GOOD        │
│ Fibonacci       │ FFI        │ Isolate  │          5.3 │      9.8x │ ❌ VERY SLOW   │
└─────────────────┴────────────┴──────────┴──────────────┴───────────┴───────────────┘
🏆 WINNER: FFI (Direct) - 0.54 μs
```

### Key Findings
- **JIT Mode**: Dart typically outperforms FFI for algorithmic computations
- **AOT Mode**: Performance characteristics change with compilation optimization
- **Isolate Mode**: Adds overhead but enables concurrent processing
- **Batch Operations**: FFI excels in bulk computational workloads

## 🔧 Build System

### Automatic Native Compilation
The package uses Dart's build hook system to automatically compile native libraries:

```dart
// hooks/build.dart - Automatically runs during package building
void main(List<String> args) async {
  await build(args, (input, output) async {
    if (input.config.buildCodeAssets) {
      final builder = CBuilder.library(
        name: 'native_add',
        sources: ['src/native_add_library.c'],
        includes: ['src/'],
      );
      await builder.run(input: input, output: output);
    }
  });
}
```

### Manual Build Testing
```bash
# Test the build hook directly
dart run hooks/build.dart

# Build with custom configuration
dart run hooks/build.dart --config path/to/config.json
```

## 🎯 Usage Examples

### Basic FFI Usage
```dart
import 'package:code_asset_example/native_library.dart';

// Synchronous native calls
final fibResult = await NativeLibraryProvider.fibo(20);
final factResult = await NativeLibraryProvider.factorial(15);

// Monte Carlo Pi estimation
final piEstimate = await NativeLibraryProvider.monteCarloPi(1000000);

// Matrix multiplication (2x3 * 3x2 = 2x2 result)
final matrixA = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]; // 2x3
final matrixB = [7.0, 8.0, 9.0, 10.0, 11.0, 12.0]; // 3x2
final matrixResult = await NativeLibraryProvider.matrixMultiply(2, 3, 2, matrixA, matrixB);

// Batch operations
final buffer = List<int>.filled(50, 0);
await NativeLibraryProvider.fiboBatch(20, 50, buffer);

// Batch Pi estimation
final piResults = List<double>.filled(10, 0.0);
await NativeLibraryProvider.monteCarloPiBatch(100000, 10, piResults);

// Batch matrix multiplication
final matrixResults = List<double>.filled(20, 0.0); // 10 iterations * 2 results
await NativeLibraryProvider.matrixMultiplyBatch(2, 3, 2, matrixA, matrixB, 10, matrixResults);
```

### Isolate-Based Concurrent Processing
```dart
// Initialize isolate for concurrent operations
await NativeLibraryProvider.initializeIsolate();

final result = await NativeLibraryProvider.fibo(100);

// Cleanup when done
NativeLibraryProvider.disposeIsolate();
```

## 📱 Flutter Integration

### Example Flutter App
The package includes a complete Flutter example (`example/`) demonstrating:
- **UI Integration**: Professional Material Design interface
- **Performance Visualization**: Interactive charts comparing Dart vs FFI
- **Real-time Benchmarking**: Live performance measurements
- **Error Handling**: Graceful handling of sandboxed environments

### Flutter App Integration Notes
**Development Environment**: Flutter desktop apps run in sandboxed containers (especially on macOS) that restrict access to external files. The example app demonstrates the integration pattern but may show library loading errors in development.

**Production Deployment**: For production Flutter apps, native libraries should be:
1. **Bundled with the app** during the build process
2. **Included in platform-specific directories** (e.g., `ios/Frameworks/`, `android/src/main/jniLibs/`)
3. **Referenced via relative paths** within the app bundle

### Example App Features
- **Performance Charts**: Visual comparison using `fl_chart`
- **Real-time Measurements**: Microsecond-precision timing
- **Batch Operations**: Demonstrates bulk processing capabilities
- **Educational UI**: Explains FFI concepts and integration patterns

## 🏗️ Architecture

### Directory Structure
```
├── src/                 # Native C source code
│   ├── native_add_library.c    # C implementations of all algorithms
│   └── native_add_library.h    # C function declarations
├── lib/                 # Dart FFI bindings and implementations
│   ├── native_library.dart     # Main provider with FFI calls
│   ├── benchmark_harness.dart  # Benchmark classes for performance testing
│   ├── add.g.dart              # Auto-generated FFI bindings
│   ├── fibo.g.dart             # Fibonacci FFI bindings
│   └── benchmark_runner.dart   # Benchmark execution utilities
├── hooks/               # Build hooks for native compilation
│   └── build.dart
├── bin/                 # Executable scripts
│   ├── benchmark_harness_test.dart
│   └── code_asset_example.dart
└── test/                # Unit tests
```

### Build Process
1. **Package Build**: Dart build system triggers `hooks/build.dart`
2. **Native Compilation**: CBuilder compiles C sources to platform-specific libraries
3. **Asset Generation**: Native libraries are packaged as code assets
4. **FFI Binding**: Auto-generated bindings provide type-safe Dart interfaces

## 🔍 Debugging & Troubleshooting

### Build Issues
```bash
# Check build hook logs
dart run hooks/build.dart

# Inspect generated assets
ls .dart_tool/hooks_output/
```

### Native Library Issues
```bash
# Verify native library exists
ls libnative_add.*

# Check library loading
dart run bin/code_asset_example.dart
```

### Performance Analysis
```bash
# Compare JIT vs AOT performance
dart run bin/benchmark_harness_test.dart                    # JIT mode
dart run benchmark_harness:bench --flavor aot --target bin/benchmark_harness_test.dart  # AOT mode
```

## 🤝 Contributing

### Development Setup
```bash
# Install development dependencies
dart pub get

# Run tests
dart test

# Run benchmarks
dart run bin/benchmark_harness_test.dart

# Format code
dart format .
```

### Adding New Benchmarks
1. Implement algorithm in `src/` (C) and `lib/` (Dart)
2. Add benchmark classes in `lib/benchmark_harness.dart`
3. Update test suite in `bin/benchmark_harness_test.dart`

## 📄 License

This project is licensed under the MIT License. See the LICENSE file for details.

## 🔗 Related Resources

- [Dart FFI Documentation](https://dart.dev/guides/libraries/c-interop)
- [Native Assets in Dart](https://dart.dev/interop/c-interop)
- [Dart Build System](https://dart.dev/tools/build)
- [Benchmark Harness Package](https://pub.dev/packages/benchmark_harness)
