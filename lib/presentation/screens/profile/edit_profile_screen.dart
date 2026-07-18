import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database_helper.dart';
import '../../../data/services/auth_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _saving = false;
  bool _showPassSection = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider)!;
    _nameCtrl    = TextEditingController(text: user.name);
    _phoneCtrl   = TextEditingController(text: user.phone ?? '');
    _addressCtrl = TextEditingController(text: user.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose();
    _oldPassCtrl.dispose(); _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = ref.read(currentUserProvider)!;

      // Đổi mật khẩu nếu user nhập
      if (_showPassSection && _newPassCtrl.text.isNotEmpty) {
        final db = ref.read(dbProvider);
        final ok = await db.checkPassword(user.email, _oldPassCtrl.text);
        if (!ok) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mật khẩu hiện tại không đúng'), backgroundColor: Colors.red),
          );
          setState(() => _saving = false);
          return;
        }
        await db.updatePassword(user.email, _newPassCtrl.text);
      }

      await ref.read(currentUserProvider.notifier).updateUser(
        user.copyWith(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công ✓'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider)!;

    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Avatar
            Center(
              child: CircleAvatar(
                radius: 48, backgroundColor: AppTheme.primary,
                child: Text(user.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text(user.email, style: TextStyle(color: Colors.grey.shade600))),
            const SizedBox(height: 24),

            // Info fields
            const Text('Thông tin cá nhân',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Họ tên', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ giao hàng', prefixIcon: Icon(Icons.location_on_outlined),
                alignLabelWithHint: true),
            ),
            const SizedBox(height: 24),

            // Change password toggle
            GestureDetector(
              onTap: () => setState(() => _showPassSection = !_showPassSection),
              child: Row(children: [
                const Text('Đổi mật khẩu',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Icon(_showPassSection ? Icons.expand_less : Icons.expand_more),
              ]),
            ),
            if (_showPassSection) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _oldPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại', prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới', prefixIcon: Icon(Icons.lock_reset_outlined)),
                validator: (v) {
                  if (!_showPassSection || _newPassCtrl.text.isEmpty) return null;
                  if (v != null && v.length < 6) return 'Tối thiểu 6 ký tự';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Lưu thay đổi', style: TextStyle(fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
