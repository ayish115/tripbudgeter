import 'package:flutter/material.dart';

class BnbScreen extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BnbScreen({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  Widget _buildNavIcon(IconData icon, bool isSelected, Color selectedColor) {
    return Icon(
      icon,
      size: isSelected ? 34 : 26,
      color: isSelected ? selectedColor : Colors.grey[600],
      shadows: isSelected
          ? [
              Shadow(
                color: selectedColor.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ]
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = const Color(0xFF45A19B);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        onTap: onTap,
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.home, currentIndex == 0, selectedColor),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.flight_rounded, currentIndex == 1, selectedColor),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.download, currentIndex == 2, selectedColor),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.person, currentIndex == 3, selectedColor),
            label: '',
          ),
        ],
      ),
    );
  }
}
