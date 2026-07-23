import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/common/premium_button.dart';
import '../../widgets/common/premium_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'demo@gmail.com');
  final _pass = TextEditingController(text: '123456');
  bool _loading = false, _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(currentUserProvider.notifier).login(_email.text.trim(), _pass.text);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s3),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 64),
                // Logo or Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: DesignTokens.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.borderRadiusXL),
                    ),
                    child: const Icon(LucideIcons.cpu, size: 48, color: DesignTokens.primary),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Chào mừng trở lại',
                  textAlign: TextAlign.center,
                  style: DesignTokens.h2,
                ),
                const SizedBox(height: 8),
                Text(
                  'Đăng nhập để tiếp tục mua sắm linh kiện',
                  textAlign: TextAlign.center,
                  style: DesignTokens.bodySmall,
                ),
                const SizedBox(height: 48),
                PremiumTextField(
                  label: 'Email',
                  hintText: 'Nhập email của bạn',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(LucideIcons.mail, size: 20, color: DesignTokens.textSecondary),
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập email' : null,
                ),
                const SizedBox(height: 20),
                PremiumTextField(
                  label: 'Mật khẩu',
                  hintText: 'Nhập mật khẩu',
                  controller: _pass,
                  obscureText: _obscure,
                  prefixIcon: const Icon(LucideIcons.lock, size: 20, color: DesignTokens.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 20, color: DesignTokens.textSecondary),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => v!.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DesignTokens.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.borderRadiusS),
                      border: Border.all(color: DesignTokens.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 18, color: DesignTokens.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!, style: DesignTokens.bodySmall.copyWith(color: DesignTokens.danger)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                PremiumButton(
                  text: 'Đăng nhập',
                  onPressed: _login,
                  isLoading: _loading,
                ),
                const SizedBox(height: 24),
                // Demo accounts info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DesignTokens.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(DesignTokens.borderRadiusM),
                    border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tài khoản dùng thử:',
                        style: DesignTokens.bodySmall.copyWith(fontWeight: FontWeight.w600, color: DesignTokens.primary),
                      ),
                      const SizedBox(height: 4),
                      Text('User: demo@gmail.com / 123456', style: DesignTokens.bodySmall),
                      Text('Admin: admin@gmail.com / 123456', style: DesignTokens.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Chưa có tài khoản?', style: DesignTokens.bodySmall),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: Text(
                        'Đăng ký ngay',
                        style: DesignTokens.bodySmall.copyWith(
                          color: DesignTokens.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
