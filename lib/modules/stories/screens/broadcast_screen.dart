import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/dark_background.dart';
import '../../profile/screens/profile_view_screen.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  // Removed _fabAnimationController since FAB will always be visible.
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  bool _isLoading = false;
  // Removed _isFabVisible since FAB will always be visible.
  String _userName = 'Alex Chen';

  // Dummy posts data
  final List<Map<String, dynamic>> _posts = [
    {
      'id': '1',
      'user': 'Alex Chen',
      'username': '@alexchen',
      'avatar': 'A',
      'time': '5m ago',
      'content':
          'Just finished my final project! So excited to present it tomorrow 🚀 #coding #finalproject #college',
      'likes': 24,
      'comments': 8,
      'shares': 3,
      'liked': false,
      'saved': false,
      'images': [],
      'hashtags': ['#coding', '#finalproject', '#college'],
      'comments_list': [
        {'user': 'Sarah', 'comment': 'Good luck! 🍀', 'time': '2m ago'},
        {'user': 'Mike', 'comment': 'You got this! 💪', 'time': '1m ago'},
      ],
    },
    {
      'id': '2',
      'user': 'Sarah Johnson',
      'username': '@sarahj',
      'avatar': 'S',
      'time': '15m ago',
      'content': 'Library study session with the best squad! 📚☕',
      'likes': 56,
      'comments': 12,
      'shares': 5,
      'liked': true,
      'saved': true,
      'images': [
        'https://picsum.photos/400/300?random=1',
        'https://picsum.photos/400/300?random=2',
      ],
      'hashtags': ['#study', '#library', '#friends'],
      'comments_list': [
        {'user': 'Emma', 'comment': 'Wish I was there!', 'time': '10m ago'},
      ],
    },
    {
      'id': '3',
      'user': 'Mike Wilson',
      'username': '@mikew',
      'avatar': 'M',
      'time': '1h ago',
      'content':
          'Campus coffee shop has the best cold brew! ☕🔥 Who\'s down for a study session?',
      'likes': 42,
      'comments': 15,
      'shares': 2,
      'liked': false,
      'saved': false,
      'images': [
        'https://picsum.photos/400/300?random=3',
        'https://picsum.photos/400/300?random=4',
        'https://picsum.photos/400/300?random=5',
      ],
      'hashtags': ['#coffee', '#study', '#campuslife'],
      'comments_list': [],
    },
    {
      'id': '4',
      'user': 'Emma Davis',
      'username': '@emmad',
      'avatar': 'E',
      'time': '2h ago',
      'content':
          'Just joined the coding club! Anyone else going to the hackathon next month? 💻✨',
      'likes': 89,
      'comments': 23,
      'shares': 8,
      'liked': true,
      'saved': false,
      'images': [],
      'hashtags': ['#coding', '#hackathon', '#tech'],
      'comments_list': [
        {'user': 'Alex', 'comment': 'I\'m going! Team up?', 'time': '1h ago'},
        {'user': 'Rachel', 'comment': 'Sounds awesome!', 'time': '45m ago'},
        {'user': 'Tom', 'comment': 'Count me in!', 'time': '30m ago'},
      ],
    },
    {
      'id': '5',
      'user': 'Rachel Green',
      'username': '@rachelg',
      'avatar': 'R',
      'time': '3h ago',
      'content':
          'Beautiful sunset on campus today! 🌅 So grateful for this view',
      'likes': 112,
      'comments': 18,
      'shares': 12,
      'liked': false,
      'saved': true,
      'images': [
        'https://picsum.photos/400/300?random=6',
        'https://picsum.photos/400/300?random=7',
        'https://picsum.photos/400/300?random=8',
        'https://picsum.photos/400/300?random=9',
      ],
      'hashtags': ['#sunset', '#campus', '#nature'],
      'comments_list': [
        {'user': 'Mike', 'comment': 'Stunning! 📸', 'time': '2h ago'},
      ],
    },
  ];

  // Trending topics with icons

  List<Map<String, dynamic>> get filteredPosts {
    if (_searchQuery.isEmpty) return _posts;
    return _posts.where((post) {
      final content = (post['content'] as String).toLowerCase();
      final user = (post['user'] as String).toLowerCase();
      final username = (post['username'] as String).toLowerCase();
      final hashtags = (post['hashtags'] as List).join(' ').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return content.contains(query) ||
          user.contains(query) ||
          username.contains(query) ||
          hashtags.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    // Removed FAB hide/show scroll listener.
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _createPost() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CreatePostSheet(userName: _userName),
    );
  }

  void _toggleLike(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      final post = filteredPosts[index];
      post['liked'] = !post['liked'];
      post['likes'] = post['liked']
          ? (post['likes'] as int) + 1
          : (post['likes'] as int) - 1;
    });
  }

  void _toggleSave(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      filteredPosts[index]['saved'] = !filteredPosts[index]['saved'];
    });

    final isSaved = filteredPosts[index]['saved'];
    Get.snackbar(
      isSaved ? 'Saved to collection' : 'Removed from collection',
      isSaved ? 'Post saved successfully' : 'Post removed successfully',
      backgroundColor:
          (isSaved ? NexoraColors.accentCyan : NexoraColors.textMuted)
              .withOpacity(0.95),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: Icon(
        isSaved ? Icons.bookmark : Icons.bookmark_border,
        color: Colors.white,
      ),
    );
  }

  void _showPostOptions(Map<String, dynamic> post, int index) {
    final isOwnPost = post['user'] == _userName;

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              NexoraColors.midnightPurple.withOpacity(0.98),
              NexoraColors.midnightDark.withOpacity(0.98),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(
            color: NexoraColors.primaryPurple.withOpacity(0.3),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              if (isOwnPost) ...[
                _buildOptionTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit Post',
                  color: NexoraColors.accentCyan,
                  onTap: () {
                    Get.back();
                    _editPost(post, index);
                  },
                ),
                _buildOptionTile(
                  icon: Icons.delete_outline,
                  label: 'Delete Post',
                  color: NexoraColors.error,
                  onTap: () {
                    Get.back();
                    _confirmDeletePost(index);
                  },
                ),
              ],
              if (!isOwnPost) ...[
                _buildOptionTile(
                  icon: Icons.person_add_outlined,
                  label: 'Follow ${post['user']}',
                  color: NexoraColors.primaryPurple,
                  onTap: () {
                    Get.back();
                    Get.snackbar(
                      'Following',
                      'You are now following ${post['user']}',
                      backgroundColor: NexoraColors.success.withOpacity(0.9),
                      colorText: Colors.white,
                      snackPosition: SnackPosition.TOP,
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                    );
                  },
                ),
                _buildOptionTile(
                  icon: Icons.notifications_off_outlined,
                  label: 'Mute this user',
                  color: NexoraColors.warning,
                  onTap: () {
                    Get.back();
                    Get.snackbar(
                      'Muted',
                      'You won\'t see posts from ${post['user']}',
                      backgroundColor: NexoraColors.warning.withOpacity(0.9),
                      colorText: Colors.white,
                      snackPosition: SnackPosition.TOP,
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                    );
                  },
                ),
                _buildOptionTile(
                  icon: Icons.report_outlined,
                  label: 'Report Post',
                  color: NexoraColors.error,
                  onTap: () {
                    Get.back();
                    _reportPost(post);
                  },
                ),
              ],
              _buildOptionTile(
                icon: Icons.copy_outlined,
                label: 'Copy Text',
                color: NexoraColors.textSecondary,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: post['content']));
                  Get.back();
                  Get.snackbar(
                    'Copied to Clipboard',
                    'Post text copied successfully',
                    backgroundColor: NexoraColors.success.withOpacity(0.9),
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                    margin: const EdgeInsets.all(16),
                    borderRadius: 12,
                    icon: const Icon(Icons.check, color: Colors.white),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: NexoraColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _editPost(Map<String, dynamic> post, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CreatePostSheet(
        userName: _userName,
        initialContent: post['content'],
        isEditing: true,
        onPostCreated: (editedPost) {
          setState(() {
            final actualIndex = _posts.indexWhere((p) => p['id'] == post['id']);
            if (actualIndex != -1) {
              _posts[actualIndex]['content'] = editedPost['content'];
              _posts[actualIndex]['hashtags'] = editedPost['hashtags'];
            }
          });
        },
      ),
    );
  }

  void _confirmDeletePost(int index) {
    final post = filteredPosts[index];

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NexoraColors.error.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: NexoraColors.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Delete Post?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: NexoraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This action cannot be undone. Your post will be permanently removed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: NexoraColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: NexoraColors.textMuted,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NexoraColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Get.back();
                        setState(() {
                          _posts.removeWhere((p) => p['id'] == post['id']);
                        });
                        Get.snackbar(
                          'Post Deleted',
                          'Your post has been removed',
                          backgroundColor: NexoraColors.error.withOpacity(0.9),
                          colorText: Colors.white,
                          snackPosition: SnackPosition.TOP,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 12,
                          icon: const Icon(Icons.delete, color: Colors.white),
                        );
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reportPost(Map<String, dynamic> post) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NexoraColors.error.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color: NexoraColors.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Report Post',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: NexoraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...[
                'Spam',
                'Harassment',
                'Inappropriate Content',
                'False Information',
              ].map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                      Get.snackbar(
                        'Report Submitted',
                        'Thank you for helping keep our community safe',
                        backgroundColor: NexoraColors.success.withOpacity(0.9),
                        colorText: Colors.white,
                        snackPosition: SnackPosition.TOP,
                        margin: const EdgeInsets.all(16),
                        borderRadius: 12,
                        duration: const Duration(seconds: 2),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        reason,
                        style: const TextStyle(
                          color: NexoraColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: NexoraColors.textMuted, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComments(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CommentsSheet(
        post: post,
        userName: _userName,
        onCommentAdded: (comment) {
          setState(() {
            final postIndex = _posts.indexWhere((p) => p['id'] == post['id']);
            if (postIndex != -1) {
              _posts[postIndex]['comments_list'].add(comment);
              _posts[postIndex]['comments'] =
                  (_posts[postIndex]['comments'] as int) + 1;
            }
          });
        },
      ),
    );
  }

  void _openUserProfile(Map<String, dynamic> post) {
    HapticFeedback.lightImpact();
    Get.to(
      () => ProfileViewScreen(
        userId: post['id'].toString(),
        name: post['user'],
        avatar: post['avatar'],
        bio: 'Campus community member 💜',
        year: '3rd Year',
        major: 'Computer Science',
        interests: const ['Coding', 'Music', 'Gaming'],
        isOnline: true,
      ),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 400),
    );
  }

  void _openImageViewer(List<String> images, int initialIndex) {
    HapticFeedback.lightImpact();
    Get.to(
      () => ImageViewerScreen(images: images, initialIndex: initialIndex),
      transition: Transition.zoom,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _refreshFeed() async {
    setState(() => _isLoading = true);
    _refreshController.forward();
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
    });
    _refreshController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return DarkBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshFeed,
            color: NexoraColors.primaryPurple,
            backgroundColor: NexoraColors.midnightPurple,
            displacement: 40,
            edgeOffset: 20,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Enhanced App Bar
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          NexoraColors.midnightDark.withOpacity(0.9),
                          NexoraColors.midnightDark.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  title: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        NexoraColors.primaryPurple,
                        NexoraColors.romanticPink,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'Nexora',
                      style: NexoraTextStyles.headline1.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    // height must account for vertical padding (8 top + 16 bottom)
                    // plus the 50px search bar, so total 74 to avoid overflow.
                    preferredSize: const Size.fromHeight(74),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: _buildSearchBar(),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Trending Stories Section
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Feed Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                NexoraColors.primaryPurple.withOpacity(0.3),
                                NexoraColors.primaryPurple.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.grid_view_rounded,
                            color: NexoraColors.primaryPurple,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Latest Updates',
                          style: TextStyle(
                            color: NexoraColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${filteredPosts.length} posts',
                          style: TextStyle(
                            color: NexoraColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Feed
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _refreshController,
                    builder: (context, _) => _buildFeed(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createPost,
          backgroundColor: NexoraColors.primaryPurple,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Create Post',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: NexoraColors.glassBackground,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: NexoraColors.primaryPurple.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: NexoraColors.primaryPurple.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: NexoraColors.primaryPurple, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 15,
              ),
              decoration: const InputDecoration(
                hintText: 'Search posts, users, hashtags...',
                hintStyle: TextStyle(
                  color: NexoraColors.textMuted,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: NexoraColors.textMuted.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: NexoraColors.textMuted,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeed() {
    final displayPosts = filteredPosts;

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(NexoraColors.primaryPurple),
          ),
        ),
      );
    }

    if (displayPosts.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptySearch();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: displayPosts.length,
      itemBuilder: (context, index) {
        final post = displayPosts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 500 + (index * 100)),
            curve: Curves.easeOutCubic,
            builder: (context, double value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: _buildPostCard(post, index),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: NexoraColors.glassBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: NexoraColors.textMuted.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No posts found',
              style: TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(color: NexoraColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: NexoraColors.primaryPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    return GestureDetector(
      onDoubleTap: () => _toggleLike(index),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header
            Row(
              children: [
                GestureDetector(
                  onTap: () => _openUserProfile(post),
                  child: Stack(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: NexoraGradients.primaryButton,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: NexoraColors.primaryPurple.withOpacity(
                                0.3,
                              ),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            post['avatar'] ?? post['user'][0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: NexoraColors.midnightDark,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openUserProfile(post),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post['user']?.toString() ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: NexoraColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: NexoraColors.primaryPurple.withOpacity(
                                  0.15,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                post['username'].toString(),
                                style: const TextStyle(
                                  color: NexoraColors.primaryPurple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: NexoraColors.textMuted,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              post['time']?.toString() ?? '',
                              style: TextStyle(
                                color: NexoraColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: NexoraColors.glassBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.more_vert),
                    color: NexoraColors.textMuted,
                    iconSize: 20,
                    onPressed: () => _showPostOptions(post, index),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Content with improved styling
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                post['content']?.toString() ?? '',
                style: const TextStyle(
                  color: NexoraColors.textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Enhanced Hashtags
            if (post['hashtags'] != null &&
                (post['hashtags'] as List).isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (post['hashtags'] as List).map<Widget>((tag) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _searchQuery = tag.toString().replaceAll('#', '');
                        _searchController.text = _searchQuery;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: NexoraColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: NexoraColors.primaryPurple.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        tag.toString(),
                        style: const TextStyle(
                          color: NexoraColors.primaryPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),

            // Images
            if ((post['images'] as List).isNotEmpty)
              _buildImageGrid(post['images'] as List<String>),

            const SizedBox(height: 16),

            // Stats row with improved design
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildStatIcon(
                      post['liked'] == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      post['liked'] == true
                          ? NexoraColors.romanticPink
                          : NexoraColors.textMuted,
                      post['likes'].toString(),
                      () => _toggleLike(index),
                    ),
                    const SizedBox(width: 20),
                    _buildStatIcon(
                      Icons.chat_bubble_outline,
                      NexoraColors.textMuted,
                      post['comments'].toString(),
                      () => _showComments(post),
                    ),
                    const SizedBox(width: 20),
                    _buildStatIcon(
                      Icons.share_outlined,
                      NexoraColors.textMuted,
                      post['shares'].toString(),
                      () => _showShareSheet(post),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _toggleSave(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: post['saved'] == true
                          ? NexoraColors.accentCyan.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      post['saved'] == true
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: post['saved'] == true
                          ? NexoraColors.accentCyan
                          : NexoraColors.textMuted,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),

            // Comments preview with improved styling
            if ((post['comments_list'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: NexoraColors.glassBorder, height: 1),
              const SizedBox(height: 12),
              ...List.generate(
                (post['comments_list'] as List).length.clamp(0, 2),
                (commentIndex) {
                  final comment = post['comments_list'][commentIndex];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: NexoraGradients.primaryButton,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              comment['user'][0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: comment['user'],
                                      style: const TextStyle(
                                        color: NexoraColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: '  •  ',
                                      style: TextStyle(
                                        color: NexoraColors.textMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                    TextSpan(
                                      text: comment['time'],
                                      style: TextStyle(
                                        color: NexoraColors.textMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                comment['comment'],
                                style: const TextStyle(
                                  color: NexoraColors.textSecondary,
                                  fontSize: 13,
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
              if ((post['comments_list'] as List).length > 2)
                GestureDetector(
                  onTap: () => _showComments(post),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          "View all ${post['comments']} comments",
                          style: const TextStyle(
                            color: NexoraColors.primaryPurple,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward,
                          color: NexoraColors.primaryPurple,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatIcon(
    IconData icon,
    Color color,
    String count,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            count,
            style: TextStyle(
              color: NexoraColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<String> images) {
    if (images.length == 1) {
      return GestureDetector(
        onTap: () => _openImageViewer(images, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.network(
                images[0],
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_out_map, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (images.length == 2) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openImageViewer(images, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  images[0],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => _openImageViewer(images, 1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  images[1],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          GestureDetector(
            onTap: () => _openImageViewer(images, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                images[0],
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _openImageViewer(images, 1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      images[1],
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openImageViewer(images, 2),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          images[2],
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (images.length > 3)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black.withOpacity(0.6),
                            ),
                            child: Center(
                              child: Text(
                                "+${images.length - 3}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  void _showShareSheet(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: NexoraGradients.mainBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(
            color: NexoraColors.primaryPurple.withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NexoraColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "Share Post",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: NexoraColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  Icons.send,
                  "Direct",
                  NexoraColors.primaryPurple,
                  () {
                    Get.back();
                    _shareToDirect(post);
                  },
                ),
                _buildShareOption(
                  Icons.group,
                  "Campus",
                  NexoraColors.romanticPink,
                  () {
                    Get.back();
                    _shareToCampus(post);
                  },
                ),
                _buildShareOption(
                  Icons.copy,
                  "Copy",
                  NexoraColors.accentCyan,
                  () {
                    Get.back();
                    _copyToClipboard(post);
                  },
                ),
                _buildShareOption(
                  Icons.more_horiz,
                  "More",
                  NexoraColors.textMuted,
                  () {
                    Get.back();
                    _shareMore(post);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Share to',
                style: TextStyle(
                  color: NexoraColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildShareContact('Sarah', NexoraColors.romanticPink, post),
                  _buildShareContact('Mike', NexoraColors.primaryPurple, post),
                  _buildShareContact('Emma', NexoraColors.accentCyan, post),
                  _buildShareContact(
                    'Alex',
                    NexoraColors.primaryPurple.withOpacity(0.6),
                    post,
                  ),
                  _buildShareContact(
                    'Jordan',
                    NexoraColors.primaryPurple,
                    post,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _shareToDirect(Map<String, dynamic> post) {
    HapticFeedback.lightImpact();
    Get.snackbar(
      'Share',
      'Select a contact to share with',
      backgroundColor: NexoraColors.primaryPurple.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _shareToCampus(Map<String, dynamic> post) {
    HapticFeedback.lightImpact();
    Get.snackbar(
      'Shared to Campus!',
      'Your post is now visible to the campus community',
      backgroundColor: NexoraColors.romanticPink.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _copyToClipboard(Map<String, dynamic> post) {
    Clipboard.setData(ClipboardData(text: post['content']));
    HapticFeedback.lightImpact();
    Get.snackbar(
      'Copied!',
      'Post content copied to clipboard',
      backgroundColor: NexoraColors.accentCyan.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _shareMore(Map<String, dynamic> post) {
    HapticFeedback.lightImpact();
    Get.snackbar(
      'Share',
      'More sharing options coming soon!',
      backgroundColor: NexoraColors.textMuted.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  Widget _buildShareContact(
    String name,
    Color color,
    Map<String, dynamic> post,
  ) {
    return GestureDetector(
      onTap: () {
        Get.back();
        HapticFeedback.lightImpact();
        Get.snackbar(
          'Shared!',
          'Post shared with $name',
          backgroundColor: color.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 1),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(
                color: NexoraColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: NexoraColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Create Post Sheet (Enhanced)
class CreatePostSheet extends StatefulWidget {
  final Function(Map<String, dynamic>)? onPostCreated;
  final String? userName;
  final String? initialContent;
  final bool isEditing;

  const CreatePostSheet({
    this.onPostCreated,
    this.userName,
    this.initialContent,
    this.isEditing = false,
    super.key,
  });

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet>
    with SingleTickerProviderStateMixin {
  late TextEditingController _postController;
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  String _visibility = 'Public';
  bool _isPosting = false;
  final List<String> _availableHashtags = [
    '#campuslife',
    '#study',
    '#college',
    '#friends',
    '#weekend',
    '#food',
    '#coffee',
    '#library',
    '#exam',
    '#fun',
  ];

  @override
  void initState() {
    super.initState();
    _postController = TextEditingController(text: widget.initialContent ?? '');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _focusNode.requestFocus();
  }

  void _addHashtag(String hashtag) {
    final currentText = _postController.text;
    if (!currentText.contains(hashtag)) {
      _postController.text = '$currentText $hashtag';
      _postController.selection = TextSelection.fromPosition(
        TextPosition(offset: _postController.text.length),
      );
      _animationController.forward().then(
        (_) => _animationController.reverse(),
      );
    }
    setState(() {});
  }

  void _createPost() {
    if (_postController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);

    final content = _postController.text.trim();
    final hashtagRegex = RegExp(r'#\w+');
    final hashtags = hashtagRegex
        .allMatches(content)
        .map((m) => m.group(0)!)
        .toList();

    final username =
        '@${(widget.userName ?? 'You').toLowerCase().replaceAll(' ', '.')}';

    final postData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'user': widget.userName ?? 'You',
      'username': username,
      'avatar': (widget.userName ?? 'You')[0],
      'time': 'Just now',
      'content': content,
      'hashtags': hashtags,
      'images': <String>[],
      'likes': 0,
      'comments': 0,
      'shares': 0,
      'liked': false,
      'saved': false,
      'comments_list': <Map<String, dynamic>>[],
    };

    if (widget.onPostCreated != null) {
      widget.onPostCreated!(postData);
    }

    Get.back();
    HapticFeedback.mediumImpact();

    Get.snackbar(
      widget.isEditing ? 'Post Updated!' : 'Post Created!',
      widget.isEditing
          ? 'Your post has been updated successfully'
          : 'Your post is now live on the campus feed',
      backgroundColor: NexoraColors.success.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        gradient: NexoraGradients.mainBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: NexoraColors.primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Enhanced Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NexoraColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: NexoraColors.glassBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: NexoraColors.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.isEditing ? "Edit Post" : "Create Post",
                      style: const TextStyle(
                        color: NexoraColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1 + (_animationController.value * 0.1),
                          child: child,
                        );
                      },
                      child: GestureDetector(
                        onTap:
                            _postController.text.trim().isNotEmpty &&
                                !_isPosting
                            ? _createPost
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: _postController.text.trim().isNotEmpty
                                ? NexoraGradients.primaryButton
                                : null,
                            color: _postController.text.trim().isEmpty
                                ? NexoraColors.textMuted.withOpacity(0.3)
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _postController.text.trim().isNotEmpty
                                ? [
                                    BoxShadow(
                                      color: NexoraColors.primaryPurple
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: _isPosting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  widget.isEditing ? "Save" : "Post",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // User info with enhanced visibility picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: NexoraGradients.primaryButton,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: NexoraColors.primaryPurple.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (widget.userName ?? 'U').isNotEmpty
                          ? (widget.userName ?? 'U')[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName ?? 'You',
                        style: const TextStyle(
                          color: NexoraColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _showVisibilityPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: NexoraColors.glassBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: NexoraColors.primaryPurple.withOpacity(
                                0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _visibility == 'Public'
                                    ? Icons.public
                                    : _visibility == 'Campus'
                                    ? Icons.school
                                    : Icons.lock,
                                size: 14,
                                color: NexoraColors.accentCyan,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _visibility,
                                style: const TextStyle(
                                  color: NexoraColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_drop_down,
                                size: 16,
                                color: NexoraColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Post content with character count
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _postController,
                        focusNode: _focusNode,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          color: NexoraColors.textPrimary,
                          fontSize: 16,
                          height: 1.4,
                        ),
                        decoration: const InputDecoration(
                          hintText:
                              "What's on your mind? Share with the campus community...",
                          hintStyle: TextStyle(
                            color: NexoraColors.textMuted,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add hashtags to reach more people',
                          style: TextStyle(
                            color: NexoraColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _postController.text.length > 500
                                ? NexoraColors.error.withOpacity(0.1)
                                : NexoraColors.glassBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_postController.text.length}/500',
                            style: TextStyle(
                              color: _postController.text.length > 500
                                  ? NexoraColors.error
                                  : NexoraColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Quick hashtags with improved design
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableHashtags.length,
              itemBuilder: (context, index) {
                final hashtag = _availableHashtags[index];
                final isSelected = _postController.text.contains(hashtag);
                return GestureDetector(
                  onTap: () => _addHashtag(hashtag),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                NexoraColors.primaryPurple,
                                NexoraColors.deepPurple,
                              ],
                            )
                          : null,
                      color: isSelected ? null : NexoraColors.glassBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : NexoraColors.glassBorder,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: NexoraColors.primaryPurple.withOpacity(
                                  0.3,
                                ),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      hashtag,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : NexoraColors.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Enhanced bottom action bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: NexoraColors.midnightDark.withOpacity(0.95),
              border: Border(
                top: BorderSide(
                  color: NexoraColors.primaryPurple.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    Icons.image_outlined,
                    'Photo',
                    NexoraColors.accentCyan,
                  ),
                  _buildActionButton(
                    Icons.videocam_outlined,
                    'Video',
                    NexoraColors.romanticPink,
                  ),
                  _buildActionButton(
                    Icons.poll_outlined,
                    'Poll',
                    NexoraColors.primaryPurple,
                  ),
                  _buildActionButton(
                    Icons.location_on_outlined,
                    'Location',
                    NexoraColors.success,
                  ),
                  _buildActionButton(
                    Icons.emoji_emotions_outlined,
                    'Feeling',
                    NexoraColors.warning,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Get.snackbar(
          'Coming Soon',
          'The $label feature is under development',
          backgroundColor: color.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 1),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showVisibilityPicker() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: NexoraGradients.mainBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NexoraColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Who can see this post?',
              style: TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildVisibilityOption(
              Icons.public,
              'Public',
              'Anyone can see this post',
              _visibility == 'Public',
              () {
                setState(() => _visibility = 'Public');
                Get.back();
              },
            ),
            _buildVisibilityOption(
              Icons.school,
              'Campus Only',
              'Only people from your campus',
              _visibility == 'Campus',
              () {
                setState(() => _visibility = 'Campus');
                Get.back();
              },
            ),
            _buildVisibilityOption(
              Icons.lock,
              'Private',
              'Only your friends',
              _visibility == 'Friends',
              () {
                setState(() => _visibility = 'Friends');
                Get.back();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityOption(
    IconData icon,
    String label,
    String description,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    NexoraColors.primaryPurple.withOpacity(0.2),
                    NexoraColors.primaryPurple.withOpacity(0.1),
                  ],
                )
              : null,
          color: isSelected ? null : NexoraColors.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? NexoraColors.primaryPurple
                : NexoraColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? NexoraColors.primaryPurple.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? NexoraColors.primaryPurple
                    : NexoraColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? NexoraColors.primaryPurple
                          : NexoraColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: NexoraColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: NexoraColors.primaryPurple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

// Comments Sheet (Enhanced)
class CommentsSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final String userName;
  final Function(Map<String, dynamic>)? onCommentAdded;

  const CommentsSheet({
    required this.post,
    required this.userName,
    this.onCommentAdded,
    super.key,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _comments = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _comments = List<Map<String, dynamic>>.from(
      widget.post['comments_list'] ?? [],
    );
  }

  void _submitComment() {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    final newComment = {
      'user': widget.userName,
      'comment': _commentController.text.trim(),
      'time': 'Just now',
    };

    setState(() {
      _comments.insert(0, newComment);
      _isSubmitting = false;
    });

    if (widget.onCommentAdded != null) {
      widget.onCommentAdded!(newComment);
    }

    _commentController.clear();
    HapticFeedback.lightImpact();

    Get.snackbar(
      'Comment Added',
      'Your comment was posted successfully',
      backgroundColor: NexoraColors.accentCyan.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        gradient: NexoraGradients.mainBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: NexoraColors.primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Enhanced Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NexoraColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            NexoraColors.primaryPurple.withOpacity(0.2),
                            NexoraColors.primaryPurple.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        color: NexoraColors.primaryPurple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Comments (${widget.post['comments']})",
                      style: const TextStyle(
                        color: NexoraColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: NexoraColors.glassBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: NexoraColors.textMuted,
                          size: 20,
                        ),
                      ),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Comments list
          Expanded(
            child: _comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: NexoraColors.glassBackground,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: NexoraColors.textMuted.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No comments yet',
                          style: TextStyle(
                            color: NexoraColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to start the conversation!',
                          style: TextStyle(
                            color: NexoraColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildCommentItem(comment),
                      );
                    },
                  ),
          ),

          // Enhanced comment input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: NexoraColors.midnightDark.withOpacity(0.95),
              border: Border(
                top: BorderSide(
                  color: NexoraColors.primaryPurple.withOpacity(0.2),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: NexoraGradients.primaryButton,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: NexoraColors.primaryPurple.withOpacity(0.3),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.userName.isNotEmpty
                            ? widget.userName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: NexoraColors.glassBackground,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: NexoraColors.primaryPurple.withOpacity(0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        style: const TextStyle(
                          color: NexoraColors.textPrimary,
                          fontSize: 14,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: "Add a comment...",
                          hintStyle: TextStyle(
                            color: NexoraColors.textMuted.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          suffixIcon: _commentController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _commentController.clear();
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: NexoraColors.textMuted.withOpacity(
                                        0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: NexoraColors.textMuted,
                                      size: 16,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        onSubmitted: (_) => _submitComment(),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap:
                        _isSubmitting || _commentController.text.trim().isEmpty
                        ? null
                        : _submitComment,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: _commentController.text.trim().isEmpty
                            ? LinearGradient(
                                colors: [
                                  NexoraColors.textMuted.withOpacity(0.3),
                                  NexoraColors.textMuted.withOpacity(0.2),
                                ],
                              )
                            : NexoraGradients.primaryButton,
                        shape: BoxShape.circle,
                        boxShadow: _commentController.text.trim().isEmpty
                            ? null
                            : [
                                BoxShadow(
                                  color: NexoraColors.primaryPurple.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 8,
                                ),
                              ],
                      ),
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                color: _commentController.text.trim().isEmpty
                                    ? NexoraColors.textMuted.withOpacity(0.5)
                                    : Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: NexoraGradients.primaryButton,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              comment['user'][0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NexoraColors.glassBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment['user'],
                          style: const TextStyle(
                            color: NexoraColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment['time'],
                          style: TextStyle(
                            color: NexoraColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment['comment'],
                      style: const TextStyle(
                        color: NexoraColors.textSecondary,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                      child: const Row(
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 14,
                            color: NexoraColors.textMuted,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Like',
                            style: TextStyle(
                              color: NexoraColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        _focusNode.requestFocus();
                        _commentController.text = '@${comment['user']} ';
                        _commentController
                            .selection = TextSelection.fromPosition(
                          TextPosition(offset: _commentController.text.length),
                        );
                      },
                      child: const Text(
                        'Reply',
                        style: TextStyle(
                          color: NexoraColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Image Viewer Screen (Enhanced)
class ImageViewerScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageViewerScreen({
    required this.images,
    this.initialIndex = 0,
    super.key,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  double _scale = 1.0;
  double _previousScale = 1.0;
  late AnimationController _likeAnimationController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _doubleTapLike() {
    _likeAnimationController.forward().then(
      (_) => _likeAnimationController.reverse(),
    );
    HapticFeedback.heavyImpact();
    Get.snackbar(
      'Liked',
      'Added to your likes',
      backgroundColor: NexoraColors.romanticPink.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(milliseconds: 800),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 22),
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 22),
            ),
            onPressed: () => _showImageOptions(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Image PageView with double tap like
          GestureDetector(
            onDoubleTap: _doubleTapLike,
            onScaleStart: (details) {
              _previousScale = _scale;
            },
            onScaleUpdate: (details) {
              setState(() {
                _scale = (_previousScale * details.scale).clamp(1.0, 4.0);
              });
            },
            onScaleEnd: (details) {
              if (_scale < 1.2) {
                setState(() {
                  _scale = 1.0;
                });
              }
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _scale = 1.0;
                });
              },
              itemBuilder: (context, index) {
                return Center(
                  child: Transform.scale(
                    scale: _scale,
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation(
                              NexoraColors.primaryPurple,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: NexoraColors.glassBackground,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: NexoraColors.textMuted,
                              size: 64,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Double tap like animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _likeAnimationController,
              builder: (context, child) {
                return Opacity(
                  opacity: 1 - _likeAnimationController.value,
                  child: Transform.scale(
                    scale: 1 + (_likeAnimationController.value * 0.5),
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Icon(
                          Icons.favorite,
                          color: NexoraColors.romanticPink.withOpacity(0.8),
                          size: 100 * (1 + _likeAnimationController.value),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Enhanced page indicator
          if (widget.images.length > 1)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 30 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: _currentIndex == index
                          ? const LinearGradient(
                              colors: [
                                NexoraColors.primaryPurple,
                                NexoraColors.romanticPink,
                              ],
                            )
                          : null,
                      color: _currentIndex == index
                          ? null
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: _currentIndex == index
                          ? [
                              BoxShadow(
                                color: NexoraColors.primaryPurple.withOpacity(
                                  0.5,
                                ),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),

          // Enhanced image counter
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: NexoraColors.primaryPurple.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Enhanced bottom actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomAction(Icons.download_outlined, 'Save'),
                    _buildBottomAction(Icons.share_outlined, 'Share'),
                    _buildBottomAction(Icons.favorite_border, 'Like'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Get.snackbar(
          label,
          'Feature coming soon!',
          backgroundColor: NexoraColors.primaryPurple.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 1),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showImageOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: NexoraGradients.mainBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: NexoraColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildOptionItem(
                Icons.download_outlined,
                'Save to device',
                NexoraColors.accentCyan,
                () {
                  Get.back();
                  Get.snackbar(
                    'Saved',
                    'Image saved to your device',
                    backgroundColor: NexoraColors.success.withOpacity(0.9),
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                  );
                },
              ),
              _buildOptionItem(
                Icons.share_outlined,
                'Share image',
                NexoraColors.primaryPurple,
                () {
                  Get.back();
                },
              ),
              _buildOptionItem(
                Icons.copy_outlined,
                'Copy image link',
                NexoraColors.romanticPink,
                () {
                  Get.back();
                  Clipboard.setData(
                    ClipboardData(text: widget.images[_currentIndex]),
                  );
                  Get.snackbar(
                    'Copied',
                    'Image link copied to clipboard',
                    backgroundColor: NexoraColors.accentCyan.withOpacity(0.9),
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                  );
                },
              ),
              _buildOptionItem(
                Icons.flag_outlined,
                'Report image',
                NexoraColors.error,
                () {
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: NexoraColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
