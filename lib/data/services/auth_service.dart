import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../local/database_helper.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dbProvider));
});

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, UserModel?>((ref) {
  return CurrentUserNotifier(ref.watch(authServiceProvider));
});

class CurrentUserNotifier extends StateNotifier<UserModel?> {
  final AuthService _auth;
  CurrentUserNotifier(this._auth) : super(null) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid != null) {
      final user = await _auth.getUserById(uid);
      state = user;
    }
  }

  Future<void> login(String email, String password) async {
    final user = await _auth.login(email: email, password: password);
    state = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', user.id);
  }

  Future<void> register(
      String email, String password, String name) async {
    final user =
        await _auth.register(email: email, password: password, name: name);
    state = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', user.id);
  }

  Future<void> logout() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
  }

  Future<void> updateUser(UserModel user) async {
    await _auth.updateUser(user);
    state = user;
  }
}

class AuthService {
  final DatabaseHelper _db;
  AuthService(this._db);

  Future<UserModel> login(
      {required String email, required String password}) async {
    final ok = await _db.checkPassword(email, password);
    if (!ok) throw Exception('Email hoặc mật khẩu không đúng');
    final user = await _db.getUserByEmail(email);
    if (user!.isLocked) throw Exception('Tài khoản đã bị khóa. Vui lòng liên hệ admin.');
    return user;
  }

  Future<UserModel> register(
      {required String email,
      required String password,
      required String name}) async {
    final existing = await _db.getUserByEmail(email);
    if (existing != null) throw Exception('Email đã được sử dụng');
    final user = UserModel(
      id: const Uuid().v4(),
      email: email,
      name: name,
    );
    await _db.insertUser(user, password);
    return user;
  }

  Future<UserModel?> getUserById(String id) => _db.getUserById(id);

  Future<void> updateUser(UserModel user) => _db.updateUser(user);
}
