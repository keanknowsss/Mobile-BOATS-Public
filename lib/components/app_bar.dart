import 'package:flutter/material.dart';
import '../constants/colors.dart';

class BoatsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BoatsAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      shape: const Border(
        bottom: BorderSide(width: 2, color: Colors.black26),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
