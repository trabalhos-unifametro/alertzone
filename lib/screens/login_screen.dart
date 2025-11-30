import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alertzone/service/auth_service.dart';

import '../components/max_width_container_web.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const double _maxWebWidth = 450.0;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _loading = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signInGoogle() async {
    setState(() => _loading = true);
    User? user = await _authService.signInWithGoogle();
    setState(() => _loading = false);

    if (!mounted) return;

    if (user != null) {
      context.goNamed('home');
    } else {
      _showMessage("Falha ao fazer login com Google. Tente novamente!");
    }
  }

  Future<void> _signInApple() async {
    setState(() => _loading = true);
    User? user = await _authService.signInWithApple();
    setState(() => _loading = false);

    if (!mounted) return;

    if (user != null) {
      context.goNamed('home');
    } else {
      _showMessage("Falha ao fazer login com Apple. Tente novamente!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'Alert Zone - Tela de login',
      color: Colors.blue,
      child: Scaffold(
        backgroundColor: AppColors.primary500,
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                    width: double.infinity,
                    child: Center(
                        child: InkWell(
                          onTap: () {
                            final String currentRoute = GoRouter.of(context).state.matchedLocation;
                            if (currentRoute != '/home') {
                              context.go('/home');
                            }
                          },
                          child: SvgPicture.asset("assets/images/logo.svg", height: 100),
                        ),
                    ),
                  ),

                  Container(
                    height: MediaQuery.of(context).size.height * 0.65,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(100),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const SizedBox(height: 30),
                          const Text('FAZER LOGIN COM', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primary500),),
                          const SizedBox(height: 20),

                          MaxWidthContainerWeb(
                            child: ElevatedButton(
                              onPressed: _loading ? null : _signInGoogle,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: AppColors.primary500,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _iconSvg('assets/images/google_logo.svg'),
                                  const Text('GOOGLE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),),
                                  const SizedBox(width: 30),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          MaxWidthContainerWeb(
                            child: ElevatedButton(
                              onPressed: _loading ? null : _signInApple,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: AppColors.primary500,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _iconSvg('assets/images/apple_logo.svg'),
                                  const Text('APPLE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),),
                                  const SizedBox(width: 30),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),
                          MaxWidthContainerWeb(
                            child: const Row(
                              children: [
                                Expanded(child: Divider(thickness: 1)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text('ou'),
                                ),
                                Expanded(child: Divider(thickness: 1)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          MaxWidthContainerWeb(
                            child: OutlinedButton(
                              onPressed: _loading
                                  ? null
                                  : () async {
                                setState(() => _loading = true);

                                await AuthService().signInAnonymously();

                                if (!mounted) return;

                                setState(() => _loading = false);

                                context.goNamed('home');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary500,
                                side: const BorderSide(color: Color(0xFF4268b3)),
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const SizedBox(width: 30),
                                  const Text('CONTINUAR SEM LOGIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),),
                                  const Icon(Icons.arrow_forward, size: 25,),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_loading)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconSvg(String path) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(left: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
      ),
      child: SvgPicture.asset(path, height: 24),
    );
  }
}