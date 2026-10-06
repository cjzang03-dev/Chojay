import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_client.dart';
import '../domain/app_notification.dart';

/// Backed by the website's existing `notifications` table — already written
/// to by both the admin dashboard (approvals, payments) and this app's own
/// chat repository, so this is a shared inbox, not an app-only feature.
class NotificationsRepository {
  Future<List<AppNotification>> fetchMine({int limit = 50}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(AppNotification.fromJson).toList();
  }

  Future<void> markAsRead(String id) async {
    await supabase.from('notifications').update({'read': true}).eq('id', id);
  }

  Future<void> markAllAsRead() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase
        .from('notifications')
        .update({'read': true})
        .eq('user_id', userId)
        .eq('read', false);
  }

  /// Live updates so the bell badge and list react immediately to a new
  /// notification, matching ChatRepository.subscribeToMessages's pattern.
  RealtimeChannel subscribeToMine(
    void Function(AppNotification notification) onInsert,
  ) {
    final userId = supabase.auth.currentUser?.id;
    final channel = supabase.channel('notifications-${userId ?? 'anon'}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) =>
              onInsert(AppNotification.fromJson(payload.newRecord)),
        )
        .subscribe();
    return channel;
  }
}
