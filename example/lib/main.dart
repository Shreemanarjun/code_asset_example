import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final String _fibonacciResult = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadFibonacci();
  }

  void _loadFibonacci() {
    // final fib = _example.generateFibonacci(10);
    // setState(() {
    //   _fibonacciResult = fib?.join(', ') ?? 'Error generating Fibonacci';
    // });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Hello World!'),
              const SizedBox(height: 20),
              Text('Fibonacci (10): $_fibonacciResult'),
            ],
          ),
        ),
      ),
    );
  }
}
