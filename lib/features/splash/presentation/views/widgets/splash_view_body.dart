import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/utils/app_router.dart';
import '../../../../../core/utils/assets.dart';

class SplashViewBody extends StatelessWidget {
  const SplashViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Animate(
                onComplete: (controller) {
                  GoRouter.of(context).replace(AppRoutes.kOnBoardingRoute);
                },
                child: Image.asset(Assets.assetsImagesLogoPng),
              )
              .fadeIn(duration: 700.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }
}
