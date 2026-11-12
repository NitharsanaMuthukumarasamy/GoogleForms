import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/network_service.dart';

/// Wraps the root app or screen with a subtle, non-intrusive banner
/// that indicates when the device has lost internet connectivity.
/// Offline Firestore changes are queued and will sync automatically upon reconnection.
class OfflineBanner extends ConsumerWidget {
  final Widget? child;

  const OfflineBanner({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineAsync = ref.watch(isOnlineProvider);
    final isOnline = onlineAsync.value ?? true;

    return Stack(
      children: [
        if (child != null) child!,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isOnline ? 0 : 36,
            color: const Color(0xFFD97706), // Amber warning
            child: isOnline
                ? const SizedBox.shrink()
                : Material(
                    color: Colors.transparent,
                    child: SafeArea(
                      bottom: false,
                      top: false,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Offline Mode — changes will sync once reconnected',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
