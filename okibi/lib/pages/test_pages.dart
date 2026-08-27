import 'package:flutter/widgets.dart';

/// Empty page used to verify the first application route.
final class FirstTestPage extends StatelessWidget {
  const FirstTestPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.expand(child: Text("1"),);
}

/// Empty page used to verify the second application route.
final class SecondTestPage extends StatelessWidget {
  const SecondTestPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.expand(child: Text("2"),);
}
