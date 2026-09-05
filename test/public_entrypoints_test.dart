import 'package:carpenter/application.dart' as application;
import 'package:carpenter/collections.dart' as collections;
import 'package:carpenter/components.dart' as components;
import 'package:carpenter/foundation.dart' as foundation;
import 'package:carpenter/layout.dart' as layout;
import 'package:carpenter/patterns.dart' as patterns;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('focused entrypoints expose their intended layers', () {
    const feedback = components.CarpenterFieldFeedback.info('Saved');
    final loading = components.LoadingNotifier();
    final selection = collections.CollectionSelection<int>.multiple();
    final command = application.CarpenterCommandController<void>(
      id: 'save',
      title: 'Save',
    );
    addTearDown(loading.close);
    addTearDown(command.dispose);

    expect(foundation.CarpenterDensity.compact, isNotNull);
    expect(feedback.role, foundation.FeedbackColorRole.info);
    expect(loading.state.isLoading, isFalse);
    expect(selection.mode, collections.CollectionSelectionMode.multiple);
    expect(layout.CarpenterPageHeader, isNotNull);
    expect(patterns.CarpenterPage, isNotNull);
    expect(command.title, 'Save');
  });

  test('higher entrypoints include lower public layers', () {
    expect(collections.CarpenterButton, isNotNull);
    expect(layout.CarpenterTable, isNotNull);
    expect(patterns.CarpenterRootLayout, isNotNull);
    expect(application.CarpenterFieldShell, isNotNull);
  });
}
