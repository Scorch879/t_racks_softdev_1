import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:t_racks_softdev_1/services/in_app_notification_service.dart';

// Light theme colors
const _bgWhite = Colors.white;
const _textBlack = Colors.black;
const _textGrey = Color(0xFF64748B);
const _chipGreen = Color(0xFF7FE26B);
const _accentCyan = Color(0xFF0C3343);
const _statusRed = Color(0xFFE26B6B);

class NotificationsDialog extends StatelessWidget {
  const NotificationsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _bgWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        // This constraint limits the MAX height, but the dialog will
        // still shrink if the content is smaller.
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Vital: Wraps content height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: _textBlack,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.done_all, color: _accentCyan),
                      tooltip: "Mark all read",
                      splashRadius: 20,
                      onPressed: () {
                        InAppNotificationService().markAsRead();
                      },
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: _textGrey),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Content Builder ---
            // Note: We removed the 'Flexible' wrapper from here so we can
            // return it conditionally inside the builder.
            AnimatedBuilder(
              animation: InAppNotificationService(),
              builder: (context, _) {
                final notifications = InAppNotificationService().notifications;

                // 1. EMPTY STATE (Small)
                if (notifications.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    // No 'Center' or 'Expanded' here prevents it from stretching
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 40,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "No new notifications",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                // 2. LIST STATE (Scrollable)
                // We wrap this in Flexible so it can scroll within the max height
                return Flexible(
                  child: ListView.separated(
                    shrinkWrap: true, // Helper for dialogs
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: _statusRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        onDismissed: (direction) {
                          InAppNotificationService().dismissNotification(
                            item.id,
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: item.isRead
                                ? Colors.grey.shade50
                                : _chipGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: item.isRead
                                  ? Colors.grey.shade200
                                  : _chipGreen.withOpacity(0.3),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: _chipGreen,
                              radius: 16,
                              child: const Icon(
                                Icons.class_,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: item.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: _textBlack,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  item.message,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('h:mm a').format(item.timestamp),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
