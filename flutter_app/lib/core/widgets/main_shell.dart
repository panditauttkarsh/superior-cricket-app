import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          child,
          Positioned(
            left: 20,
            right: 20,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: _buildBottomNavBar(context, location),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, String location) {
    return Container(
      // Outer container handles only shadow and shape for clipping
      decoration: BoxDecoration(
        color: Colors.transparent, // Color is handled inside for glass effect
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color?.withOpacity(0.6) ?? Colors.white.withOpacity(0.6),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(context, Icons.home, Icons.home_outlined, 'Home', 'home', '/', location),
                _buildNavItem(context, Icons.sports_cricket, Icons.sports_cricket_outlined, 'My Cricket', 'my-matches', '/my-cricket', location),
                
                // Center Plus Button
                _buildCenterPlusButton(context),

                _buildNavItem(context, Icons.workspace_premium, Icons.workspace_premium_outlined, 'PRO', 'pro', '/pro', location),
                _buildNavItem(context, Icons.person, Icons.person_outline, 'Profile', 'profile', '/profile', location),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterPlusButton(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/create-match');
          },
          borderRadius: BorderRadius.circular(23),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData filledIcon, IconData outlinedIcon, String label, String navKey, String path, String currentLocation) {
    final isActive = path == '/' 
        ? currentLocation == '/' 
        : (currentLocation == path || currentLocation.startsWith('$path/'));
    
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          context.go(path);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.transparent, 
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? filledIcon : outlinedIcon,
              color: isActive 
                  ? Colors.white
                  : AppColors.textMeta,
              size: 22,
            ),
          ),
          const SizedBox(height: 2), // Tighter spacing
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive 
                  ? AppColors.primary
                  : AppColors.textMeta,
            ),
          ),
        ],
      ),
    );
  }
}
