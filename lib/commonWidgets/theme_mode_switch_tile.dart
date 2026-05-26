import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/theme_service.dart';

class ThemeModeSwitchTile extends StatelessWidget {
  const ThemeModeSwitchTile({
    super.key,
    required this.scale,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconColor,
    this.borderColor,
    this.shadowColor,
  });

  final double scale;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color iconColor;
  final Color? borderColor;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeController.instance;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isDarkMode = controller.isDarkMode;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 18 * scale,
            vertical: 12 * scale,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22 * scale),
            border: borderColor != null
                ? Border.all(color: borderColor!)
                : null,
            boxShadow: [
              BoxShadow(
                color: shadowColor ?? Colors.black.withValues(alpha: 0.18),
                blurRadius: 8 * scale,
                offset: Offset(0, 4 * scale),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: iconColor,
                size: 20 * scale,
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Text(
                  'Dark Mode',
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch(
                value: isDarkMode,
                onChanged: (value) {
                  controller.setDarkMode(value);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
