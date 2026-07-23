import 'package:flutter/material.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/network/api_client.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _notifications = [];
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get('/notifications');
      setState(() {
        _notifications = response.data as List? ?? [];
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load notifications.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      final apiClient = getIt<ApiClient>();
      await apiClient.patch('/notifications/$id/read');
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == id);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update notification.')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    if (_notifications.every((n) => n['is_read'] == true)) return;

    setState(() => _isLoading = true);
    try {
      final apiClient = getIt<ApiClient>();
      await apiClient.post('/notifications/read-all');
      setState(() {
        for (var n in _notifications) {
          n['is_read'] = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark all as read.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getFilteredNotifications() {
    if (_selectedCategory == "All") return _notifications;
    if (_selectedCategory == "Critical") {
      return _notifications.where((n) => n['type'] == 'emergency' || n['type'] == 'alert').toList();
    }
    if (_selectedCategory == "Appointments") {
      return _notifications.where((n) => n['type'] == 'appointment').toList();
    }
    if (_selectedCategory == "Lab Updates") {
      return _notifications.where((n) => n['type'] == 'lab').toList();
    }
    return _notifications;
  }

  int _getUnreadCount(String category) {
    if (category == "All") {
      return _notifications.where((n) => n['is_read'] == false).length;
    }
    if (category == "Critical") {
      return _notifications.where((n) => (n['type'] == 'emergency' || n['type'] == 'alert') && n['is_read'] == false).length;
    }
    if (category == "Appointments") {
      return _notifications.where((n) => n['type'] == 'appointment' && n['is_read'] == false).length;
    }
    if (category == "Lab Updates") {
      return _notifications.where((n) => n['type'] == 'lab' && n['is_read'] == false).length;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredNotifications();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchNotifications, child: const Text("Retry")),
                      ],
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Desktop Sidebar Left Panel
                      if (isDesktop)
                        Container(
                          width: 300,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.grey.shade200),
                            ),
                          ),
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Summary',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              _buildCategorySelector("All", Icons.notifications_none_rounded),
                              _buildCategorySelector("Critical", Icons.priority_high_rounded, badgeColor: Colors.red),
                              _buildCategorySelector("Appointments", Icons.calendar_month_rounded, badgeColor: Colors.blue),
                              _buildCategorySelector("Lab Updates", Icons.biotech_rounded, badgeColor: Colors.teal),
                              const SizedBox(height: 24),
                              
                              // AI Insight panel
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.auto_awesome_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          'AI INSIGHT',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Review clinical alerts regularly to ensure critical parameters and vitals are addressed promptly.',
                                      style: TextStyle(fontSize: 12, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Main List Panel
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top actions header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (!isDesktop)
                                    // Mobile Category Chips
                                    DropdownButton<String>(
                                      value: _selectedCategory,
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.filter_list_rounded),
                                      items: ["All", "Critical", "Appointments", "Lab Updates"].map((cat) {
                                        final unread = _getUnreadCount(cat);
                                        return DropdownMenuItem(
                                          value: cat,
                                          child: Text(unread > 0 ? "$cat ($unread)" : cat),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedCategory = val);
                                        }
                                      },
                                    )
                                  else
                                    Text(
                                      '$_selectedCategory Alerts',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ElevatedButton.icon(
                                    onPressed: _markAllAsRead,
                                    icon: const Icon(Icons.done_all_rounded, size: 18),
                                    label: const Text('Mark all as read'),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(150, 44),
                                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Notification feed list
                              Expanded(
                                child: filtered.isEmpty
                                    ? _buildEmptyState()
                                    : ListView.builder(
                                        itemCount: filtered.length,
                                        itemBuilder: (context, index) {
                                          final item = filtered[index];
                                          final isRead = item['is_read'] == true;
                                          final id = item['id'] as int;
                                          final title = item['title'] as String? ?? 'Alert';
                                          final body = item['body'] as String? ?? '';
                                          final type = item['type'] as String? ?? 'alert';
                                          
                                          final isCritical = type == 'emergency' || type == 'alert';

                                          return Card(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              side: BorderSide(
                                                color: !isRead && isCritical
                                                    ? Theme.of(context).colorScheme.error.withOpacity(0.5)
                                                    : Colors.transparent,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  left: BorderSide(
                                                    color: isCritical
                                                        ? Theme.of(context).colorScheme.error
                                                        : (type == 'lab' ? Colors.teal : Colors.blue),
                                                    width: 4,
                                                  ),
                                                ),
                                              ),
                                              child: ListTile(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                leading: Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: (isCritical
                                                            ? Theme.of(context).colorScheme.errorContainer
                                                            : (type == 'lab' ? Colors.teal.shade50 : Colors.blue.shade50))
                                                        .withOpacity(0.8),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    isCritical
                                                        ? Icons.emergency_rounded
                                                        : (type == 'lab' ? Icons.biotech_rounded : Icons.calendar_today_rounded),
                                                    color: isCritical
                                                        ? Theme.of(context).colorScheme.error
                                                        : (type == 'lab' ? Colors.teal : Colors.blue),
                                                  ),
                                                ),
                                                title: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        title,
                                                        style: TextStyle(
                                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                                          color: isRead
                                                              ? Theme.of(context).colorScheme.onSurfaceVariant
                                                              : Theme.of(context).colorScheme.onSurface,
                                                        ),
                                                      ),
                                                    ),
                                                    if (!isRead)
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: BoxDecoration(
                                                          color: isCritical
                                                              ? Theme.of(context).colorScheme.error
                                                              : Theme.of(context).colorScheme.primary,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                subtitle: Padding(
                                                  padding: const EdgeInsets.only(top: 6.0),
                                                  child: Text(
                                                    body,
                                                    style: TextStyle(
                                                      color: isRead
                                                          ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7)
                                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ),
                                                trailing: isRead
                                                    ? null
                                                    : ElevatedButton(
                                                        onPressed: () => _markAsRead(id),
                                                        child: Text(isCritical ? 'Acknowledge' : 'Mark Read'),
                                                        style: ElevatedButton.styleFrom(
                                                          minimumSize: const Size(80, 36),
                                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                          backgroundColor: isCritical
                                                              ? Theme.of(context).colorScheme.error
                                                              : Theme.of(context).colorScheme.primary,
                                                          foregroundColor: Colors.white,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildCategorySelector(String name, IconData icon, {Color? badgeColor}) {
    final isSelected = _selectedCategory == name;
    final unread = _getUnreadCount(name);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = name;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (unread > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unread.toString().padLeft(2, '0'),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_paused_rounded,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'All Caught Up',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'No active alerts or clinical notifications.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
