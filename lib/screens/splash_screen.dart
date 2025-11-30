import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/terms_acceptance_footer.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _termsAccepted = false;
  final String _termsAcceptedKey = 'terms_accepted';
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkTermsStatus();
  }

  void _checkTermsStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_termsAcceptedKey) ?? false;

    setState(() {
      _termsAccepted = accepted;
      _isChecking = false;
    });

    if (accepted) {
      _startAppFlow();
    }
  }

  void _acceptAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_termsAcceptedKey, true);
    setState(() {
      _termsAccepted = true;
    });
    _startAppFlow();
  }

  void _startAppFlow() {
    context.goNamed('home');
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'Alert Zone - Carregando...',
      color: AppColors.primary500,
      child: Scaffold(
        backgroundColor: const Color(0xFF4268b3),
        body: Stack(
          children: <Widget>[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SvgPicture.asset(
                    "assets/images/logo.svg",
                    height: 100,
                  ),
                  if (_isChecking)
                    const Padding(
                      padding: EdgeInsets.only(top: 20.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                ],
              ),
            ),

            if (!_termsAccepted && !_isChecking)
              Align(
                alignment: Alignment.bottomCenter,
                child: TermsAcceptanceFooter(
                  onAccept: _acceptAndNavigate,
                ),
              ),
          ],
        ),
      ),
    );
  }
}