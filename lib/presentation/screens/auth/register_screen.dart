import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/common/premium_button.dart';
import '../../widgets/common/premium_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false, _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(currentUserProvider.notifier).register(_email.text.trim(), _pass.text, _name.text.trim());
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
      appBar: AppBar(
        title: const Text('Tạo tài khoản'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s3),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: DesignTokens.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.borderRadiusXL),
                    ),
                    child: const Icon(LucideIcons.userPlus, size: 48, color: DesignTokens.primary),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Bắt đầu hành trình',
                  textAlign: TextAlign.center,
                  style: DesignTokens.h2,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tạo tài khoản để trải nghiệm dịch vụ tốt nhất',
                  textAlign: TextAlign.center,
                  style: DesignTokens.bodySmall,
                ),
                const SizedBox(height: 40),
                PremiumTextField(
                  label: 'Họ và tên',
                  hintText: 'Nhập họ và tên',
                  controller: _name,
                  prefixIcon: const Icon(LucideIcons.user, size: 20, color: DesignTokens.textSecondary),
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập họ tên' : null,
                ),
                const SizedBox(height: 20),
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
                  hintText: 'Tối thiểu 6 ký tự',
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
                const SizedBox(height: 40),
                PremiumButton(
                  text: 'Đăng ký ngay',
                  onPressed: _register,
                  isLoading: _loading,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Đã có tài khoản?', style: DesignTokens.bodySmall),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Đăng nhập',
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
