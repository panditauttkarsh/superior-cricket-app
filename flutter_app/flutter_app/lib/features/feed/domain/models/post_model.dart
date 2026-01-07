class Post {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String? imageUrl;
  final String? videoUrl;
  final String? videoDuration;
  final String content;
  final DateTime timestamp;
  final int likes;
  final int comments;
  final bool isLiked;
  final bool isBookmarked;
  final List<Comment> commentsList;
  final PostType type;
  final List<String> hashtags;
  final List<PollOption>? pollOptions;
  final String? scoreOverlay; // For match score overlay on images

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    this.imageUrl,
    this.videoUrl,
    this.videoDuration,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.isLiked,
    this.isBookmarked = false,
    required this.commentsList,
    required this.type,
    this.hashtags = const [],
    this.pollOptions,
    this.scoreOverlay,
  });

  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? imageUrl,
    String? videoUrl,
    String? videoDuration,
    String? content,
    DateTime? timestamp,
    int? likes,
    int? comments,
    bool? isLiked,
    bool? isBookmarked,
    List<Comment>? commentsList,
    PostType? type,
    List<String>? hashtags,
    List<PollOption>? pollOptions,
    String? scoreOverlay,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      videoDuration: videoDuration ?? this.videoDuration,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      commentsList: commentsList ?? this.commentsList,
      type: type ?? this.type,
      hashtags: hashtags ?? this.hashtags,
      pollOptions: pollOptions ?? this.pollOptions,
      scoreOverlay: scoreOverlay ?? this.scoreOverlay,
    );
  }
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime timestamp;
  final int likes;
  final bool isLiked;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.isLiked,
  });

  Comment copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    DateTime? timestamp,
    int? likes,
    bool? isLiked,
  }) {
    return Comment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

enum PostType {
  score,
  achievement,
  match,
  general,
  poll,
  video,
}

class PollOption {
  final String id;
  final String text;
  final int votes;
  final double percentage;
  final bool isSelected;

  PollOption({
    required this.id,
    required this.text,
    required this.votes,
    required this.percentage,
    this.isSelected = false,
  });

  PollOption copyWith({
    String? id,
    String? text,
    int? votes,
    double? percentage,
    bool? isSelected,
  }) {
    return PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      votes: votes ?? this.votes,
      percentage: percentage ?? this.percentage,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

