import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';

enum Role { admin, staff, pelanggan }

class AuthProvider extends ChangeNotifier {
  bool initialized = false;
  bool loading = false;
  Role? role;
  int? id;
  String nama = '';
  String email = '';
  String jabatan = '';
  String foto = '';

  bool get loggedIn => role != null;
  bool get isAdmin => role == Role.admin;
  bool get isStaff => role == Role.staff;
  bool get isPegawai => isAdmin || isStaff;
  bool get isPelanggan => role == Role.pelanggan;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    Api.token = sp.getString('token');
    final r = sp.getString('role');
    if (Api.token != null && r != null) {
      role = _parseRole(r, sp.getBool('is_admin') ?? false);
      id = sp.getInt('id');
      nama = sp.getString('nama') ?? '';
      email = sp.getString('email') ?? '';
      jabatan = sp.getString('jabatan') ?? '';
      foto = sp.getString('foto') ?? '';
    }
    initialized = true;
    notifyListeners();
  }

  static Role _parseRole(String r, bool isAdmin) {
    if (r == 'pelanggan') return Role.pelanggan;
    return isAdmin ? Role.admin : Role.staff;
  }

  Future<void> login(String email, String password) async {
    loading = true;
    notifyListeners();
    try {
      final res = await Api().post('login.php', {'email': email, 'password': password});
      final u = res['user'] as Map<String, dynamic>;
      Api.token = res['token'] as String;
      role = _parseRole('${u['role']}', u['is_admin'] == true);
      id = u['id'] as int?;
      nama = '${u['nama'] ?? ''}';
      this.email = '${u['email'] ?? ''}';
      jabatan = '${u['jabatan'] ?? ''}';
      await persist();
      notifyListeners();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await Api().post('logout.php', {});
    } catch (_) {}
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
    Api.token = null;
    role = null;
    id = null;
    nama = email = jabatan = foto = '';
    notifyListeners();
  }

  void updateFoto(String f) {
    foto = f;
    notifyListeners();
  }

  void updateProfil({String? nama, String? email}) {
    if (nama != null) this.nama = nama;
    if (email != null) this.email = email;
    notifyListeners();
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('role', isPelanggan ? 'pelanggan' : 'pegawai');
    await sp.setBool('is_admin', isAdmin);
    await sp.setInt('id', id ?? 0);
    await sp.setString('nama', nama);
    await sp.setString('email', email);
    await sp.setString('jabatan', jabatan);
    await sp.setString('foto', foto);
  }

  Future<void> _persistToken() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('token', Api.token ?? '');
  }

  Future<void> persist() async {
    await _persistToken();
    await _persist();
  }
}
