import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';

final authStateProvider = StreamProvider<UserModel?>((ref) {
  // Since AuthRepository uses GetX Rx, we can't directly use it as a stream
  // unless we convert it or use the underlying Firebase stream.
  // For now, let's create a stream that yields the current profile whenever it changes.

  // We'll use a simple proxy to the Rx value for now,
  // but ideally AuthRepository should provide a Stream.
  return AuthRepository.instance.userRx.stream.asyncMap(
    (_) => AuthRepository.instance.currentUserProfile,
  );
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).value ??
      AuthRepository.instance.currentUserProfile;
});
