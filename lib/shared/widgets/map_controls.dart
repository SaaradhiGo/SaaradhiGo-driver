import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:saaradhigo_driver/ui/sg_tokens.dart';

class MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;

  const MapControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.glassOverlay,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: SgColors.shadow, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? AppColors.primaryText : AppColors.whiteText,
          size: 24,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
