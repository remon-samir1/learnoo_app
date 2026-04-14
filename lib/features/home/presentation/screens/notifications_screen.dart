import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final String time;
  final FaIconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final bool isUnread;
  final String type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.isUnread,
    required this.type,
  });
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final newNotifications = [
      NotificationItem(
        id: '1',
        title: 'home.live_session_starting'.tr(),
        description: 'home.advanced_sorting'.tr(),
        time: 'home.two_min_ago'.tr(),
        icon: FontAwesomeIcons.video,
        iconBackgroundColor: const Color(0xFFFFF0F0),
        iconColor: const Color(0xFFFF4B4B),
        isUnread: true,
        type: 'live',
      ),
      NotificationItem(
        id: '2',
        title: 'home.new_lecture'.tr(),
        description: 'home.chapter_5_cost'.tr(),
        time: 'home.one_hour_ago'.tr(),
        icon: FontAwesomeIcons.bookOpen,
        iconBackgroundColor: const Color(0xFFF0F5FF),
        iconColor: const Color(0xFF5A75FF),
        isUnread: true,
        type: 'lecture',
      ),
      NotificationItem(
        id: '3',
        title: 'home.exam_reminder'.tr(),
        description: 'home.chapter_3_quiz'.tr(),
        time: 'home.three_hours_ago'.tr(),
        icon: FontAwesomeIcons.calendarCheck,
        iconBackgroundColor: const Color(0xFFFFF8F0),
        iconColor: const Color(0xFFF2994A),
        isUnread: true,
        type: 'exam',
      ),
    ];

    final earlierNotifications = [
      NotificationItem(
        id: '4',
        title: 'home.new_reply'.tr(),
        description: 'home.dr_sarah_reply'.tr(),
        time: 'home.five_hours_ago'.tr(),
        icon: FontAwesomeIcons.commentDots,
        iconBackgroundColor: const Color(0xFFF0FFF6),
        iconColor: const Color(0xFF27AE60),
        isUnread: false,
        type: 'reply',
      ),
      NotificationItem(
        id: '5',
        title: 'home.new_summary'.tr(),
        description: 'home.chapter_4_summary'.tr(),
        time: 'home.yesterday'.tr(),
        icon: FontAwesomeIcons.fileLines,
        iconBackgroundColor: const Color(0xFFF0F5FF),
        iconColor: const Color(0xFF5A75FF),
        isUnread: false,
        type: 'summary',
      ),
      NotificationItem(
        id: '6',
        title: 'home.welcome_learnoo'.tr(),
        description: 'home.start_exploring'.tr(),
        time: 'home.two_days_ago'.tr(),
        icon: FontAwesomeIcons.bell,
        iconBackgroundColor: const Color(0xFFF5F5F5),
        iconColor: const Color(0xFF9CA3AF),
        isUnread: false,
        type: 'welcome',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.arrowLeft,
                          color: Color(0xFF374151),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'home.notifications_title'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Notifications List
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // New Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: const Color(0xFFF9FAFB),
                      child: Text(
                        'home.notifications_new'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),

                    // New Notifications
                    ...newNotifications.map((notification) => _buildNotificationItem(notification)),

                    // Earlier Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: const Color(0xFFF9FAFB),
                      child: Text(
                        'home.notifications_earlier'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),

                    // Earlier Notifications
                    ...earlierNotifications.map((notification) => _buildNotificationItem(notification)),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF3F4F6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: notification.iconBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: FaIcon(
                notification.icon,
                color: notification.iconColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with unread dot
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    if (notification.isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF5A75FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  notification.description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),

                // Time
                Text(
                  notification.time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
