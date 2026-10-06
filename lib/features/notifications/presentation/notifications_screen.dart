import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/coming_soon.dart';
import '../../../core/widgets/error_state.dart';
import '../data/notifications_providers.dart';
import '../domain/app_notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllAsRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const ComingSoon(
              icon: Icons.notifications_none_rounded,
              title: 'Nothing here yet',
              message: 'Booking updates, messages, and approvals will show up here.',
            );
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                onTap: () {
                  if (!notification.isRead) {
                    ref
                        .read(notificationsProvider.notifier)
                        .markAsRead(notification.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (notification.type) {
      'success' => (Icons.check_circle_rounded, AppColors.himalayanGreen),
      'error' => (Icons.error_rounded, AppColors.errorRed),
      'message' => (Icons.chat_bubble_rounded, AppColors.saffron),
      _ => (Icons.notifications_rounded, AppColors.stoneGrey),
    };

    return Container(
      color: notification.isRead ? null : AppColors.himalayanGreen.withValues(alpha: 0.04),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Text(notification.message, style: TextStyle(color: AppColors.stoneGrey)),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.saffron,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }
}
