import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tlist/page/login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    _register();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      await cred.user?.updateDisplayName(name);
      await cred.user?.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil. Cek email untuk verifikasi sebelum login.'),
          duration: Duration(seconds: 4),
        ),
      );
      // Paksa sign out sampai email terverifikasi
      await FirebaseAuth.instance.signOut();
      Navigator.pop(context); // kembali ke login
    } on FirebaseAuthException catch (e) {
      final msg = _humanizeAuthError(e.code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  String _humanizeAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'invalid-email':
        return 'Email tidak valid';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan';
      case 'weak-password':
        return 'Password terlalu lemah';
      default:
        return 'Registrasi gagal ($code)';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 80,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Buat Akun TList',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.isEmpty) return 'Nama tidak boleh kosong';
                    if (v.length < 3) return 'Nama terlalu pendek';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.isEmpty) return 'Email tidak boleh kosong';
                    final emailRegex = RegExp(r'^.+@.+\..+$');
                    if (!emailRegex.hasMatch(v)) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off),
                      tooltip: _obscurePass ? 'Tampilkan' : 'Sembunyikan',
                    ),
                  ),
                  validator: (value) {
                    final v = value ?? '';
                    if (v.isEmpty) return 'Password tidak boleh kosong';
                    if (v.length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                      tooltip: _obscureConfirm ? 'Tampilkan' : 'Sembunyikan',
                    ),
                  ),
                  validator: (value) {
                    final v = value ?? '';
                    if (v.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                    if (v != _passwordController.text) return 'Password tidak cocok';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Daftar'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun?'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
