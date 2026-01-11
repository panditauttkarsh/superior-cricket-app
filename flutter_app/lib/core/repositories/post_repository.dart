import '../config/supabase_config.dart';
import '../../features/feed/domain/models/post_model.dart';

class PostRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<Post>> getPosts({
    String? userId,
    int? limit,
    DateTime? before,
  }) async {
    try {
      dynamic query = _supabase
          .from('posts')
          .select('''
            *,
            profiles:user_id (
              id,
              name,
              profile_image_url,
              email
            ),
            post_likes!left (
              user_id
            ),
            post_comments (
              id,
              user_id,
              content,
              created_at,
              profiles:user_id (
                id,
                name,
                profile_image_url,
                email
              )
            )
          ''');

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      query = query.order('created_at', ascending: false);

      final response = await query;
      final currentUserId = _supabase.auth.currentUser?.id;

      return (response as List).map((json) {
        final postData = json as Map<String, dynamic>;
        final profileData = postData['profiles'] as Map<String, dynamic>?;
        final likesData = postData['post_likes'] as List?;
        final commentsData = postData['post_comments'] as List?;

        // Check if current user liked this post
        final isLiked = currentUserId != null &&
            likesData != null &&
            likesData.any((like) => like['user_id'] == currentUserId);

        // Build comments list
        final commentsList = (commentsData ?? []).map((commentJson) {
          final comment = commentJson as Map<String, dynamic>;
          final commentProfile = comment['profiles'] as Map<String, dynamic>?;
          return Comment(
            id: comment['id'] as String,
            userId: comment['user_id'] as String,
            userName: commentProfile?['name'] as String? ?? 'Unknown',
            userAvatar: commentProfile?['profile_image_url'] as String? ??
                'https://api.dicebear.com/7.x/avataaars/png?seed=${commentProfile?['email'] ?? 'User'}',
            content: comment['content'] as String,
            timestamp: DateTime.parse(comment['created_at'] as String),
            likes: 0, // TODO: Add comment likes if needed
            isLiked: false,
          );
        }).toList();

        // Determine post type based on content
        PostType postType = PostType.general;
        if (postData['video_url'] != null) {
          postType = PostType.video;
        } else if (postData['image_url'] != null) {
          // Could be match, achievement, or general
          postType = PostType.general;
        }

        return Post(
          id: postData['id'] as String,
          userId: postData['user_id'] as String,
          userName: profileData?['name'] as String? ?? 'Unknown',
          userAvatar: profileData?['profile_image_url'] as String? ??
              'https://api.dicebear.com/7.x/avataaars/png?seed=${profileData?['email'] ?? 'User'}',
          imageUrl: postData['image_url'] as String?,
          videoUrl: postData['video_url'] as String?,
          videoDuration: null,
          content: postData['content'] as String? ?? '',
          timestamp: DateTime.parse(postData['created_at'] as String),
          likes: (postData['likes_count'] as int?) ?? (likesData?.length ?? 0),
          comments: (postData['comments_count'] as int?) ?? (commentsData?.length ?? 0),
          isLiked: isLiked,
          isBookmarked: false, // TODO: Add bookmarks table if needed
          commentsList: commentsList,
          type: postType,
          hashtags: [], // TODO: Extract hashtags from content
          pollOptions: null, // TODO: Add poll support if needed
          scoreOverlay: null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  Future<Post> createPost({
    required String userId,
    String? content,
    String? imageUrl,
    String? videoUrl,
  }) async {
    try {
      final response = await _supabase.from('posts').insert({
        'user_id': userId,
        'content': content,
        'image_url': imageUrl,
        'video_url': videoUrl,
        'likes_count': 0,
        'comments_count': 0,
      }).select('''
        *,
        profiles:user_id (
          id,
          name,
          profile_image_url,
          email
        )
      ''').single();

      final postData = response as Map<String, dynamic>;
      final profileData = postData['profiles'] as Map<String, dynamic>?;

      PostType postType = PostType.general;
      if (videoUrl != null) {
        postType = PostType.video;
      } else if (imageUrl != null) {
        postType = PostType.general;
      }

      return Post(
        id: postData['id'] as String,
        userId: postData['user_id'] as String,
        userName: profileData?['name'] as String? ?? 'Unknown',
        userAvatar: profileData?['profile_image_url'] as String? ??
            'https://api.dicebear.com/7.x/avataaars/png?seed=${profileData?['email'] ?? 'User'}',
        imageUrl: postData['image_url'] as String?,
        videoUrl: postData['video_url'] as String?,
        videoDuration: null,
        content: postData['content'] as String? ?? '',
        timestamp: DateTime.parse(postData['created_at'] as String),
        likes: 0,
        comments: 0,
        isLiked: false,
        isBookmarked: false,
        commentsList: [],
        type: postType,
        hashtags: [],
        pollOptions: null,
        scoreOverlay: null,
      );
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  Future<void> likePost(String postId, String userId) async {
    try {
      // Check if already liked
      final existingLike = await _supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike == null) {
        // Add like
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });

        // Update likes count manually
        try {
          final currentPost = await _supabase
              .from('posts')
              .select('likes_count')
              .eq('id', postId)
              .single();

          final currentLikes = (currentPost['likes_count'] as int?) ?? 0;
          await _supabase
              .from('posts')
              .update({'likes_count': currentLikes + 1})
              .eq('id', postId);
        } catch (e) {
          // Ignore if update fails
        }
      }
    } catch (e) {
      // If increment function doesn't exist, manually update
      try {
        final currentPost = await _supabase
            .from('posts')
            .select('likes_count')
            .eq('id', postId)
            .single();

        final currentLikes = (currentPost['likes_count'] as int?) ?? 0;
        await _supabase
            .from('posts')
            .update({'likes_count': currentLikes + 1})
            .eq('id', postId);
      } catch (e2) {
        throw Exception('Failed to like post: $e2');
      }
    }
  }

  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);

      // Update likes count
      try {
        final currentPost = await _supabase
            .from('posts')
            .select('likes_count')
            .eq('id', postId)
            .single();

        final currentLikes = (currentPost['likes_count'] as int?) ?? 0;
        await _supabase
            .from('posts')
            .update({'likes_count': (currentLikes - 1).clamp(0, double.infinity).toInt()})
            .eq('id', postId);
      } catch (e) {
        // Ignore if update fails
      }
    } catch (e) {
      throw Exception('Failed to unlike post: $e');
    }
  }

  Future<Comment> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      final response = await _supabase.from('post_comments').insert({
        'post_id': postId,
        'user_id': userId,
        'content': content,
      }).select('''
        *,
        profiles:user_id (
          id,
          name,
          profile_image_url,
          email
        )
      ''').single();

      final commentData = response as Map<String, dynamic>;
      final profileData = commentData['profiles'] as Map<String, dynamic>?;

      // Update comments count
      try {
        final currentPost = await _supabase
            .from('posts')
            .select('comments_count')
            .eq('id', postId)
            .single();

        final currentComments = (currentPost['comments_count'] as int?) ?? 0;
        await _supabase
            .from('posts')
            .update({'comments_count': currentComments + 1})
            .eq('id', postId);
      } catch (e) {
        // Ignore if update fails
      }

      return Comment(
        id: commentData['id'] as String,
        userId: commentData['user_id'] as String,
        userName: profileData?['name'] as String? ?? 'Unknown',
        userAvatar: profileData?['profile_image_url'] as String? ??
            'https://api.dicebear.com/7.x/avataaars/png?seed=${profileData?['email'] ?? 'User'}',
        content: commentData['content'] as String,
        timestamp: DateTime.parse(commentData['created_at'] as String),
        likes: 0,
        isLiked: false,
      );
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }
}

