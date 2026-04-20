import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLogin = true;
  bool _isSmsLogin = true;
  bool _isLoading = false;
  String? _errorMessage;
  int _countdown = 0;
  Timer? _timer;

  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Forgot password dialog controllers
  final _fpPhoneController = TextEditingController();
  final _fpCodeController = TextEditingController();
  final _fpPasswordController = TextEditingController();
  final _fpConfirmPasswordController = TextEditingController();
  int _fpCountdown = 0;
  Timer? _fpTimer;

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fpPhoneController.dispose();
    _fpCodeController.dispose();
    _fpPasswordController.dispose();
    _fpConfirmPasswordController.dispose();
    _timer?.cancel();
    _fpTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendCode(String purpose) async {
    if (_countdown > 0) return;
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length != 11) {
      setState(() => _errorMessage = '请输入正确的手机号');
      return;
    }
    try {
      await ref.read(authProvider.notifier).sendCode(phone, purpose);
      setState(() {
        _countdown = 60;
        _errorMessage = null;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() => _countdown--);
        if (_countdown <= 0) t.cancel();
      });
    } catch (e) {
      setState(() => _errorMessage = '发送验证码失败');
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool success;
    if (_isLogin) {
      if (_isSmsLogin) {
        // SMS login
        final phone = _phoneController.text.trim();
        final code = _codeController.text.trim();
        if (phone.isEmpty || phone.length != 11) {
          setState(() { _isLoading = false; _errorMessage = '请输入正确的手机号'; });
          return;
        }
        if (code.isEmpty) {
          setState(() { _isLoading = false; _errorMessage = '请输入验证码'; });
          return;
        }
        success = await ref.read(authProvider.notifier).loginWithPhone(phone, code);
      } else {
        // Password login
        final username = _usernameController.text.trim();
        final password = _passwordController.text;
        if (username.isEmpty) {
          setState(() { _isLoading = false; _errorMessage = '请输入用户名或手机号'; });
          return;
        }
        if (password.isEmpty) {
          setState(() { _isLoading = false; _errorMessage = '请输入密码'; });
          return;
        }
        success = await ref.read(authProvider.notifier).login(username, password);
      }
      if (!success) {
        setState(() {
          _isLoading = false;
          _errorMessage = _isSmsLogin ? '登录失败，请检查手机号和验证码' : '登录失败，请检查用户名和密码';
        });
      }
    } else {
      // Register
      final username = _usernameController.text.trim();
      final phone = _phoneController.text.trim();
      final code = _codeController.text.trim();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (username.isEmpty) {
        setState(() { _isLoading = false; _errorMessage = '请输入用户名'; });
        return;
      }
      if (phone.isEmpty || phone.length != 11) {
        setState(() { _isLoading = false; _errorMessage = '请输入正确的手机号'; });
        return;
      }
      if (code.isEmpty) {
        setState(() { _isLoading = false; _errorMessage = '请输入验证码'; });
        return;
      }
      if (password.isEmpty || password.length < 6) {
        setState(() { _isLoading = false; _errorMessage = '密码至少6位'; });
        return;
      }
      if (password != confirmPassword) {
        setState(() { _isLoading = false; _errorMessage = '两次密码输入不一致'; });
        return;
      }

      success = await ref.read(authProvider.notifier).registerWithPhone(
            username,
            phone,
            code,
            password,
          );
      if (!success) {
        setState(() {
          _isLoading = false;
          _errorMessage = '注册失败，用户名或手机号可能已存在';
        });
      }
    }

    if (success && mounted) {
      context.go('/');
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    _fpPhoneController.clear();
    _fpCodeController.clear();
    _fpPasswordController.clear();
    _fpConfirmPasswordController.clear();

    String? dialogError;
    bool dialogLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('重置密码'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Phone
                    TextField(
                      controller: _fpPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '手机号',
                        prefixText: '+86 ',
                        prefixIcon: Icon(Icons.phone_android),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Code + send button
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _fpCodeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '验证码',
                              prefixIcon: Icon(Icons.sms),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 110,
                          child: ElevatedButton(
                            onPressed: _fpCountdown > 0
                                ? null
                                : () async {
                                    final phone = _fpPhoneController.text.trim();
                                    if (phone.isEmpty || phone.length != 11) {
                                      setDialogState(() => dialogError = '请输入正确的手机号');
                                      return;
                                    }
                                    try {
                                      await ref.read(authProvider.notifier).sendCode(phone, 'reset_password');
                                      setDialogState(() {
                                        _fpCountdown = 60;
                                        dialogError = null;
                                      });
                                      _fpTimer?.cancel();
                                      _fpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
                                        setDialogState(() => _fpCountdown--);
                                        if (_fpCountdown <= 0) t.cancel();
                                      });
                                    } catch (e) {
                                      setDialogState(() => dialogError = '发送验证码失败');
                                    }
                                  },
                            child: Text(
                              _fpCountdown > 0 ? '${_fpCountdown}s' : '获取验证码',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // New password
                    TextField(
                      controller: _fpPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '新密码',
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Confirm password
                    TextField(
                      controller: _fpConfirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '确认密码',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          dialogError!,
                          style: const TextStyle(color: AppTheme.accentColor, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: dialogLoading
                      ? null
                      : () async {
                          final phone = _fpPhoneController.text.trim();
                          final code = _fpCodeController.text.trim();
                          final newPwd = _fpPasswordController.text;
                          final confirmPwd = _fpConfirmPasswordController.text;

                          if (phone.isEmpty || phone.length != 11) {
                            setDialogState(() => dialogError = '请输入正确的手机号');
                            return;
                          }
                          if (code.isEmpty) {
                            setDialogState(() => dialogError = '请输入验证码');
                            return;
                          }
                          if (newPwd.isEmpty || newPwd.length < 6) {
                            setDialogState(() => dialogError = '密码至少6位');
                            return;
                          }
                          if (newPwd != confirmPwd) {
                            setDialogState(() => dialogError = '两次密码输入不一致');
                            return;
                          }

                          setDialogState(() { dialogLoading = true; dialogError = null; });

                          final success = await ref.read(authProvider.notifier).resetPassword(phone, code, newPwd);
                          if (success && dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('密码重置成功，请使用新密码登录')),
                            );
                          } else {
                            setDialogState(() {
                              dialogLoading = false;
                              dialogError = '重置失败，请检查验证码是否正确';
                            });
                          }
                        },
                  child: dialogLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('重置'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and app name
                  Icon(Icons.restaurant_menu, size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    '🍳 智能厨房助手',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Top toggle: login / register
                  _buildTopToggle(),
                  const SizedBox(height: 24),

                  if (_isLogin) ...[
                    // Login mode tabs: SMS / Password
                    _buildLoginModeTabs(),
                    const SizedBox(height: 20),

                    if (_isSmsLogin)
                      _buildSmsLoginForm()
                    else
                      _buildPasswordLoginForm(),
                  ] else ...[
                    _buildRegisterForm(),
                  ],

                  const SizedBox(height: 16),

                  // Error message
                  if (_errorMessage != null) _buildErrorBox(),

                  const SizedBox(height: 16),

                  // Submit button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Top Toggle (segmented control style) ----------

  Widget _buildTopToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildToggleItem('登录', _isLogin, () {
            setState(() {
              _isLogin = true;
              _errorMessage = null;
            });
          }),
          _buildToggleItem('注册', !_isLogin, () {
            setState(() {
              _isLogin = false;
              _errorMessage = null;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Login Mode Tabs (underline style) ----------

  Widget _buildLoginModeTabs() {
    return Row(
      children: [
        _buildUnderlineTab('验证码登录', _isSmsLogin, () {
          setState(() {
            _isSmsLogin = true;
            _errorMessage = null;
          });
        }),
        const SizedBox(width: 24),
        _buildUnderlineTab('密码登录', !_isSmsLogin, () {
          setState(() {
            _isSmsLogin = false;
            _errorMessage = null;
          });
        }),
      ],
    );
  }

  Widget _buildUnderlineTab(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? Theme.of(context).colorScheme.primary : AppTheme.secondaryTextColor,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 60,
            decoration: BoxDecoration(
              color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- SMS Login Form ----------

  Widget _buildSmsLoginForm() {
    return Column(
      children: [
        // Phone input
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: '手机号',
            prefixText: '+86 ',
            prefixIcon: Icon(Icons.phone_android),
          ),
        ),
        const SizedBox(height: 16),
        // Code input + send code button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '验证码',
                  prefixIcon: Icon(Icons.sms),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _countdown > 0 ? null : () => _sendCode('login'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  _countdown > 0 ? '${_countdown}s' : '获取验证码',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------- Password Login Form ----------

  Widget _buildPasswordLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: '用户名/手机号',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '密码',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        const SizedBox(height: 8),
        // Forgot password link
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _showForgotPasswordDialog,
            child: Text(
              '忘记密码?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Register Form ----------

  Widget _buildRegisterForm() {
    return Column(
      children: [
        // Username
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: '用户名',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        // Phone
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: '手机号',
            prefixText: '+86 ',
            prefixIcon: Icon(Icons.phone_android),
          ),
        ),
        const SizedBox(height: 16),
        // Code + send button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '验证码',
                  prefixIcon: Icon(Icons.sms),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _countdown > 0 ? null : () => _sendCode('register'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  _countdown > 0 ? '${_countdown}s' : '获取验证码',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Password
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '密码',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        const SizedBox(height: 16),
        // Confirm password
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '确认密码',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
      ],
    );
  }

  // ---------- Error Box ----------

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: AppTheme.accentColor),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ---------- Submit Button ----------

  Widget _buildSubmitButton() {
    final String label;
    if (_isLogin) {
      label = '登录';
    } else {
      label = '注册';
    }

    return ElevatedButton(
      onPressed: _isLoading ? null : _submit,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
