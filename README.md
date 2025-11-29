# PausableBehaviorSubject

[![Version](https://img.shields.io/pub/v/pausable_behavior_subject.svg)](https://pub.dev/packages/pausable_behavior_subject) ![GitHub license](https://img.shields.io/badge/license-BSD3-blue.svg?style=flat)

### A package that provides a way to pause and resume event emissions for streams that do not natively support it.

## Usage

`PausableBehaviorSubject` behaves similarly to the [`BehaviorSubject`](https://pub.dev/documentation/rxdart/latest/rx/BehaviorSubject-class.html) from [`rxdart`](https://pub.dev/packages/rxdart), since it is in fact using that. The only difference is that it wraps a stream which is the source of events instead of you adding them to its sink. It allows pausing & resuming receiving new events from the source stream with the last item retained even when paused.

This is useful for e.g. bluetooth notifications, connectivity changes, sensor streams, Firestore snapshots and etc, basically when the stream of events is provided to you and you do not have full control at the source of events.

```dart
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

  print(receivedValues.toString()); // Should print: [1]

  await controller.close(); // Closes the subject as well
  await subject.dispose(); // In case you don't have control over the source stream, you can simply dispose of the subject only
}
```

## Parameters

| Parameter | Description                                                                                |
| --------- | ------------------------------------------------------------------------------------------ |
| `_stream` | The source stream of type `Stream<T>` for the subject. First and only positional parameter |
| `start`   | Whether to start listening to the source stream immediately or not. Defaults to true.      |

## License

```
Copyright 2025 Norbert Csörgő

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
