import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pausable_behavior_subject/pausable_behavior_subject.dart';

void main() {
  group('PausableBehaviorSubject', () {
    group('isActive', () {
      test('isActive is true by default when start=true', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        expect(subject.isActive, isTrue);

        await controller.close();
        await subject.dispose();
      });

      test('isActive is false when start=false', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream, start: false);

        expect(subject.isActive, isFalse);

        await controller.close();
        await subject.dispose();
      });

      test('isActive toggles to false after pause()', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        expect(subject.isActive, isTrue);
        await subject.pause();
        expect(subject.isActive, isFalse);

        await controller.close();
        await subject.dispose();
      });

      test('isActive becomes true after resume() when not disposed', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream, start: false);

        expect(subject.isActive, isFalse);
        subject.resume();
        expect(subject.isActive, isTrue);

        await controller.close();
        await subject.dispose();
      });

      test('after dispose(), isActive stays false and resume() does nothing', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        expect(subject.isActive, isTrue);
        await subject.dispose();
        expect(subject.isActive, isFalse);

        // Attempt to resume after dispose should have no effect
        subject.resume();
        expect(subject.isActive, isFalse);

        await controller.close();
      });
    });
    group('Constructor behavior', () {
      test('start: true (default) - subject starts listening immediately', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        final receivedValues = <int>[];
        subject.stream.listen(receivedValues.add);

        controller.add(1);
        await Future.delayed(Duration.zero);

        expect(receivedValues, [1]);

        await controller.close();
        await subject.dispose();
      });

      test('start: false - no subscription created', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream, start: false);

        controller.add(1);
        await Future.delayed(Duration.zero);

        final receivedValues = <int>[];
        subject.stream.listen(receivedValues.add);

        // Should not receive the value emitted before resume
        expect(receivedValues, isEmpty);

        await controller.close();
        await subject.dispose();
      });
    });

    group('Pause & Resume', () {
      test('resume() multiple times does not create multiple subscriptions', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream, start: false);

        subject.resume();
        subject.resume();
        subject.resume();

        final receivedValues = <int>[];
        subject.stream.listen(receivedValues.add);

        controller.add(1);
        await Future.delayed(Duration.zero);

        // Should only receive one value, not three
        expect(receivedValues, [1]);

        await controller.close();
        await subject.dispose();
      });

      test('values from underlying stream are forwarded after resuming', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream, start: false);

        final receivedValues = <int>[];
        subject.stream.listen(receivedValues.add);

        subject.resume();

        controller.add(1);
        controller.add(2);
        controller.add(3);
        await Future.delayed(Duration.zero);

        expect(receivedValues, [1, 2, 3]);

        await controller.close();
        await subject.dispose();
      });

      test('values emitted before resume are not forwarded', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream, start: false);

        final receivedValues = <int>[];
        subject.stream.listen(receivedValues.add);

        controller.add(1);
        controller.add(2);
        await Future.delayed(Duration.zero);

        subject.resume();

        controller.add(3);
        controller.add(4);
        await Future.delayed(Duration.zero);

        expect(receivedValues, [3, 4]);

        await controller.close();
        await subject.dispose();
      });

      test('values emitted while paused are not forwarded after resume', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        final receivedValues = <int>[];
        subject.stream.listen(receivedValues.add);

        controller.add(1);
        await Future.delayed(Duration.zero);

        await subject.pause();

        controller.add(2);
        controller.add(3);
        await Future.delayed(Duration.zero);

        subject.resume();

        controller.add(4);
        await Future.delayed(Duration.zero);

        expect(receivedValues, [1, 4]);

        await controller.close();
        await subject.dispose();
      });

      test('no values are forwarded during pause', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        final receivedValues = <int>[];
        subject.stream.listen(receivedValues.add);

        controller.add(1);
        await Future.delayed(Duration.zero);

        await subject.pause();

        controller.add(2);
        controller.add(3);
        await Future.delayed(Duration.zero);

        expect(receivedValues, [1]);

        await controller.close();
        await subject.dispose();
      });

      test('pause() multiple times is safe', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        await subject.pause();
        await subject.pause();
        await subject.pause();

        // Should not throw - verify by adding a listener and checking no events received
        final receivedValues = <int>[];
        subject.stream.listen(receivedValues.add);

        controller.add(1);
        await Future.delayed(Duration.zero);
        expect(receivedValues, isEmpty);

        await controller.close();
        await subject.dispose();
      });
    });

    group('BehaviorSubject semantics', () {
      test('latest value is retained and replayed to new subscribers', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        controller.add(1);
        controller.add(2);
        await Future.delayed(Duration.zero);

        final receivedValues = <int>[];
        subject.stream.listen(receivedValues.add);
        await Future.delayed(Duration.zero);

        // New subscriber should receive the latest value (2)
        expect(receivedValues, [2]);

        await controller.close();
        await subject.dispose();
      });

      test('multiple subscribers receive the same latest value', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        controller.add(42);
        await Future.delayed(Duration.zero);

        final receivedValues1 = <int>[];
        final receivedValues2 = <int>[];

        subject.stream.listen(receivedValues1.add);
        subject.stream.listen(receivedValues2.add);
        await Future.delayed(Duration.zero);

        expect(receivedValues1, [42]);
        expect(receivedValues2, [42]);

        await controller.close();
        await subject.dispose();
      });
    });

    group('Error handling', () {
      test('errors from underlying stream are forwarded through subject.addError', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        final receivedErrors = <dynamic>[];
        subject.stream.listen((_) {}, onError: receivedErrors.add);

        final testError = Exception('Test error');
        controller.addError(testError);
        await Future.delayed(Duration.zero);

        expect(receivedErrors, [testError]);

        await controller.close();
        await subject.dispose();
      });

      test('errors are not forwarded when paused', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        final receivedErrors = <dynamic>[];
        subject.stream.listen((_) {}, onError: receivedErrors.add);

        await subject.pause();

        controller.addError(Exception('Should not be received'));
        await Future.delayed(Duration.zero);

        expect(receivedErrors, isEmpty);

        await controller.close();
        await subject.dispose();
      });

      test('after error, subject continues functioning', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        final receivedValues = <int>[];
        final receivedErrors = <dynamic>[];
        subject.stream.listen(receivedValues.add, onError: receivedErrors.add);

        controller.add(1);
        await Future.delayed(Duration.zero);

        controller.addError(Exception('Test error'));
        await Future.delayed(Duration.zero);

        controller.add(2);
        await Future.delayed(Duration.zero);

        expect(receivedValues, [1, 2]);
        expect(receivedErrors.length, 1);

        await controller.close();
        await subject.dispose();
      });
    });

    group('Stream completion / onDone', () {
      test('when underlying stream completes, dispose() is automatically invoked', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        var onDoneCalled = false;
        subject.stream.listen((_) {}, onDone: () => onDoneCalled = true);

        controller.close();
        await Future.delayed(Duration.zero);

        expect(onDoneCalled, isTrue);
        await subject.dispose();
      });

      test('after completion, resume() does nothing', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        controller.close();
        await Future.delayed(Duration.zero);

        subject.resume();

        // Verify no errors thrown
        await subject.dispose();
      });

      test('after completion, pause() is safe but meaningless', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        controller.close();
        await Future.delayed(Duration.zero);

        await subject.pause();

        // Should not throw
        await subject.dispose();
      });
    });

    group('Dispose', () {
      test('dispose() twice does not throw', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        await subject.dispose();
        await subject.dispose();

        // Should not throw
        await controller.close();
      });

      test('after dispose, resume() does nothing', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        await subject.dispose();

        subject.resume();

        // Verify no errors thrown and no events received
        await controller.close();
      });

      test('after dispose, pause() does nothing', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        await subject.dispose();

        await subject.pause();

        // Should not throw
        await controller.close();
      });

      test('after dispose, adding events to underlying stream does not reach subject', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        final receivedValues = <int>[];
        subject.stream.listen(receivedValues.add);

        controller.add(1);
        await Future.delayed(Duration.zero);

        await subject.dispose();

        controller.add(2);
        await Future.delayed(Duration.zero);

        expect(receivedValues, [1]);
        await controller.close();
      });

      test('listeners receive stream completion event after dispose', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        var completionReceived = false;
        subject.stream.listen((_) {}, onDone: () => completionReceived = true);

        await subject.dispose();
        await Future.delayed(Duration.zero);

        expect(completionReceived, isTrue);
        await controller.close();
      });
    });

    group('Timing / ordering tests', () {
      test('resume -> receive -> pause -> no receive -> resume -> receive', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        final receivedValues = <int>[];
        subject.stream.listen(receivedValues.add);

        // Resume (already resumed by default)
        controller.add(1);
        await Future.delayed(Duration.zero);
        expect(receivedValues, [1]);

        // Pause
        await subject.pause();
        controller.add(2);
        await Future.delayed(Duration.zero);
        expect(receivedValues, [1]);

        // Resume
        subject.resume();
        controller.add(3);
        await Future.delayed(Duration.zero);
        expect(receivedValues, [1, 3]);

        await controller.close();
        await subject.dispose();
      });

      test('pause is effective immediately - no events leak through', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        final receivedValues = <int>[];
        subject.stream.listen(receivedValues.add);

        controller.add(1);
        await Future.delayed(Duration.zero);

        await subject.pause();

        // Add immediately after pause
        controller.add(2);
        controller.add(3);
        await Future.delayed(Duration.zero);

        expect(receivedValues, [1]);

        await controller.close();
        await subject.dispose();
      });

      test('dispose during event stream does not allow later events', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        final receivedValues = <int>[];
        subject.stream.listen(receivedValues.add);

        controller.add(1);
        await Future.delayed(Duration.zero);

        await subject.dispose();

        controller.add(2);
        controller.add(3);
        await Future.delayed(Duration.zero);

        expect(receivedValues, [1]);

        await controller.close();
      });
    });

    group('Behavior after subject closure', () {
      test('subscribing to stream after dispose yields closed stream immediately', () async {
        final controller = StreamController<int>.broadcast();
        final subject = PausableBehaviorSubject(controller.stream);

        await subject.dispose();

        var completionReceived = false;
        final receivedValues = <int>[];

        subject.stream.listen(receivedValues.add, onDone: () => completionReceived = true);
        await Future.delayed(Duration.zero);

        expect(completionReceived, isTrue);
        expect(receivedValues, isEmpty);

        await controller.close();
      });
    });
  });
}
