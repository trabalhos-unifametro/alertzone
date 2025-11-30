import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../components/app_shell.dart';
import '../components/auth_wrapper.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/register_occurrence_screen.dart';
import '../screens/occurrences_list_screen.dart';
import '../screens/my_account_screen.dart';
import '../service/auth_notifier_service.dart';
import '../utils/terms_utils.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();
bool get isDesktop =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: authNotifier,
  redirect: (context, state) async {
    final bool termsAccepted = await checkTermsAccepted();
    final user = authNotifier.user;
    final bool isLogged = user != null && !user.isAnonymous;
    final String location = state.matchedLocation;
    final bool isSplash = location == '/';
    final bool isPublic = location == '/home' || location == '/login';
    final bool isProtected = location.startsWith('/form') ||
        location == '/occurrences' ||
        location == '/account';

    final bool isDocument = location == '/politica-e-privacidade.pdf' ||
        location == '/termos-de-servico.pdf';

    if (isDocument) {
      return null;
    }

    if (!termsAccepted && !isSplash) {
      return '/';
    }

    if (termsAccepted && isSplash) {
      return '/home';
    }

    if (isPublic) {
      if (isLogged && location == '/login') {
        return '/home';
      }
      return null;
    }

    if (isProtected) {
      if (!isLogged) {
        return '/login';
      }
    }

    return null;
    // final user = authNotifier.user;
    // final bool isLogged = user != null && !user.isAnonymous;
    //
    // final loggingIn = state.matchedLocation == '/login';
    // final splash = state.matchedLocation == '/';
    // final home = state.matchedLocation == '/home';
    // if (loggingIn || splash) return null;
    // if (isLogged && loggingIn) return '/home';
    // if (!isLogged) {
    //   if (home) return null;
    //   return '/login';
    // }
    //
    // return null;
  },
  routes: [
    GoRoute(
      name: 'splash',
      path: '/',
      pageBuilder: (context, state) {
        return (kIsWeb || isDesktop)
            ? NoTransitionPage(child: const SplashScreen())
            : MaterialPage(child: const SplashScreen());
      }
    ),
    GoRoute(
      name: 'login',
      path: '/login',
      pageBuilder: (context, state) {
        return (kIsWeb || isDesktop)
            ? NoTransitionPage(child: const LoginScreen())
            : MaterialPage(child: const LoginScreen());
      }
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        String title = '';
        bool noFull = false;
        final location = state.matchedLocation;

        if (location == '/home') {
          title = 'Alert Zone';
          noFull = true;
        }
        else if (location.startsWith('/form')) {
          if (location.contains('mode=edit')) {
            title = 'Editar ocorrência';
          } else {
            title = 'Registrar ocorrência';
          }
        }
        if (location == '/occurrences') title = 'Minhas ocorrências';
        if (location == '/account') title = 'Editar meus dados';
        if (location.startsWith('/edit')) title = 'Editar ocorrência';

        return AuthWrapper(
          title: title,
          noFull: noFull,
          child: child,
        );
      },
      routes: [
        GoRoute(
          name: 'home',
          path: '/home',
          pageBuilder: (context, state) {
            return (kIsWeb || isDesktop)
                ? NoTransitionPage(child: const HomeScreen())
                : MaterialPage(child: const HomeScreen());
          }
        ),
        GoRoute(
            name: 'form',
            path: '/form',
            pageBuilder: (context, state) {
              final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;

              final String? docIdToEdit = extra?['docIdToEdit'] as String?;
              final Map<String, dynamic>? initialData = extra?['initialData'] as Map<String, dynamic>?;
              final LatLng? initialCoordinates = extra?['initialCoordinates'] as LatLng?;

              return (kIsWeb || isDesktop)
                  ? NoTransitionPage(
                child: RegisterOccurrenceScreen(
                  docIdToEdit: docIdToEdit,
                  initialData: initialData,
                  initialCoordinates: initialCoordinates,
                ),
              )
                  : MaterialPage(
                child: RegisterOccurrenceScreen(
                  docIdToEdit: docIdToEdit,
                  initialData: initialData,
                  initialCoordinates: initialCoordinates,
                ),
              );
            }
        ),
        GoRoute(
          name: 'occurrences',
          path: '/occurrences',
          pageBuilder: (context, state) {
            return (kIsWeb || isDesktop)
                ? NoTransitionPage(child: const OccurrencesListScreen())
                : MaterialPage(child: const OccurrencesListScreen());
          }
        ),
        GoRoute(
          name: 'account',
          path: '/account',
          pageBuilder: (context, state) {
            return (kIsWeb || isDesktop)
                ? NoTransitionPage(child: const MyAccountScreen())
                : MaterialPage(child: const MyAccountScreen());
          }
        ),
      ],
    ),
  ],
);