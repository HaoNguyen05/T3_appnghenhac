import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  User? _user;
  UserProfile? _userProfile;

  AuthService() {
    _user = _client.auth.currentUser;

    _client.auth.onAuthStateChange.listen((event) {
      _user = event.session?.user ?? _client.auth.currentUser;
      notifyListeners();
    });
  }

  User? get user => _user;
  String? get userId => _user?.id;
  bool get isAuthenticated => _user != null;
  UserProfile? get userProfile => _userProfile;
  Future<void> signUp(
    String email,
    String password, {
    required String name,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
      },
    );

    if (res.user == null) {
      throw Exception('Sign up failed');
    }
  }

  Future<void> signIn(String email, String password) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (res.session == null) {
      throw Exception('Login failed');
    }

    _user = res.session!.user;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_user == null) return null;

    return await _client
        .from('users')
        .select()
        .eq('id', _user!.id)
        .maybeSingle();
  }

  Future<UserProfile?> getUserProfileAsModel() async {
    final map = await getUserProfile();
    if (map == null) return null;
    _userProfile = UserProfile.fromMap(map);
    return _userProfile;
  }

  void updateUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }

  Future<bool> isAdmin() async {
    if (_user == null) return false;

    final res = await _client
        .from('users')
        .select('user_role')
        .eq('id', _user!.id)
        .single();

    return res['user_role'] == 'admin';
  }
}
