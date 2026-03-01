import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/dark_background.dart';
import '../repositories/connection_service.dart';
import '../../profile/models/profile_model.dart';
import '../../profile/screens/profile_view_screen.dart';
import '../../chat/repositories/chat_repository.dart';
import '../../chat/screens/chat_detail_screen.dart';

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
  final ChatRepository _chatRepo = ChatRepository.instance;

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
          title: Text(
            'Connections',
            style: TextStyle(
              color: NexoraColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicatorColor: NexoraColors.primaryPurple,
            indicatorWeight: 3,
            labelColor: NexoraColors.textPrimary,
            unselectedLabelColor: NexoraColors.textMuted,
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
            tabs: [
              Obx(
                () => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Requests'),
                      if (_connectionService.incomingRequests.isNotEmpty) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: NexoraColors.romanticPink,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            '${_connectionService.incomingRequests.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
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
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: NexoraColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '${_connectionService.connections.length}',
                          style: TextStyle(
                            color: NexoraColors.success,
                            fontSize: 10.sp,
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
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: NexoraColors.glassBackground,
                shape: BoxShape.circle,
                border: Border.all(color: NexoraColors.glassBorder),
              ),
              child: Icon(icon, size: 48.r, color: NexoraColors.textMuted),
            ),
            SizedBox(height: 24.h),
            Text(
              title,
              style: TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: NexoraColors.textMuted, fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(ConnectionRequest request) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: NexoraColors.glassBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: NexoraColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _navigateToProfile(request),
            child: Container(
              width: 56.w,
              height: 56.w,
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
                      request.name.isNotEmpty
                          ? request.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 22.sp,
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
                    style: TextStyle(
                      color: NexoraColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    request.major,
                    style: TextStyle(
                      color: NexoraColors.textSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatTimeAgo(request.timestamp),
                    style: TextStyle(
                      color: NexoraColors.textMuted,
                      fontSize: 11.sp,
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
                    margin: EdgeInsets.all(16.r),
                    borderRadius: 12.r,
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: NexoraColors.textMuted.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: NexoraColors.textMuted,
                    size: 20.r,
                  ),
                ),
              ),

              SizedBox(width: 8.w),

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
                    margin: EdgeInsets.all(16.r),
                    borderRadius: 12.r,
                    icon: Padding(
                      padding: EdgeInsets.only(left: 12.w),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [NexoraColors.success, NexoraColors.accentCyan],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: NexoraColors.success.withOpacity(0.4),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20.r,
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
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: NexoraColors.glassBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: NexoraColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                gradient: NexoraGradients.primaryButton,
                shape: BoxShape.circle,
                border: Border.all(
                  color: NexoraColors.success.withOpacity(0.5),
                  width: 2.w,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  connection.avatar,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      connection.name.isNotEmpty
                          ? connection.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 22.sp,
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
                        style: TextStyle(
                          color: NexoraColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: NexoraColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.link_rounded,
                              size: 10.r,
                              color: NexoraColors.success,
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              'Connected',
                              style: TextStyle(
                                color: NexoraColors.success,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    connection.major,
                    style: TextStyle(
                      color: NexoraColors.textSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Connected ${_formatTimeAgo(connection.timestamp)}',
                    style: TextStyle(
                      color: NexoraColors.textMuted,
                      fontSize: 11.sp,
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
                  onTap: () async {
                    // Always check for existing chat first
                    String? chatId = await _chatRepo.findExistingChat(
                      connection.userId,
                    );
                    chatId ??= await _chatRepo.createChat(connection.userId);
                    Get.to(
                      () => ChatDetailScreen(
                        name: connection.name,
                        avatar: connection.avatar,
                        chatId: chatId,
                        participantId: connection.userId,
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: NexoraColors.primaryPurple.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      color: NexoraColors.primaryPurple,
                      size: 20.r,
                    ),
                  ),
                ),

                SizedBox(width: 8.w),

                // More options
                GestureDetector(
                  onTap: () => _showConnectionOptions(connection),
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: NexoraColors.glassBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: NexoraColors.glassBorder),
                    ),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      color: NexoraColors.textSecondary,
                      size: 20.r,
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
        profile: ProfileModel(
          id: request.userId,
          name: request.name,
          username: request.name,
          email:
              '${request.name.toLowerCase().replaceAll(' ', '.')}@example.com',
          avatar: request.avatar,
          major: request.major,
          bio: 'Hey there! I\'m using Nexora 💜',
          year: '3rd Year',
          interests: const ['Music', 'Tech', 'Coffee', 'Gaming'],
          isOnline: true,
          spotifyTrackName: 'Espresso',
          spotifyArtist: 'Sabrina Carpenter',
        ),
      ),
      transition: Transition.rightToLeftWithFade,
    );
  }

  void _showConnectionOptions(ConnectionRequest connection) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: NexoraColors.midnightDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: NexoraColors.textMuted,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              connection.name,
              style: TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24.h),
            ListTile(
              leading: Icon(
                Icons.person_outline_rounded,
                color: NexoraColors.textPrimary,
                size: 22.r,
              ),
              title: Text(
                'View Profile',
                style: TextStyle(
                  color: NexoraColors.textPrimary,
                  fontSize: 16.sp,
                ),
              ),
              onTap: () {
                Get.back();
                _navigateToProfile(connection);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.block_rounded,
                color: NexoraColors.textMuted,
                size: 22.r,
              ),
              title: Text(
                'Block User',
                style: TextStyle(
                  color: NexoraColors.textMuted,
                  fontSize: 16.sp,
                ),
              ),
              onTap: () {
                Get.back();
                // Block functionality
              },
            ),
            ListTile(
              leading: Icon(
                Icons.person_remove_rounded,
                color: NexoraColors.romanticPink,
                size: 22.r,
              ),
              title: Text(
                'Remove Connection',
                style: TextStyle(
                  color: NexoraColors.romanticPink,
                  fontSize: 16.sp,
                ),
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
                  margin: EdgeInsets.all(16.r),
                  borderRadius: 12.r,
                );
              },
            ),
            SizedBox(height: 16.h),
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
