import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text('$title - Coming Soon!',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketScannerScreen extends StatelessWidget {
  const MarketScannerScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Market Scanner');
}

class OptimizerScreen extends StatelessWidget {
  const OptimizerScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Strategy Optimizer');
}
