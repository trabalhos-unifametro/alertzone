import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 5), () {
      context.goNamed('home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'Alert Zone - Carregando...',
      color: AppColors.primary500,
      child: Scaffold(
        backgroundColor: const Color(0xFF4268b3),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SvgPicture.asset(
                "assets/images/logo.svg",
                height: 100,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
