import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import '../widgets/post_card.dart';
import '../widgets/create_post_dialog.dart';
import '../../domain/models/post_model.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final postRepo = ref.read(postRepositoryProvider);
      final posts = await postRepo.getPosts(limit: 50);

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleLike(Post post) async {
    final postRepo = ref.read(postRepositoryProvider);
    final user = ref.read(authStateProvider).user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to like posts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (post.isLiked) {
        await postRepo.unlikePost(post.id, user.id);
      } else {
        await postRepo.likePost(post.id, user.id);
      }

      // Reload posts to get updated like status
      await _loadPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update like: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleBookmark(Post post) {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = post.copyWith(
          isBookmarked: !post.isBookmarked,
        );
      }
    });
  }

  void _handleComment(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCommentsSheet(post),
    );
  }

  void _handleShare(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF205A28)),
              title: const Text('Share to WhatsApp'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shared to WhatsApp')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF205A28)),
              title: const Text('Share to Twitter'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shared to Twitter')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Color(0xFF205A28)),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handlePollVote(Post post, PollOption option) {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1 && post.pollOptions != null) {
        final updatedOptions = post.pollOptions!.map((opt) {
          if (opt.id == option.id) {
            return opt.copyWith(isSelected: true, votes: opt.votes + 1);
          }
          return opt;
        }).toList();
        
        // Recalculate percentages
        final totalVotes = updatedOptions.fold(0, (sum, opt) => sum + opt.votes);
        final optionsWithPercentages = updatedOptions.map((opt) {
          return opt.copyWith(percentage: totalVotes > 0 ? (opt.votes / totalVotes) * 100 : 0.0);
        }).toList();
        
        _posts[index] = post.copyWith(pollOptions: optionsWithPercentages);
      }
    });
  }

  void _showCreatePostDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostDialog(
          onPostCreated: (post) {
            // Reload posts to get the new post from Supabase
            _loadPosts();
          },
        ),
        fullscreenDialog: true,
      ),
    );
    // Refresh the feed after returning
    if (mounted) {
      await _loadPosts();
    }
  }

  Widget _buildCommentsSheet(Post post) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF205A28),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF205A28)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: post.commentsList.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildAddCommentField(post);
                  }
                  final comment = post.commentsList[index - 1];
                  return _buildCommentItem(post, comment);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCommentField(Post post) {
    final commentController = TextEditingController();
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(
              ref.read(authStateProvider).user?.email != null
                  ? 'https://api.dicebear.com/7.x/avataaars/svg?seed=${ref.read(authStateProvider).user!.email}'
                  : 'https://api.dicebear.com/7.x/avataaars/svg?seed=User',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: commentController,
              style: const TextStyle(color: Color(0xFF205A28)),
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF205A28), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF205A28)),
            onPressed: () async {
              if (commentController.text.isNotEmpty) {
                final user = ref.read(authStateProvider).user;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please log in to comment'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final postRepo = ref.read(postRepositoryProvider);
                  await postRepo.addComment(
                    postId: post.id,
                    userId: user.id,
                    content: commentController.text,
                  );
                  commentController.clear();
                  Navigator.pop(context);
                  // Reload posts to get updated comments
                  await _loadPosts();
                  // Reopen comments sheet with updated post
                  final updatedPost = _posts.firstWhere((p) => p.id == post.id);
                  _handleComment(updatedPost);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add comment: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Post post, Comment comment) {
    final currentUserId = ref.read(authStateProvider).user?.id ?? 'current_user';
    final isOwnComment = comment.userId == currentUserId;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(comment.userAvatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF205A28),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF205A28)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _getTimeAgo(comment.timestamp),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _handleLikeComment(post, comment),
                      child: Row(
                        children: [
                          Icon(
                            comment.isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: comment.isLiked ? const Color(0xFFC72B32) : Colors.grey[600],
                          ),
                          if (comment.likes > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${comment.likes}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
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

  void _handleLikeComment(Post post, Comment comment) {
    setState(() {
      final postIndex = _posts.indexWhere((p) => p.id == post.id);
      if (postIndex != -1) {
        final commentIndex = post.commentsList.indexWhere((c) => c.id == comment.id);
        if (commentIndex != -1) {
          final updatedComments = List<Comment>.from(post.commentsList);
          updatedComments[commentIndex] = comment.copyWith(
            isLiked: !comment.isLiked,
            likes: comment.isLiked ? comment.likes - 1 : comment.likes + 1,
          );
          _posts[postIndex] = post.copyWith(commentsList: updatedComments);
        }
      }
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[100]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF205A28),
                      size: 24,
                    ),
                    onPressed: () {
                      context.go('/');
                    },
                  ),
                  const Text(
                    'Feed',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF205A28),
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.filter_list,
                      color: Color(0xFF205A28),
                      size: 28,
                    ),
                    onPressed: () {
                      // Filter functionality
                    },
                  ),
                ],
              ),
            ),
            
            // Feed Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadPosts,
                color: const Color(0xFF205A28),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF205A28),
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading posts',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _loadPosts,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF205A28),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _posts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.rss_feed,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No posts yet. Be the first to post!',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: PostCard(
                              post: _posts[index],
                              onLike: () => _handleLike(_posts[index]),
                              onBookmark: () => _handleBookmark(_posts[index]),
                              onComment: () => _handleComment(_posts[index]),
                              onShare: () => _handleShare(_posts[index]),
                              onPollVote: (option) => _handlePollVote(_posts[index], option),
                              currentUserId: ref.read(authStateProvider).user?.id ?? 'current_user',
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        backgroundColor: const Color(0xFF205A28),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}
