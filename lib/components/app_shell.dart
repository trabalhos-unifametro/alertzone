import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'max_width_container_web.dart';
import 'right_sidebar_drawer.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String title;
  final bool? noFull;
  final bool? noHeader;
  final bool loggedIn;

  const AppShell({
    super.key,
    required this.child,
    required this.title,
    this.noFull,
    this.noHeader,
    required this.loggedIn,
  });

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      endDrawer: const RightSidebarDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4268b3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(10),
          ),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: InkWell(
          onTap: () {
            final String currentRoute = GoRouter.of(context).state.matchedLocation;
            if (currentRoute != '/home') {
              context.go('/home');
            }
          },
          child: SvgPicture.asset(
            "assets/images/logo.svg",
            height: 35,
          ),
        ),
        actions: <Widget>[
          if (loggedIn) IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              scaffoldKey.currentState!.openEndDrawer();
            },
          ) else TextButton(
            onPressed: () {
              // Navigator.of(context).pop();
              GoRouter.of(context).goNamed('login');
            },
            child: const Row(
              children: [
                Text('LOGIN', style: TextStyle(color: Colors.white)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (noFull == true) {
            return child;
          } else {
            return MaxWidthContainerWeb(maxWidth: 800, title: title, child: child,);
          }
        },
      ),
    );
  }
}