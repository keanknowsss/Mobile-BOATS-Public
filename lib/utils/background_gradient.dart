import 'package:flutter/material.dart';
import '../constants/colors.dart';

BoxDecoration appBackgroundGradient() {
  return const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        AppColors.primary,
        AppColors.primaryAccent,
      ],
    ),
  );
}
