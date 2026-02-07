import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'localization_service.dart';

// Notification Model
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final Timestamp time; // Use Firestore Timestamp for compatibility
  final bool isRead;
  final NotificationType type;
  final NotificationPriority priority;
  
  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
    this.priority = NotificationPriority.normal,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    String typeStr = (data['type'] as String?) ?? 'system';
    String prioStr = (data['priority'] as String?) ?? 'normal';

    NotificationType parsedType = NotificationType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == typeStr.toLowerCase(),
      orElse: () => NotificationType.system,
    );

    NotificationPriority parsedPriority = NotificationPriority.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == prioStr.toLowerCase(),
      orElse: () => NotificationPriority.normal,
    );

    return NotificationModel(
      id: doc.id,
      title: (data['title'] as String?) ?? 'No title',
      message: (data['message'] as String?) ?? '',
      time: (data['time'] as Timestamp?) ?? Timestamp.now(),
      type: parsedType,
      isRead: (data['isRead'] as bool?) ?? false,
      priority: parsedPriority,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'time': time,
      'isRead': isRead,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
    };
  }
}

enum NotificationType {
  weather,
  pest,
  irrigation,
  crop,
  system
}

enum NotificationPriority {
  high,
  normal,
  low
}

enum NotificationFilter {
  all,
  unread,
}

// Main Notification Screen
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool showFilter = false;
  NotificationFilter currentFilter = NotificationFilter.all;
  NotificationType? selectedType;
  
  String tr(String key) => LocalizationService.translate(key);
  
  // Filter logic will be applied to the live list from Firestore snapshot in the StreamBuilder
  

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    final Stream<QuerySnapshot> notificationsStream = userId.isNotEmpty
        ? FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .orderBy('time', descending: true)
            .snapshots()
        : Stream.empty();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: notificationsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('${LocalizationService.translate('Error:')} ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            List<NotificationModel> notifications = docs
                .map((d) => NotificationModel.fromFirestore(d))
                .toList();

            // Apply filters
            List<NotificationModel> filtered = notifications;
            if (currentFilter == NotificationFilter.unread) {
              filtered = filtered.where((n) => !n.isRead).toList();
            }
            if (selectedType != null) {
              filtered = filtered.where((n) => n.type == selectedType).toList();
            }

            final totalCount = notifications.length;
            final unreadCount = notifications.where((n) => !n.isRead).length;
            final highPriorityCount = notifications.where((n) => n.priority == NotificationPriority.high).length;
            final todayCount = notifications.where((n) => n.time.toDate().day == DateTime.now().day).length;

            return Column(
              children: [
                _buildHeaderCounts(unreadCount),
                _buildFilterSection(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildNotificationsList(filtered),
                        const SizedBox(height: 16),
                        _buildNotificationSummaryCounts(totalCount, unreadCount, highPriorityCount, todayCount),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildHeaderCounts(int unreadCount) {
    return Container(
      height: 124,
      decoration: BoxDecoration(
        color: const Color(0xFF2C7C48),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  tr('Notifications'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$unreadCount ${tr('unread notifications')}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.filter_list,
                  label: tr('Filter'),
                  onTap: () => setState(() => showFilter = !showFilter),
                  color: const Color(0xFF354152),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.check_circle_outline,
                  label: tr('Mark all read'),
                  onTap: _markAllAsRead,
                  color: const Color(0xFF354152),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.delete_outline,
                  label: tr('Clear all'),
                  onTap: _clearAllNotifications,
                  color: const Color(0xFFE7000B),
                ),
              ),
            ],
          ),
          if (showFilter) _buildFilterPanel(),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontFamily: 'Arimo',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFilterPanel() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('Filter Notifications'),
                    style: const TextStyle(
                      color: Color(0xFF101727),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => showFilter = false),
                    child: const Icon(Icons.close, size: 20, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('All', NotificationFilter.all, null, currentFilter == NotificationFilter.all),
                  _buildFilterChip('Unread', NotificationFilter.unread, null, currentFilter == NotificationFilter.unread),
                  _buildFilterChip('Weather', null, NotificationType.weather, selectedType == NotificationType.weather),
                  _buildFilterChip('Pest', null, NotificationType.pest, selectedType == NotificationType.pest),
                  _buildFilterChip('Irrigation', null, NotificationType.irrigation, selectedType == NotificationType.irrigation),
                  _buildFilterChip('Crop', null, NotificationType.crop, selectedType == NotificationType.crop),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFilterChip(
    String labelKey,
    NotificationFilter? filterType,
    NotificationType? typeFilter,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (filterType != null) {
            currentFilter = filterType;
            selectedType = null;
          } else if (typeFilter != null) {
            currentFilter = NotificationFilter.all;
            selectedType = typeFilter;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9810FA) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          tr(labelKey),
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF354152),
            fontSize: 14,
            fontFamily: 'Arimo',
          ),
        ),
      ),
    );
  }
  
  Widget _buildNotificationsList(List<NotificationModel> filteredNotifications) {
    if (filteredNotifications.isEmpty) return const EmptyNotificationWidget();

    return Column(
      children: filteredNotifications.map((notification) => NotificationItemWidget(
        notification: notification,
        onMarkAsRead: () => _markAsRead(notification.id),
        onDelete: () => _deleteNotification(notification.id),
      )).toList(),
    );
  }
  


