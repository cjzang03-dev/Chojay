import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_client.dart';
import '../domain/app_notification.dart';
import 'notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository();
});

/// Newest-first notifications for the signed-in user, kept live via a
/// realtime subscription — a new row (e.g. a chat message, an admin
/// approval) prepends itself without needing a manual refresh.
final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  RealtimeChannel? _channel;

  @override
  Future<List<AppNotification>> build() async {
    final repo = ref.watch(notificationsRepositoryProvider);
    _channel?.unsubscribe();
    _channel = null;

    if (supabase.auth.currentUser != null) {
      _channel = repo.subscribeToMine((notification) {
        final current = state.valueOrNull ?? const [];
        state = AsyncData([notification, ...current]);
      });
    }
    ref.onDispose(() => _channel?.unsubscribe());

    return repo.fetchMine();
  }

  Future<void> markAsRead(String id) async {
    final current = state.valueOrNull ?? const [];
    state = AsyncData([
      for (final n in current)
        if (n.id == id)
          AppNotification(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
          )
        else
          n,
    ]);
    await ref.read(notificationsRepositoryProvider).markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    final current = state.valueOrNull ?? const [];
    state = AsyncData([
      for (final n in current)
        AppNotification(
          id: n.id,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
        ),
    ]);
    await ref.read(notificationsRepositoryProvider).markAllAsRead();
  }
}

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return notifications.where((n) => !n.isRead).length;
});
