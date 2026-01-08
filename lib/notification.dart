import 'package:flutter/material.dart';

// Notification Model
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime time;
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
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> notifications = [
    NotificationModel(
      id: '1',
      title: 'Heavy Rain Alert',
      message: 'Heavy rainfall expected in the next 24 hours. Consider delaying irrigation and protecting sensitive crops.',
      time: DateTime.now().subtract(Duration(minutes: 10)),
      type: NotificationType.weather,
      priority: NotificationPriority.high,
      isRead: false,
    ),
    NotificationModel(
      id: '2',
      title: 'Pest Detection Alert',
      message: 'Brown plant hopper detected in nearby fields. Monitor your rice crops closely and consider preventive measures.',
      time: DateTime.now().subtract(Duration(hours: 1)),
      type: NotificationType.pest,
      priority: NotificationPriority.high,
      isRead: false,
    ),
    NotificationModel(
      id: '3',
      title: 'Irrigation Completed',
      message: 'North Field irrigation completed successfully. Water used: 500L, Duration: 120 minutes.',
      time: DateTime.now().subtract(Duration(hours: 2)),
      type: NotificationType.irrigation,
      priority: NotificationPriority.normal,
      isRead: true,
    ),
    NotificationModel(
      id: '4',
      title: 'Crop Health Improved',
      message: 'Wheat Field health score increased to 92%. Recent fertilizer application showing positive results.',
      time: DateTime.now().subtract(Duration(hours: 3)),
      type: NotificationType.crop,
      priority: NotificationPriority.normal,
      isRead: true,
    ),
    NotificationModel(
      id: '5',
      title: 'Temperature Rising',
      message: 'Temperature expected to reach 32°C today. Ensure adequate irrigation for heat-sensitive crops.',
      time: DateTime.now().subtract(Duration(hours: 5)),
      type: NotificationType.weather,
      priority: NotificationPriority.high,
      isRead: false,
    ),
  ];

  bool showFilter = false;
  NotificationFilter currentFilter = NotificationFilter.all;
  NotificationType? selectedType;
  
  List<NotificationModel> get filteredNotifications {
    List<NotificationModel> filtered = notifications;
    
    if (currentFilter == NotificationFilter.unread) {
      filtered = filtered.where((n) => !n.isRead).toList();
    }
    
    if (selectedType != null) {
      filtered = filtered.where((n) => n.type == selectedType).toList();
    }
    
    return filtered;
  }
  
  int get totalCount => notifications.length;
  int get unreadCount => notifications.where((n) => !n.isRead).length;
  int get highPriorityCount => notifications.where((n) => n.priority == NotificationPriority.high).length;
  int get todayCount => notifications.where((n) => n.time.day == DateTime.now().day).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterSection(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildNotificationsList(),
                    SizedBox(height: 16),
                    _buildNotificationSummary(), // Fixed summary widget
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      height: 124,
      decoration: BoxDecoration(
        color: Color(0xFF2C7C48),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
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
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
                SizedBox(width: 16),
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  '$unreadCount unread notifications',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
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
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.filter_list,
                  label: 'Filter',
                  onTap: () => setState(() => showFilter = !showFilter),
                  color: Color(0xFF354152),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.check_circle_outline,
                  label: 'Mark all read',
                  onTap: _markAllAsRead,
                  color: Color(0xFF354152),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.delete_outline,
                  label: 'Clear all',
                  onTap: _clearAllNotifications,
                  color: Color(0xFFE7000B),
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
          border: Border.all(color: Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontFamily: 'Arimo',
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterPanel() {
    return Column(
      children: [
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Notifications',
                    style: TextStyle(
                      color: Color(0xFF101727),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => showFilter = false),
                    child: Icon(Icons.close, size: 20, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('All', currentFilter == NotificationFilter.all),
                  _buildFilterChip('Unread', currentFilter == NotificationFilter.unread),
                  _buildFilterChip('Weather', selectedType == NotificationType.weather),
                  _buildFilterChip('Pest', selectedType == NotificationType.pest),
                  _buildFilterChip('Irrigation', selectedType == NotificationType.irrigation),
                  _buildFilterChip('Crop', selectedType == NotificationType.crop),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (label == 'All') {
            currentFilter = NotificationFilter.all;
            selectedType = null;
          } else if (label == 'Unread') {
            currentFilter = NotificationFilter.unread;
            selectedType = null;
          } else {
            currentFilter = NotificationFilter.all;
            selectedType = NotificationType.values.firstWhere(
              (e) => e.name.toLowerCase() == label.toLowerCase()
            );
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF9810FA) : Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Color(0xFF354152),
            fontSize: 14,
            fontFamily: 'Arimo',
          ),
        ),
      ),
    );
  }
  
  Widget _buildNotificationsList() {
    if (filteredNotifications.isEmpty) return EmptyNotificationWidget();
    
    return Column(
      children: filteredNotifications.map((notification) => NotificationItemWidget(
        notification: notification,
        onMarkAsRead: () => _markAsRead(notification.id),
        onDelete: () => _deleteNotification(notification.id),
      )).toList(),
    );
  }
  
  // Fixed Notification Summary Widget - No overflow
 Widget _buildNotificationSummary() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Color(0xFFE5E7EB), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Summary',
          style: TextStyle(
            color: Color(0xFF101727),
            fontSize: 18,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        SizedBox(height: 16),
        // Using LayoutBuilder to avoid overflow
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: 160, // Fixed height for the grid
              child: Column(
                children: [
                  // First row
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryBox(
                            title: 'Total',
                            value: totalCount.toString(),
                            bgColor: Color(0xFFFAF5FF),
                            titleColor: Color(0xFF9810FA),
                            valueColor: Color(0xFF59168B),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryBox(
                            title: 'Unread',
                            value: unreadCount.toString(),
                            bgColor: Color(0xFFFFF7ED),
                            titleColor: Color(0xFFF44900),
                            valueColor: Color(0xFF7E2A0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  // Second row
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryBox(
                            title: 'High Priority',
                            value: highPriorityCount.toString(),
                            bgColor: Color(0xFFFEF2F2),
                            titleColor: Color(0xFFE7000B),
                            valueColor: Color(0xFF82181A),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryBox(
                            title: 'Today',
                            value: todayCount.toString(),
                            bgColor: Color(0xFFEFF6FF),
                            titleColor: Color(0xFF155CFB),
                            valueColor: Color(0xFF1B388E),
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
    padding: EdgeInsets.all(12),
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
        SizedBox(height: 4),
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
  
  void _markAsRead(String id) {
    setState(() {
      notifications = notifications.map((notification) {
        if (notification.id == id) {
          return NotificationModel(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            time: notification.time,
            type: notification.type,
            priority: notification.priority,
            isRead: true,
          );
        }
        return notification;
      }).toList();
    });
  }
  
  void _markAllAsRead() {
    setState(() {
      notifications = notifications.map((notification) => NotificationModel(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        time: notification.time,
        type: notification.type,
        priority: notification.priority,
        isRead: true,
      )).toList();
    });
  }
  
  void _deleteNotification(String id) {
    setState(() => notifications.removeWhere((notification) => notification.id == id));
  }
  
  void _clearAllNotifications() {
    setState(() => notifications.clear());
  }
}

class EmptyNotificationWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
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
  
  NotificationItemWidget({
    required this.notification,
    required this.onMarkAsRead,
    required this.onDelete,
  });
  
  Map<NotificationType, Map<String, dynamic>> _typeStyles = {
    NotificationType.weather: {
      'border': Color(0xFFBDDAFF),
      'bg': Color(0xFFEFF6FF),
      'icon': Color(0xFFBDDAFF),
      'text': Color(0xFF1B388E),
      'iconData': Icons.cloud,
    },
    NotificationType.pest: {
      'border': Color(0xFFFEEF85),
      'bg': Color(0xFFFEFCE8),
      'icon': Color(0xFFFFF085),
      'text': Color(0xFF723D0A),
      'iconData': Icons.bug_report,
    },
    NotificationType.irrigation: {
      'border': Color(0xFFBDDAFF),
      'bg': Color(0xFFEFF6FF),
      'icon': Color(0xFFBDDAFF),
      'text': Color(0xFF1B388E),
      'iconData': Icons.water_drop,
    },
    NotificationType.crop: {
      'border': Color(0xFFB8F7CF),
      'bg': Color(0xFFF0FDF4),
      'icon': Color(0xFFB9F8CF),
      'text': Color(0xFF0D532B),
      'iconData': Icons.eco,
    },
    NotificationType.system: {
      'border': Color(0xFFD1D5DB),
      'bg': Color(0xFFF9FAFB),
      'icon': Color(0xFFD1D5DB),
      'text': Color(0xFF374151),
      'iconData': Icons.notifications,
    },
  };
  
  Map<String, dynamic> get _styles {
    if (!notification.isRead) {
      return {
        'border': Color(0xFFFFC9C9),
        'bg': Color(0xFFFEF2F2),
        'icon': Color(0xFFFFC9C9),
        'text': Color(0xFF82181A),
        'iconData': Icons.notifications,
      };
    }
    return _typeStyles[notification.type]!;
  }
  
  String get _timeAgo {
    final diff = DateTime.now().difference(notification.time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return '1 day ago';
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    return '${notification.time.day}/${notification.time.month}/${notification.time.year}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
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
          SizedBox(width: 12),
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
                        margin: EdgeInsets.only(left: 8, top: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF9810FA),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  notification.message,
                  style: TextStyle(
                    color: _styles['text'].withOpacity(0.9),
                    fontSize: 14,
                    fontFamily: 'Arimo',
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _timeAgo,
                      style: TextStyle(
                        color: _styles['text'].withOpacity(0.75),
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
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _styles['icon'],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Mark as read',
                                style: TextStyle(
                                  color: _styles['text'],
                                  fontSize: 12,
                                  fontFamily: 'Arimo',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(width: 8),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notification.isRead)
              ListTile(
                leading: Icon(Icons.check_circle, color: Color(0xFF2C7C48)),
                title: Text('Mark as read', style: TextStyle(fontFamily: 'Arimo')),
                onTap: () {
                  Navigator.pop(context);
                  onMarkAsRead();
                },
              ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete', style: TextStyle(fontFamily: 'Arimo', color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            SizedBox(height: 8),
            Container(
              margin: EdgeInsets.all(16),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(fontFamily: 'Arimo')),
                style: TextButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  backgroundColor: Color(0xFFF3F4F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}