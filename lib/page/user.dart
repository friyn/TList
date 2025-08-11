import 'package:flutter/material.dart';
import 'package:tlist/page/login.dart';
import 'package:tlist/page/register.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          'You are not sign in',
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
      ],
    );
  }

}

