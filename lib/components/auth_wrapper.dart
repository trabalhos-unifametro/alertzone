import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/auth_service.dart';
import 'app_shell.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;
  final String title;
  final bool? noFull;
  final bool? noHeader;

  const AuthWrapper({
    super.key,
    required this.child,
    required this.title,
    this.noFull,
    this.noHeader,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        bool loggedIn = user != null && !user.isAnonymous;

        return AppShell(
          title: title,
          noFull: noFull,
          noHeader: noHeader,
          loggedIn: loggedIn,
          child: child,
        );
      },
    );
  }
}
