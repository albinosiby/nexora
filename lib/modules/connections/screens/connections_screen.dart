import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/dark_background.dart';
import '../repositories/connection_service.dart';
import '../../profile/screens/profile_view_screen.dart';

/// Connections Screen - View and manage connections and requests
class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ConnectionService _connectionService = Get.find<ConnectionService>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DarkBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: NexoraColors.textPrimary,
            ),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            'Connections',
            style: TextStyle(
              color: NexoraColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: NexoraColors.primaryPurple,
            indicatorWeight: 3,
            labelColor: NexoraColors.textPrimary,
            unselectedLabelColor: NexoraColors.textMuted,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: [
              Obx(
                () => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Requests'),
                      if (_connectionService.incomingRequests.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: NexoraColors.romanticPink,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_connectionService.incomingRequests.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Obx(
                () => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Connections'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: NexoraColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_connectionService.connections.length}',
                          style: const TextStyle(
                            color: NexoraColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildRequestsTab(), _buildConnectionsTab()],
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    return Obx(() {
      final requests = _connectionService.incomingRequests;

      if (requests.isEmpty) {
        return _buildEmptyState(
          icon: Icons.person_add_disabled_rounded,
          title: 'No Pending Requests',
          subtitle:
              'When someone sends you a connection request, it will appear here.',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildRequestCard(request);
        },
      );
    });
  }

  Widget _buildConnectionsTab() {
    return Obx(() {
      final connections = _connectionService.connections;

      if (connections.isEmpty) {
        return _buildEmptyState(
          icon: Icons.people_outline_rounded,
          title: 'No Connections Yet',
          subtitle: 'Start connecting with people to build your network!',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: connections.length,
        itemBuilder: (context, index) {
          final connection = connections[index];
          return _buildConnectionCard(connection);
        },
      );
    });
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: NexoraColors.glassBackground,
                shape: BoxShape.circle,
                border: Border.all(color: NexoraColors.glassBorder),
              ),
              child: Icon(icon, size: 48, color: NexoraColors.textMuted),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: NexoraColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(ConnectionRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NexoraColors.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexoraColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _navigateToProfile(request),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: NexoraGradients.primaryButton,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.network(
                  request.avatar,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      request.name.isNotEmpty ? request.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToProfile(request),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.name,
                    style: const TextStyle(
                      color: NexoraColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.major,
                    style: const TextStyle(
                      color: NexoraColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(request.timestamp),
                    style: const TextStyle(
                      color: NexoraColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Row(
            children: [
              // Reject
              GestureDetector(
                onTap: () {
                  _connectionService.rejectRequest(request.userId);
                  Get.snackbar(
                    'Request Declined',
                    'Connection request from ${request.name} declined',
                    backgroundColor: NexoraColors.glassBackground,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                    duration: const Duration(seconds: 2),
                    margin: const EdgeInsets.all(16),
                    borderRadius: 12,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: NexoraColors.textMuted.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: NexoraColors.textMuted,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Accept
              GestureDetector(
                onTap: () {
                  _connectionService.acceptRequest(request.userId);
                  Get.snackbar(
                    'Connected!',
                    'You are now connected with ${request.name}',
                    backgroundColor: NexoraColors.success.withOpacity(0.9),
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                    duration: const Duration(seconds: 2),
                    margin: const EdgeInsets.all(16),
                    borderRadius: 12,
                    icon: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [NexoraColors.success, NexoraColors.accentCyan],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: NexoraColors.success.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(ConnectionRequest connection) {
    return GestureDetector(
      onTap: () => _navigateToProfile(connection),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NexoraColors.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NexoraColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: NexoraGradients.primaryButton,
                shape: BoxShape.circle,
                border: Border.all(
                  color: NexoraColors.success.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  connection.avatar,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      connection.name.isNotEmpty ? connection.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        connection.name,
                        style: const TextStyle(
                          color: NexoraColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: NexoraColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.link_rounded,
                              size: 10,
                              color: NexoraColors.success,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Connected',
                              style: TextStyle(
                                color: NexoraColors.success,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    connection.major,
                    style: const TextStyle(
                      color: NexoraColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connected ${_formatTimeAgo(connection.timestamp)}',
                    style: const TextStyle(
                      color: NexoraColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              children: [
                // Message
                GestureDetector(
                  onTap: () {
                    // Navigate to chat
                    Get.snackbar(
                      'Opening Chat',
                      'Starting conversation with ${connection.name}',
                      backgroundColor: NexoraColors.primaryPurple.withOpacity(
                        0.9,
                      ),
                      colorText: Colors.white,
                      snackPosition: SnackPosition.TOP,
                      duration: const Duration(seconds: 1),
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: NexoraColors.primaryPurple.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: NexoraColors.primaryPurple,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // More options
                GestureDetector(
                  onTap: () => _showConnectionOptions(connection),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: NexoraColors.glassBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: NexoraColors.glassBorder),
                    ),
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      color: NexoraColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(ConnectionRequest request) {
    Get.to(
      () => ProfileViewScreen(
        userId: request.userId,
        name: request.name,
        avatar: request.avatar,
        major: request.major,
      ),
      transition: Transition.rightToLeftWithFade,
    );
  }

  void _showConnectionOptions(ConnectionRequest connection) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: NexoraColors.midnightDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NexoraColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              connection.name,
              style: const TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(
                Icons.person_outline_rounded,
                color: NexoraColors.textPrimary,
              ),
              title: const Text(
                'View Profile',
                style: TextStyle(color: NexoraColors.textPrimary),
              ),
              onTap: () {
                Get.back();
                _navigateToProfile(connection);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.block_rounded,
                color: NexoraColors.textMuted,
              ),
              title: const Text(
                'Block User',
                style: TextStyle(color: NexoraColors.textMuted),
              ),
              onTap: () {
                Get.back();
                // Block functionality
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.person_remove_rounded,
                color: NexoraColors.romanticPink,
              ),
              title: const Text(
                'Remove Connection',
                style: TextStyle(color: NexoraColors.romanticPink),
              ),
              onTap: () {
                Get.back();
                _connectionService.removeConnection(connection.userId);
                Get.snackbar(
                  'Connection Removed',
                  '${connection.name} has been removed from your connections',
                  backgroundColor: NexoraColors.glassBackground,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                  duration: const Duration(seconds: 2),
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${(diff.inDays / 7).floor()}w ago';
    }
  }
}
