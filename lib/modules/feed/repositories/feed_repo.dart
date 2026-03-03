import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/feed_model.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../../notifications/models/notification_model.dart';
import '../../profile/repositories/user_repository.dart';

abstract class IPostRepository {
  Stream<List<PostModel>> getPostsStream({int limit = 50});
  Future<List<PostModel>> getPosts({int page = 1, int limit = 10});
  Future<PostModel> getPostById(String id);
  Future<List<PostModel>> searchPosts(String query);
  Future<PostModel> createPost(PostModel post);
  Future<PostModel> updatePost(PostModel post);
  Future<void> deletePost(String id);
  Future<void> toggleLike(String postId, String userId);
  Future<void> likePost(String postId, String userId);
  Future<void> toggleSave(String postId, String userId);
  Future<CommentModel> addComment(String postId, CommentModel comment);
  Future<void> deleteComment(String postId, String commentId);
  Future<List<PostModel>> getPostsByUser(String userId);
  Future<List<String>> getTrendingHashtags();
  Future<void> voteInPoll(String postId, int optionIndex, String userId);
}

class PostRepository implements IPostRepository {
  static final PostRepository instance = PostRepository();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _postsCollection;

  PostRepository() {
    _postsCollection = _firestore.collection('feed');
  }

  @override
  Stream<List<PostModel>> getPostsStream({int limit = 50}) {
    return _postsCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Future<List<PostModel>> getPosts({int page = 1, int limit = 10}) async {
    try {
      final querySnapshot = await _postsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit * page) // Simple pagination for now
          .get();

      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting posts: $e');
      return [];
    }
  }

  @override
  Future<PostModel> getPostById(String id) async {
    final doc = await _postsCollection.doc(id).get();
    if (!doc.exists) throw Exception('Post not found');
    return PostModel.fromFirestore(doc);
  }

  @override
  Future<List<PostModel>> searchPosts(String query) async {
    // Firestore doesn't support full-text search directly without third-party services.
    // However, we can do a simple prefix search or client-side filtering.
    // For now, let's fetch recent posts and filter client-side as a fallback.
    final posts = await getPosts(limit: 50);
    final lowercaseQuery = query.toLowerCase();

    return posts.where((post) {
      return post.content.toLowerCase().contains(lowercaseQuery) ||
          post.user.toLowerCase().contains(lowercaseQuery) ||
          post.username.toLowerCase().contains(lowercaseQuery) ||
          post.hashtags.any(
            (tag) => tag.toLowerCase().contains(lowercaseQuery),
          );
    }).toList();
  }

  @override
  Future<PostModel> createPost(PostModel post) async {
    final docRef = await _postsCollection.add(post.toJson());
    final doc = await docRef.get();
    final postId = docRef.id;

    // Increment the user's post count
    if (post.userId.isNotEmpty) {
      await _firestore.collection('users').doc(post.userId).update({
        'posts': FieldValue.increment(1),
      });

      // Notify connections about new post
      try {
        final connectionsSnapshot = await _firestore
            .collection('users')
            .doc(post.userId)
            .collection('connections')
            .get();

        if (connectionsSnapshot.docs.isNotEmpty) {
          final notification = NotificationModel(
            id: '',
            type: NotificationType.feed,
            userId: post.userId,
            userName: post.displayName,
            userAvatar: post.avatar,
            message: 'shared a new post',
            timestamp: DateTime.now(),
            targetId: postId,
          );

          for (var doc in connectionsSnapshot.docs) {
            final connectionId = doc.id;
            NotificationRepository().addNotification(
              notification,
              connectionId,
            );
          }
        }
      } catch (e) {
        print('Error notifying connections: $e');
      }
    }

    return PostModel.fromFirestore(doc);
  }

  @override
  Future<PostModel> updatePost(PostModel post) async {
    await _postsCollection.doc(post.id).update(post.toJson());
    return post;
  }

  @override
  Future<void> deletePost(String id) async {
    // Fetch post to get the userId for decrementing counter
    final doc = await _postsCollection.doc(id).get();
    await _postsCollection.doc(id).delete();

    // Decrement user's post count
    if (doc.exists) {
      final userId =
          (doc.data() as Map<String, dynamic>?)?['userId'] as String?;
      if (userId != null && userId.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update({
          'posts': FieldValue.increment(-1),
        });
      }
    }
  }

