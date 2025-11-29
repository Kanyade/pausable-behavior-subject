import 'dart:async';

import 'package:pausable_behavior_subject/pausable_behavior_subject.dart';

Future<void> main() async {
  final controller = StreamController<int>.broadcast();
  final subject = PausableBehaviorSubject<int>(controller.stream);

  final receivedValues = <int>[];
  subject.stream.listen(receivedValues.add);

  controller.add(1);
  await Future.delayed(Duration.zero);

  await subject.pause();

  controller.add(2);
  controller.add(3);
  await Future.delayed(Duration.zero);

  // ignore: avoid_print
  print(receivedValues.toString()); // Should print: [1]

  // Closes the subject as well
  await controller.close();

  // In case you don't have control over the source stream, you can simply dispose of the subject only
  await subject.dispose();
}
