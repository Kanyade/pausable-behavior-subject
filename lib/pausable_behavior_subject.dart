import 'dart:async';

import 'package:rxdart/rxdart.dart';

/// A BehaviorSubject that based on an underlying stream which cannot be paused and resumed,
/// but this class provides pause and resume functionality by managing the subscription and
/// the last value.
class PausableBehaviorSubject<T> {
  PausableBehaviorSubject(
    this._stream, {

    /// Whether to start listening to the underlying stream immediately.
    bool start = true,
  }) {
    if (start) {
      resume();
    }
  }

  final Stream<T> _stream;
  final BehaviorSubject<T> _subject = BehaviorSubject<T>();

  StreamSubscription<T>? _subscription;
  bool _isDisposed = false;

  /// The stream of values emitted by the underlying stream until this subject is paused.
  Stream<T> get stream => _subject.stream;

  /// Resume listening to the underlying stream, skipping any values emitted while paused.
  void resume() {
    if (_isDisposed) return;
    _subscription ??= _stream.listen(
      _subject.add,
      onError: _subject.addError,
      onDone: dispose,
    );
  }

  /// Pause listening to the underlying stream. The last emitted value is retained.
  Future<void> pause() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Dispose the subject and release all resources.
  Future<void> dispose() async {
    _isDisposed = true;
    await pause();
    await _subject.close();
  }
}
