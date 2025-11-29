import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MaxWidthContainerWeb extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final String? title;

  const MaxWidthContainerWeb({
    super.key,
    required this.child,
    this.maxWidth = 450,
    this.title
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLarge = width > maxWidth;

    return isLarge
        ? Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: title != null ? Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(children: [
                InkWell(
                  onTap: () {
                    final String currentRoute = GoRouter.of(context).state.matchedLocation;
                    if (currentRoute != '/home') {
                      context.go('/home');
                    }
                  },
                  child: const Icon(Icons.keyboard_backspace, size: 30,),
                ),
                const SizedBox(width: 20,),
                Text(title ?? '')
              ],),
            ),
            Expanded(child: child),
          ],
        ) : child,
      ),
    ) : child;
  }
}
