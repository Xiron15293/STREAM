import '../models/profile.dart';

abstract class ProfilesController {
  List<Profile> get profiles;
  Profile? get activeProfile;
  String? get activeProfileId;

  Future<List<Profile>> loadProfiles();
  Future<Profile> createProfile(String name);
  Future<void> switchProfile(String profileId);
  Future<void> renameProfile(String profileId, String name);
  Future<void> deleteProfile(String profileId);
  Future<String> getDatabasePath(Profile profile);
}
