import '../models/user_profile.dart';
import '../datasources/remote/api_service.dart';
import '../../core/errors/exceptions.dart';

class ProfileRepository {
  final ApiService _api;

  ProfileRepository(this._api);

  Future<UserProfile?> getProfile(String userId) => _api.getProfile(userId);

  Future<void> saveProfile(UserProfile profile) => _api.upsertProfile(profile);

  Future<UserProfile> updateMonthlySalary(UserProfile profile, double salary) {
    final updated = profile.copyWith(monthlySalary: salary);
    return _api.upsertProfile(updated).then((_) => updated);
  }
}

