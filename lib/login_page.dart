import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _emailOrUsernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupUsernameController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();

  bool _isLoading = false;

  // 로그인 로직
  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final input = _emailOrUsernameController.text.trim();
      final password = _passwordController.text;

      if (input.isEmpty || password.isEmpty) {
        _showSnackBar('아이디와 비밀번호를 입력해주세요.');
        return;
      }

      String targetEmail = input;

      // 아이디로 로그인 시도 시 이메일 찾기
      if (!input.contains('@')) {
        final data = await supabase
            .from('profiles')
            .select('email')
            .eq('username', input)
            .maybeSingle(); // 데이터가 없으면 null 반환

        if (data == null) {
          _showSnackBar('존재하지 않는 아이디입니다.');
          return;
        }
        targetEmail = data['email'] as String;
      }

      await supabase.auth.signInWithPassword(email: targetEmail, password: password);
    } catch (e) {
      _showSnackBar('로그인 실패: 아이디 또는 비밀번호를 확인하세요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 회원가입 로직 (username 저장 보장)
  Future<void> _signup() async {
    final email = _signupEmailController.text.trim();
    final username = _signupUsernameController.text.trim();
    final password = _signupPasswordController.text;

    if (email.isEmpty || username.isEmpty || password.length < 6) {
      _showSnackBar('모든 항목을 올바르게 입력해주세요 (비밀번호 6자 이상).');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Auth 회원가입
      final res = await supabase.auth.signUp(email: email, password: password);
      final user = res.user;

      if (user != null) {
        // 2. profiles 테이블에 즉시 저장
        await supabase.from('profiles').upsert({
          'user_id': user.id,
          'username': username,
          'email': email,
        });
        
        _showSnackBar('회원가입 성공! 로그인해 주세요.');
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('회원가입 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // UI 부분 (회원가입 팝업 포함)
  void _showSignupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원가입'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _signupEmailController, decoration: const InputDecoration(labelText: '이메일')),
            TextField(controller: _signupUsernameController, decoration: const InputDecoration(labelText: '사용할 아이디')),
            TextField(controller: _signupPasswordController, obscureText: true, decoration: const InputDecoration(labelText: '비밀번호')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          FilledButton(onPressed: _signup, child: const Text('가입하기')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Weet', style: TextStyle(fontSize: 32, color: Color(0xFF5C6AC4), fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(controller: _emailOrUsernameController, decoration: const InputDecoration(labelText: '아이디 또는 이메일', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: '비밀번호', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: _isLoading ? null : _login, child: const Text('로그인'))),
            TextButton(onPressed: _showSignupDialog, child: const Text('회원가입 하기')),
          ],
        ),
      ),
    );
  }
}