import 'package:flutter/material.dart';
import 'package:fancy_counter/fancy_counter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Fancy Counter Example',
      home: CounterExamplePage(),
    );
  }
}

class CounterExamplePage extends StatefulWidget {
  const CounterExamplePage({super.key});

  @override
  _CounterExamplePageState createState() => _CounterExamplePageState();
}

class _CounterExamplePageState extends State<CounterExamplePage> {
  // Start at 100.0 to better see the animation
  double _counter = 100.0;

  void _incrementCounter() {
    setState(() {
      _counter += 150.75;
    });
  }

  void _decrementCounter() {
    setState(() {
      _counter -= 150.75;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Fancy Counter Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- 1. AnimatedTextCounter Widget ---
            AnimatedTextCounter(
              value: _counter,
              duration: const Duration(milliseconds: 500),
              style: textTheme.headlineMedium,
              prefix: '₺',
              fractionDigits: 2,
              increaseColor: Colors.green,
              decreaseColor: Colors.red,
              animateOnFirstBuild: true,
              postfix: ' TRY',
              curve: Curves.easeInCubic,
            ),

            const SizedBox(height: 40),

            // --- 2. FlipCounter Widget ---
            FlipCounter(
              value: _counter,
              duration: const Duration(milliseconds: 500),
              style: textTheme.headlineMedium,
              prefix: '\$',
              fractionDigits: 2,
              increaseColor: Colors.blue,
              decreaseColor: Colors.orange,
              animateOnFirstBuild: false,
              postfix: ' USD',
              curve: Curves.easeInCubic,
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 10,
        children: [
          FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            onPressed: _decrementCounter,
            tooltip: 'Decrement',
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
