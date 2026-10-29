import 'package:flutter/material.dart';
import '../storage/offline_queue.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OfflineSyncEngine.instance.isOfflineNotifier,
      builder: (context, isOffline, child) {
        return ValueListenableBuilder<int>(
          valueListenable: OfflineSyncEngine.instance.pendingCountNotifier,
          builder: (context, pendingCount, child) {
            if (!isOffline && pendingCount == 0) {
              return const SizedBox.shrink();
            }

            final text = isOffline
                ? (pendingCount > 0
                    ? 'Offline mode. $pendingCount change(s) queued and will sync automatically.'
                    : 'Offline mode. Changes will be queued and synced.')
                : 'Syncing $pendingCount pending changes...';

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF59E0B), // Material Amber 600
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
