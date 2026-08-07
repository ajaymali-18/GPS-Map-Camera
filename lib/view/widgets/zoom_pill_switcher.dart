import 'package:flutter/material.dart';
import '../../viewModel/camera_viewmodel.dart';

class ZoomPillSwitcher extends StatelessWidget {
  final CameraViewModel viewModel;
  final VoidCallback onZoomChanged;

  const ZoomPillSwitcher({
    super.key,
    required this.viewModel,
    required this.onZoomChanged,
  });

  Widget _buildZoomPillOption(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 96,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0x99262626),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildZoomPillOption('1x', viewModel.currentZoom <= 1.5, () async {
                await viewModel.setZoom(1.0);
                onZoomChanged();
              }),
              _buildZoomPillOption('2x', viewModel.currentZoom > 1.5, () async {
                await viewModel.setZoom(
                  2.0.clamp(viewModel.minZoom, viewModel.maxZoom),
                );
                onZoomChanged();
              }),
            ],
          ),
        ),
      ),
    );
  }
}
