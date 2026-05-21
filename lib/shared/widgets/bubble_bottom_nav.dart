import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class BubbleBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int pendingCount;

  const BubbleBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.pendingCount = 0,
  });

  @override
  State<BubbleBottomNav> createState() => _BubbleBottomNavState();
}

class _BubbleBottomNavState extends State<BubbleBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  int _prevIndex = 0;

  static const _barHeight = 64.0;
  static const _circleRadius = 28.0;
  static const _notchDepth = 16.0;

  final _items = const [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Inicio'),
    _NavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment, label: 'Visitas'),
    _NavItem(icon: Icons.add_circle_outlined, activeIcon: Icons.add_circle, label: 'Crear'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Perfil'),
  ];

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(
      begin: _prevIndex.toDouble(),
      end: widget.currentIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void didUpdateWidget(BubbleBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _prevIndex = oldWidget.currentIndex;
      _animation = Tween<double>(
        begin: _prevIndex.toDouble(),
        end: widget.currentIndex.toDouble(),
      ).animate(CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOutCubic,
      ));
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final navWidth = screenWidth - 32;
    final itemWidth = navWidth / 4;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: SizedBox(
        height: _barHeight + _circleRadius + 8,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final activeIndex = _animation.value;
                return CustomPaint(
                  size: Size(navWidth, _barHeight),
                  painter: _NotchBarPainter(
                    activeIndex: activeIndex,
                    itemWidth: itemWidth,
                    circleRadius: _circleRadius,
                    notchDepth: _notchDepth,
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final activeIndex = _animation.value;
                final circleX = activeIndex * itemWidth + itemWidth / 2;
                return Positioned(
                  left: circleX - _circleRadius,
                  top: -(_circleRadius - _notchDepth + 4),
                  child: _buildActiveCircle(activeIndex),
                );
              },
            ),
            Row(
              children: List.generate(_items.length, (i) {
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onTap(i),
                    child: SizedBox(
                      height: _barHeight,
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          final isActive = (_animation.value - i).abs() < 0.5;
                          return Icon(
                            isActive ? _items[i].activeIcon : _items[i].icon,
                            color: isActive ? Colors.transparent : AppColors.dorado,
                            size: 24,
                          );
                        },
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (widget.pendingCount > 0)
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final activeIndex = _animation.value;
                  final badgeX = activeIndex * itemWidth + itemWidth / 2 + _circleRadius * 0.6;
                  return Positioned(
                    left: badgeX - 8,
                    top: -(_circleRadius - _notchDepth + 2),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: BoxDecoration(
                        color: AppColors.dorado,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.darkBg, width: 2),
                      ),
                      child: Text(
                        '${widget.pendingCount > 9 ? '9+' : widget.pendingCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.guindaDark,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCircle(double activeIndex) {
    return Container(
      width: _circleRadius * 2,
      height: _circleRadius * 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.guinda, AppColors.guindaMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.guinda.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        _items[activeIndex.round().clamp(0, 3)].activeIcon,
        color: AppColors.doradoLight,
        size: 24,
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NotchBarPainter extends CustomPainter {
  final double activeIndex;
  final double itemWidth;
  final double circleRadius;
  final double notchDepth;

  _NotchBarPainter({
    required this.activeIndex,
    required this.itemWidth,
    required this.circleRadius,
    required this.notchDepth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.darkBg
      ..style = PaintingStyle.fill;

    final path = Path();
    final barHeight = size.height;
    final cornerRadius = 20.0;
    final notchWidth = circleRadius * 2 + 8;
    final notchCenterX = activeIndex * itemWidth + itemWidth / 2;

    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    double currentX = cornerRadius;
    final notchStartX = notchCenterX - notchWidth / 2;
    final notchEndX = notchCenterX + notchWidth / 2;

    if (notchStartX > currentX) {
      path.lineTo(notchStartX, 0);
    }

    path.quadraticBezierTo(
      notchCenterX - notchWidth / 4,
      0,
      notchCenterX - notchWidth / 4,
      notchDepth * 0.3,
    );
    path.quadraticBezierTo(
      notchCenterX - notchWidth / 6,
      notchDepth,
      notchCenterX,
      notchDepth,
    );
    path.quadraticBezierTo(
      notchCenterX + notchWidth / 6,
      notchDepth,
      notchCenterX + notchWidth / 4,
      notchDepth * 0.3,
    );
    path.quadraticBezierTo(
      notchCenterX + notchWidth / 4,
      0,
      notchEndX,
      0,
    );

    if (notchEndX < size.width - cornerRadius) {
      path.lineTo(size.width - cornerRadius, 0);
    }

    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    path.lineTo(size.width, barHeight - cornerRadius);
    path.quadraticBezierTo(size.width, barHeight, size.width - cornerRadius, barHeight);
    path.lineTo(cornerRadius, barHeight);
    path.quadraticBezierTo(0, barHeight, 0, barHeight - cornerRadius);
    path.close();

    canvas.drawPath(path, paint);

    final shadowPaint = Paint()
      ..color = AppColors.guindaDark.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final shadowPath = Path();
    shadowPath.moveTo(0, barHeight);
    shadowPath.lineTo(size.width, barHeight);
    shadowPath.lineTo(size.width, barHeight + 4);
    shadowPath.lineTo(0, barHeight + 4);
    shadowPath.close();
    canvas.drawPath(shadowPath, shadowPaint);
  }

  @override
  bool shouldRepaint(_NotchBarPainter oldDelegate) {
    return oldDelegate.activeIndex != activeIndex;
  }
}