  @override
  Future<void> toggleLike(String postId, String userId) async {
    final doc = await _postsCollection.doc(postId).get();
    if (!doc.exists) throw Exception('Post not found');

    final post = PostModel.fromFirestore(doc);
    final isLiked = post.likedBy.contains(userId);

    if (isLiked) {
      // Unlike
      await _postsCollection.doc(postId).update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likes': FieldValue.increment(-1),
      });
    } else {
      // Like
      await _postsCollection.doc(postId).update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likes': FieldValue.increment(1),
      });

      // Send notification to post owner
      if (post.userId != userId) {
        final likingUser = await UserRepository.instance.getUserById(userId);
        final notification = NotificationModel(
          id: '',
          type: NotificationType.like,
          userId: userId,
          userName: likingUser?.name ?? 'Someone',
          userAvatar: likingUser?.avatar,
          message: 'liked your post',
          timestamp: DateTime.now(),
          targetId: postId,
        );
        NotificationRepository().addNotification(notification, post.userId);
      }
    }
  }

  @override
  Future<void> likePost(String postId, String userId) async {
    final doc = await _postsCollection.doc(postId).get();
    if (!doc.exists) return;

    final post = PostModel.fromFirestore(doc);
    if (!post.likedBy.contains(userId)) {
      await _postsCollection.doc(postId).update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likes': FieldValue.increment(1),
      });

      // Send notification
      if (post.userId != userId) {
        final likingUser = await UserRepository.instance.getUserById(userId);
        final notification = NotificationModel(
          id: '',
          type: NotificationType.like,
          userId: userId,
          userName: likingUser?.name ?? 'Someone',
          userAvatar: likingUser?.avatar,
          message: 'liked your post',
          timestamp: DateTime.now(),
          targetId: postId,
        );
        NotificationRepository().addNotification(notification, post.userId);
      }
    }
  }

  @override
  Future<void> toggleSave(String postId, String userId) async {
    final doc = await _postsCollection.doc(postId).get();
    if (!doc.exists) throw Exception('Post not found');

    final post = PostModel.fromFirestore(doc);
    final isSaved = post.savedBy.contains(userId);

    if (isSaved) {
      await _postsCollection.doc(postId).update({
        'savedBy': FieldValue.arrayRemove([userId]),
      });
    } else {
      await _postsCollection.doc(postId).update({
        'savedBy': FieldValue.arrayUnion([userId]),
      });
    }
  }

  @override
  Future<CommentModel> addComment(String postId, CommentModel comment) async {
    final newComment = comment.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
    );

    await _postsCollection.doc(postId).update({
      'comments_list': FieldValue.arrayUnion([newComment.toJson()]),
      'comments': FieldValue.increment(1),
    });

    final postDoc = await _postsCollection.doc(postId).get();
    if (!postDoc.exists) return newComment;

    final post = PostModel.fromFirestore(postDoc);

    // 1. Send notification to post owner
    if (post.userId != comment.userId) {
      final notification = NotificationModel(
        id: '',
        type: NotificationType.comment,
        userId: comment.userId,
        userName: comment.displayName,
        userAvatar: comment.avatar,
        message: 'commented: ${comment.comment}',
        timestamp: DateTime.now(),
        targetId: postId,
      );
      NotificationRepository().addNotification(notification, post.userId);
    }

    // 2. Handle mentions
    final mentionRegex = RegExp(r'@(\w+)');
    final mentions = mentionRegex.allMatches(comment.comment);
    final uniqueUsernames = mentions
        .map((m) => m.group(1)!.toLowerCase())
        .toSet()
        .where((username) => username != comment.displayName.toLowerCase());

    for (final username in uniqueUsernames) {
      final mentionedUser = await UserRepository.instance.getUserByUsername(
        username,
      );
      if (mentionedUser != null && mentionedUser.id != comment.userId) {
        // Only send mention notification if it's not the already-notified post owner
        // (Unless you want them to get both, but usually one is enough.
        // Let's send mention notification to anyone tagged who isn't the commenter)
        final mentionNotification = NotificationModel(
          id: '',
          type: NotificationType.mention,
          userId: comment.userId,
          userName: comment.displayName,
          userAvatar: comment.avatar,
          message: 'mentioned you in a comment: ${comment.comment}',
          timestamp: DateTime.now(),
          targetId: postId,
        );
        NotificationRepository().addNotification(
          mentionNotification,
          mentionedUser.id,
        );
      }
    }

    return newComment;
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    final doc = await _postsCollection.doc(postId).get();
    if (!doc.exists) return;

    final post = PostModel.fromFirestore(doc);
    final updatedComments = post.commentsList
        .where((c) => c.id != commentId)
        .toList();

    await _postsCollection.doc(postId).update({
      'comments_list': updatedComments.map((c) => c.toJson()).toList(),
      'comments': FieldValue.increment(-1),
    });
  }

  @override
  Future<List<PostModel>> getPostsByUser(String userId) async {
    final querySnapshot = await _postsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<String>> getTrendingHashtags() async {
    // This would typically be a cloud function or separate aggregation.
    // For now, client-side aggregation on the latest 50 posts.
    final posts = await getPosts(limit: 50);
    final hashtagCount = <String, int>{};

    for (final post in posts) {
      for (final hashtag in post.hashtags) {
        hashtagCount[hashtag] = (hashtagCount[hashtag] ?? 0) + 1;
      }
    }

    final sortedHashtags = hashtagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedHashtags.take(10).map((e) => e.key).toList();
  }

  @override
  Future<void> voteInPoll(String postId, int optionIndex, String userId) async {
    await _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(_postsCollection.doc(postId));
      if (!postDoc.exists) throw Exception('Post not found');

      final post = PostModel.fromFirestore(postDoc);
      final poll = post.poll;
      if (poll == null) throw Exception('Post has no poll');

      final updatedVotes = List<int>.from(poll.votes);
      final updatedVotedBy = Map<String, int>.from(poll.votedBy);

      if (updatedVotedBy.containsKey(userId)) {
        final previousVoteIndex = updatedVotedBy[userId]!;
        if (previousVoteIndex == optionIndex) {
          // Unvote (toggle off)
          updatedVotes[previousVoteIndex]--;
          updatedVotedBy.remove(userId);
        } else {
          // Change vote
          updatedVotes[previousVoteIndex]--;
          updatedVotes[optionIndex]++;
          updatedVotedBy[userId] = optionIndex;
        }
      } else {
        // New vote
        updatedVotes[optionIndex]++;
        updatedVotedBy[userId] = optionIndex;
      }

      transaction.update(_postsCollection.doc(postId), {
        'poll.votes': updatedVotes,
        'poll.votedBy': updatedVotedBy,
      });
    });
  }
}