Widget _buildSummaryBox({
  required String title,
  required String value,
  required Color bgColor,
  required Color titleColor,
  required Color valueColor,
}) {
  return Container(
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 12,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
  
  Widget _buildNotificationSummaryCounts(int totalCount, int unreadCount, int highPriorityCount, int todayCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Summary',
            style: TextStyle(
              color: Color(0xFF101727),
              fontSize: 18,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: 160,
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryBox(
                              title: 'Total',
                              value: totalCount.toString(),
                              bgColor: const Color(0xFFFAF5FF),
                              titleColor: const Color(0xFF9810FA),
                              valueColor: const Color(0xFF59168B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryBox(
                              title: 'Unread',
                              value: unreadCount.toString(),
                              bgColor: const Color(0xFFFFF7ED),
                              titleColor: const Color(0xFFF44900),
                              valueColor: const Color(0xFF7E2A0B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryBox(
                              title: 'High Priority',
                              value: highPriorityCount.toString(),
                              bgColor: const Color(0xFFFEF2F2),
                              titleColor: const Color(0xFFE7000B),
                              valueColor: const Color(0xFF82181A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryBox(
                              title: 'Today',
                              value: todayCount.toString(),
                              bgColor: const Color(0xFFEFF6FF),
                              titleColor: const Color(0xFF155CFB),
                              valueColor: const Color(0xFF1B388E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  void _markAsRead(String id) {
    // Update Firestore document
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(id)
        .update({'isRead': true})
        .catchError((e) {
          print('Error marking as read: $e');
        });
  }
  
  void _markAllAsRead() {
    // Batch update all notifications to read
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    final batch = FirebaseFirestore.instance.batch();
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .get()
        .then((snap) {
          for (var doc in snap.docs) {
            batch.update(doc.reference, {'isRead': true});
          }
          return batch.commit();
        })
        .catchError((e) {
          print('Error marking all as read: $e');
        });
  }
  
  void _deleteNotification(String id) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(id)
        .delete()
        .catchError((e) {
          print('Error deleting notification: $e');
        });
  }
  
  void _clearAllNotifications() {
    // Delete all documents in notifications collection (batched)
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .get()
        .then((snap) async {
          final batch = FirebaseFirestore.instance.batch();
          for (var doc in snap.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        })
        .catchError((e) {
          print('Error clearing notifications: $e');
        });
  }
}

class EmptyNotificationWidget extends StatelessWidget {
  const EmptyNotificationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.notifications_none, size: 64, color: Color(0xFF6B7280)),
          SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              color: Color(0xFF101727),
              fontSize: 16,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No unread notifications to show',
            style: TextStyle(
              color: Color(0xFF495565),
              fontSize: 14,
              fontFamily: 'Arimo',
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationItemWidget extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;
  
  const NotificationItemWidget({super.key, 
    required this.notification,
    required this.onMarkAsRead,
    required this.onDelete,
  });
  
  static final Map<NotificationType, Map<String, dynamic>> _typeStyles = {
    NotificationType.weather: {
      'border': const Color(0xFFBDDAFF),
      'bg': const Color(0xFFEFF6FF),
      'icon': const Color(0xFFBDDAFF),
      'text': const Color(0xFF1B388E),
      'iconData': Icons.cloud,
    },
    NotificationType.pest: {
      'border': const Color(0xFFFEEF85),
      'bg': const Color(0xFFFEFCE8),
      'icon': const Color(0xFFFFF085),
      'text': const Color(0xFF723D0A),
      'iconData': Icons.bug_report,
    },
    NotificationType.irrigation: {
      'border': const Color(0xFFBDDAFF),
      'bg': const Color(0xFFEFF6FF),
      'icon': const Color(0xFFBDDAFF),
      'text': const Color(0xFF1B388E),
      'iconData': Icons.water_drop,
    },
    NotificationType.crop: {
      'border': const Color(0xFFB8F7CF),
      'bg': const Color(0xFFF0FDF4),
      'icon': const Color(0xFFB9F8CF),
      'text': const Color(0xFF0D532B),
      'iconData': Icons.eco,
    },
    NotificationType.system: {
      'border': const Color(0xFFD1D5DB),
      'bg': const Color(0xFFF9FAFB),
      'icon': const Color(0xFFD1D5DB),
      'text': const Color(0xFF374151),
      'iconData': Icons.notifications,
    },
  };
  
  Map<String, dynamic> get _styles {
    if (!notification.isRead) {
      return {
        'border': const Color(0xFFFFC9C9),
        'bg': const Color(0xFFFEF2F2),
        'icon': const Color(0xFFFFC9C9),
        'text': const Color(0xFF82181A),
        'iconData': Icons.notifications,
      };
    }
    return _typeStyles[notification.type]!;
  }
  
  String get _timeAgo {
    final diff = DateTime.now().difference(notification.time.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return '1 day ago';
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    final dt = notification.time.toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _styles['bg'],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _styles['border'], width: notification.isRead ? 1 : 3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _styles['icon'],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_styles['iconData'], size: 20, color: _styles['text']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          color: _styles['text'],
                          fontSize: 16,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8, top: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF9810FA),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.message,
                  style: TextStyle(
                    color: _styles['text'].withValues(alpha: 0.9),
                    fontSize: 14,
                    fontFamily: 'Arimo',
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _timeAgo,
                      style: TextStyle(
                        color: _styles['text'].withValues(alpha: 0.75),
                        fontSize: 12,
                        fontFamily: 'Arimo',
                      ),
                    ),
                    Row(
                      children: [
                        if (!notification.isRead)
                          InkWell(
                            onTap: onMarkAsRead,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _styles['icon'],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                LocalizationService.translate('Mark as read'),
                                style: TextStyle(
                                  color: _styles['text'],
                                  fontSize: 12,
                                  fontFamily: 'Arimo',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showActionMenu(context),
                          child: Icon(Icons.more_vert, size: 20, color: _styles['text']),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!notification.isRead)
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Color(0xFF2C7C48)),
                  title: Text(LocalizationService.translate('Mark as read'), style: const TextStyle(fontFamily: 'Arimo')),
                  onTap: () {
                    Navigator.pop(context);
                    onMarkAsRead();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(LocalizationService.translate('Delete'), style: const TextStyle(fontFamily: 'Arimo', color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: const Color(0xFFF3F4F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(LocalizationService.translate('Cancel'), style: const TextStyle(fontFamily: 'Arimo')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
  