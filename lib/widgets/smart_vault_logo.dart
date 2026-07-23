import 'package:flutter/material.dart';

/// Animated SmartVaultz logo for dashboard and branding.
class SmartVaultLogo extends StatefulWidget {
  const SmartVaultLogo({
    super.key,
    this.size = 120,
    this.iconSize = 56,
    this.showTagline = true,
  });

  final double size;
  final double iconSize;
  final bool showTagline;

  @override
  State<SmartVaultLogo> createState() => _SmartVaultLogoState();
}

class _SmartVaultLogoState extends State<SmartVaultLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // Logo circle: use 75% of screen width so it fills the area
    final size = (w * 0.75).clamp(160.0, 320.0);
    final iconSize = (size * 0.45).clamp(72.0, 140.0);
    final textSize = (w * 0.09).clamp(28.0, 42.0);
    final taglineSize = (w * 0.035).clamp(12.0, 18.0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: size,
                  height: size,
                  padding: EdgeInsets.all(size * 0.15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF778DA9).withValues(alpha: 0.4),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: iconSize,
                    color: const Color(0xFFE0E1DD),
                  ),
                ),
                SizedBox(height: size * 0.18),
                SizedBox(
                  width: w * 0.9,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFE0E1DD), Color(0xFF778DA9)],
                      ).createShader(bounds),
                      child: Text(
                        'SmartVaultz',
                        style: TextStyle(
                          fontSize: textSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.showTagline) ...[
                  SizedBox(height: size * 0.06),
                  Text(
                    'Secure • Simple • Yours',
                    style: TextStyle(
                      fontSize: taglineSize,
                      letterSpacing: 4,
                      color: const Color(0xFF778DA9).withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
