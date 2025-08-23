import 'package:flutter/material.dart';
import 'fullscreen_search.dart';
import 'package:latlong2/latlong.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final Color iconColor;
  final Function(String) onSubmitted;
  final VoidCallback onSearchPressed;
  final Function(String, LatLng)? onLocationSelected;

  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.iconColor,
    required this.onSubmitted,
    required this.onSearchPressed,
    this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => FullscreenSearch(
              initialQuery: controller.text,
              hintText: hintText,
              onLocationSelected: (address, location) {
                controller.text = address;
                if (onLocationSelected != null) {
                  onLocationSelected!(address, location);
                }
              },
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(
                  Tween(begin: const Offset(0.0, 1.0), end: Offset.zero),
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 100),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  controller.text.isEmpty ? hintText : controller.text,
                  style: TextStyle(
                    color: controller.text.isEmpty ? Colors.grey.shade600 : Colors.black,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
