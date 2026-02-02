import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BackArrowButton extends StatelessWidget {
  const BackArrowButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        GoRouter.of(context).pop();
      },
      child: const Icon(Icons.arrow_back),
    );
  }
}
