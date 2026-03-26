import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../repositories/auth_repository.dart';
import '../models/user_profile.dart';
import '../datasources/remote/api_service.dart';
import '../repositories/profile_repository.dart';
import '../datasources/local/shared_prefs_helper.dart';
import '../datasources/remote/supabase_client.dart';
import '../../core/constants/app_constants.dart';

// Singleton repository provider
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.read(apiServiceProvider)),
);

// Auth State: watches the Supabase auth stream
final authStateProvider = StreamProvider<sb.AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return repo.authStateChanges;
});

// Current user convenience - now reactive
final currentUserProvider = Provider<sb.User?>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  return authState?.session?.user ?? SupabaseConfig.auth.currentUser;
});

// User profile
class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return null;
    final repo = ref.read(profileRepositoryProvider);
    return repo.getProfile(user.id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      if (user == null) return null;
      final repo = ref.read(profileRepositoryProvider);
      return repo.getProfile(user.id);
    });
  }

  Future<void> updateProfile(UserProfile profile) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.saveProfile(profile);
    state = AsyncData(profile);
  }

  Future<void> createDefaultProfile(
      String userId, String name, String email) async {
    final now = DateTime.now();
    final profile = UserProfile(
      id: userId,
      name: name,
      email: email,
      planType: 'trial',
      premiumUntil: now.add(const Duration(days: 7)),
      createdAt: now,
      updatedAt: now,
    );
    final repo = ref.read(profileRepositoryProvider);
    await repo.saveProfile(profile);
    state = AsyncData(profile);
    await SharedPrefsHelper.setString(
      AppConstants.keyUserName,
      profile.firstName,
    );
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile?>(
  ProfileNotifier.new,
);
