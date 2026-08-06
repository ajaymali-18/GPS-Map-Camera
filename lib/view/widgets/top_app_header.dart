import 'package:flutter/material.dart';

class TopAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onFlashPressed;
  final VoidCallback? onSettingsPressed;

  const TopAppHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.onFlashPressed,
    this.onSettingsPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.transparent,
        child: Row(
          children: [
            // Left Action / Flash
            leading ??
                IconButton(
                  onPressed: onFlashPressed,
                  icon: const Icon(Icons.bolt, color: Colors.white, size: 26),
                  tooltip: 'Flash Toggle',
                ),

            // Centered Title / Banner
            Expanded(
              child: Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // Right Action / Settings
            trailing ??
                IconButton(
                  onPressed: onSettingsPressed ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Settings coming soon'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                  icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                  tooltip: 'Settings',
                ),
          ],
        ),
      ),
    );
  }
}
