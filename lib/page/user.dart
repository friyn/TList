import 'package:flutter/material.dart';
import 'package:tlist/page/login.dart';
import 'package:tlist/page/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tlist/utils/app_update.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (user == null) {
                return _buildSignedOut(context);
              }
              return _buildSignedIn(context, user);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSignedOut(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Image.asset(
            'assets/logo.png',
            height: 80,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'You are not signed in',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Login'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterPage()),
            );
          },
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Daftar'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.system_update_alt),
          title: const Text('Cek pembaruan'),
          subtitle: const Text('Periksa apakah ada versi terbaru'),
          onTap: () async {
            final manifestUrl = kIsWeb
                ? Uri.base.resolve('update.json').toString() // same-origin to avoid CORS in web
                : 'https://tlistserver.web.app/update.json';
            final cfg = AppUpdateConfig(manifestUrl: manifestUrl);
            // Manual check: tampilkan prompt meskipun sebelumnya pernah di-dismiss.
            await AppUpdate.checkAndPrompt(
              context,
              config: cfg,
              silentOnError: false,
              ignoreDismiss: true,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSignedIn(BuildContext context, User user) {
    final displayName = user.displayName ?? 'Pengguna';
    final email = user.email ?? '-';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(displayName),
          subtitle: Text(email),
        ),
        const Divider(),
        if (!(user.emailVerified))
          ListTile(
            leading: const Icon(Icons.mark_email_unread_outlined),
            title: const Text('Kirim ulang verifikasi email'),
            onTap: () async {
              try {
                final acs = kIsWeb
                    ? ActionCodeSettings(
                        url: '${Uri.base.origin}/verified',
                        handleCodeInApp: false,
                      )
                    : null;
                if (acs != null) {
                  await user.sendEmailVerification(acs);
                } else {
                  await user.sendEmailVerification();
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email verifikasi dikirim')), 
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal kirim verifikasi: $e')),
                  );
                }
              }
            },
          ),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Ganti nama tampil'),
          onTap: () async {
            final name = await _prompt(context, title: 'Nama tampil baru', hint: 'Nama lengkap');
            if (name == null || name.trim().isEmpty) return;
            try {
              await user.updateDisplayName(name.trim());
              await user.reload();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama tampil diperbarui')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal ganti nama: $e')),
                );
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.alternate_email),
          title: const Text('Ganti email'),
          subtitle: const Text('Butuh verifikasi ulang, Anda akan keluar'),
          onTap: () async {
            final currentPass = await _prompt(context, title: 'Konfirmasi Password', hint: 'Password saat ini', obscure: true);
            if (currentPass == null || currentPass.isEmpty) return;
            final newEmail = await _prompt(context, title: 'Email baru', hint: 'nama@domain.com');
            if (newEmail == null || newEmail.trim().isEmpty) return;
            try {
              final emailNow = user.email;
              if (emailNow == null) throw Exception('Email akun tidak tersedia');
              final cred = EmailAuthProvider.credential(email: emailNow, password: currentPass);
              await user.reauthenticateWithCredential(cred);
              final newAddr = newEmail.trim();
              final acs = kIsWeb
                  ? ActionCodeSettings(
                      url: '${Uri.base.origin}/verified',
                      handleCodeInApp: false,
                    )
                  : null;
              if (acs != null) {
                await user.verifyBeforeUpdateEmail(newAddr, acs);
              } else {
                await user.verifyBeforeUpdateEmail(newAddr);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verifikasi telah dikirim ke email baru. Selesaikan verifikasi lalu login kembali.')),
                );
              }
              await FirebaseAuth.instance.signOut();
            } on FirebaseAuthException catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal ganti email: ${e.code}')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal ganti email: $e')),
                );
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Ganti password'),
          onTap: () async {
            final currentPass = await _prompt(context, title: 'Password saat ini', hint: 'Password', obscure: true);
            if (currentPass == null || currentPass.isEmpty) return;
            final newPass = await _prompt(context, title: 'Password baru', hint: 'Minimal 6 karakter', obscure: true);
            if (newPass == null || newPass.length < 6) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password baru minimal 6 karakter')),
                );
              }
              return;
            }
            try {
              final emailNow = user.email;
              if (emailNow == null) throw Exception('Email akun tidak tersedia');
              final cred = EmailAuthProvider.credential(email: emailNow, password: currentPass);
              await user.reauthenticateWithCredential(cred);
              await user.updatePassword(newPass);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password berhasil diubah')),
                );
              }
            } on FirebaseAuthException catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal ganti password: ${e.code}')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal ganti password: $e')),
                );
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Keluar'),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out')),
              );
            }
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.system_update_alt),
          title: const Text('Cek pembaruan'),
          subtitle: const Text('Periksa apakah ada versi terbaru'),
          onTap: () async {
            final manifestUrl = kIsWeb
                ? Uri.base.resolve('update.json').toString()
                : 'https://tlistserver.web.app/update.json';
            final cfg = AppUpdateConfig(manifestUrl: manifestUrl);
            final status = await AppUpdate.getStatus(config: cfg);
            if (!context.mounted) return;
            final info = status.info;
            if (info == null) {
              // gagal memuat manifest
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Gagal memeriksa pembaruan'),
                  content: const Text('Tidak bisa memuat informasi pembaruan saat ini. Coba lagi nanti.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
              return;
            }

            if (!status.isNewer) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sudah versi terbaru'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Versi terpasang: ${status.currentVersion}'),
                      Text('Versi terbaru: ${info.version}'),
                      const SizedBox(height: 8),
                      if ((info.notes ?? '').isNotEmpty)
                        Text(info.notes!),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } else {
              await AppUpdate.checkAndPrompt(
                context,
                config: cfg,
                silentOnError: false,
              );
            }
          },
        ),
      ],
    );
  }

  Future<String?> _prompt(
    BuildContext context, {
    required String title,
    required String hint,
    bool obscure = false,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

}

