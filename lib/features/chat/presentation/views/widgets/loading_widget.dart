import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

import '../../../../../core/utils/app_colors.dart';

class CustomLoadingWidget extends StatelessWidget {
  const CustomLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 24,
      child: Center(
        child: LoadingIndicator(
          indicatorType: Indicator.ballPulse,
          colors: [AppColors.primaryColor],
          strokeWidth: 3,
        ),
      ),
    );
  }
}
