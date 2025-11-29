import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../service/auth_service.dart';
import '../theme/app_colors.dart';

class RightSidebarDrawer extends StatelessWidget {
  const RightSidebarDrawer({super.key});

  void _navigateTo(BuildContext context, String routeName) {
    Navigator.of(context).pop();
    GoRouter.of(context).goNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Drawer(
      child: Column(
        children: <Widget>[
          StreamBuilder<User?>(
            stream: authService.authStateChanges(),
            builder: (context, snapshot) {
              final User? user = snapshot.data;

              final String userName = user?.displayName ?? 'Usuário';
              final String? photoUrl = user?.photoURL;

              return DrawerHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary500,
                      child: photoUrl != null
                          ? ClipOval(
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 40, color: Colors.white);
                          },
                        ),
                      )
                          : const Icon(Icons.person, size: 40, color: Colors.white),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Olá, ', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black)),
                        Text(
                            '$userName!',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
                        ),
                      ],
                    ),

                    if (user?.email != null)
                      Text(
                        user!.email!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.edit_note, color: Colors.grey),
            title: const Text('Editar meus dados'),
            onTap: () => _navigateTo(context, 'account'),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.playlist_add, color: Colors.grey),
            title: const Text('Registrar ocorrência'),
            onTap: () => _navigateTo(context, 'form'),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.list_alt, color: Colors.grey),
            title: const Text('Minhas ocorrências'),
            onTap: () =>
                _navigateTo(context, 'occurrences'),
          ),
          const Divider(height: 0),

          const Spacer(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await authService.signOut();
              GoRouter.of(context).goNamed('login');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}