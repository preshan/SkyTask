import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dialog TextEditingController survives typing until Add',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await showDialog<String>(
                    context: context,
                    builder: (ctx) => const _OwnedControllerDialog(),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('New category'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Health');
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('New category'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _OwnedControllerDialog extends StatefulWidget {
  const _OwnedControllerDialog();

  @override
  State<_OwnedControllerDialog> createState() => _OwnedControllerDialogState();
}

class _OwnedControllerDialogState extends State<_OwnedControllerDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New category'),
      content: TextField(controller: _controller),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
