import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../domain/models/post_model.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreatePostDialog extends ConsumerStatefulWidget {
  final Function(Post) onPostCreated;
  final Post? initialPost;

  const CreatePostDialog({
    super.key,
    required this.onPostCreated,
    this.initialPost,
  });

  @override
  ConsumerState<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends ConsumerState<CreatePostDialog> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _hashtagsController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  final FocusNode _hashtagFocusNode = FocusNode();
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  List<String> _hashtagChips = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialPost != null) {
      _contentController.text = widget.initialPost!.content;
      _hashtagChips = widget.initialPost!.hashtags
          .map((h) => h.startsWith('#') ? h : '#$h')
          .toList();
    } else {
      // Add default hashtags
      _hashtagChips = ['#Cricket', '#IPL2024', '#LiveMatch'];
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _hashtagsController.dispose();
    _contentFocusNode.dispose();
    _hashtagFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _addHashtag() {
    final text = _hashtagsController.text.trim();
    if (text.isNotEmpty) {
      // Ensure hashtag starts with #
      String hashtag = text.startsWith('#') ? text : '#$text';
      // Remove any extra spaces and ensure it's a valid hashtag
      hashtag = hashtag.trim();
      if (hashtag.length > 1 && !_hashtagChips.contains(hashtag)) {
        setState(() {
          _hashtagChips.add(hashtag);
          _hashtagsController.clear();
        });
      }
    }
  }

  void _removeHashtag(String hashtag) {
    setState(() {
      _hashtagChips.remove(hashtag);
    });
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some content')),
      );
      return;
    }

    final user = ref.read(authStateProvider).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to create posts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String content = _contentController.text.trim();
    
    // Extract hashtags from chips (ensure they have # prefix)
    final hashtagList = _hashtagChips.map((h) {
      return h.startsWith('#') ? h.replaceFirst('#', '') : h;
    }).toList();
    
    // Add hashtags to content for display
    if (_hashtagChips.isNotEmpty) {
      content = '$content ${_hashtagChips.join(' ')}';
    }

    try {
      // TODO: Upload image to Supabase Storage if _selectedImage is not null
      // For now, we'll just use the local path or null
      final imageUrl = _selectedImage != null ? _selectedImage!.path : null;

      final postRepo = ref.read(postRepositoryProvider);
      final newPost = await postRepo.createPost(
        userId: user.id,
        content: content,
        imageUrl: imageUrl,
        videoUrl: null,
      );

      // Call the callback to notify parent
      widget.onPostCreated(newPost);
      
      // Then navigate back
      Navigator.pop(context);
      
      // Clear fields
      _contentController.clear();
      _hashtagsController.clear();
      setState(() {
        _selectedImage = null;
        _hashtagChips.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create post: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authStateProvider).user;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[100]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF205A28),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Text(
                    'Create Post',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF205A28),
                      letterSpacing: -0.5,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _createPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF205A28),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF205A28).withOpacity(0.2),
                    ),
                    child: const Text(
                      'Post',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info Section
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF205A28),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              user?.email != null
                                  ? 'https://api.dicebear.com/7.x/avataaars/svg?seed=${user!.email}'
                                  : 'https://lh3.googleusercontent.com/aida-public/AB6AXuCAqmGqkLb3TUbTO-ibhl4h4gKqdKir2HBpFsiIUBeSFbtX9USNDlKICzE1xpzD_AdEUDlxcU0dNQ05wGMM8h94AwOXg0Q6bptslB6cqf44g9N5dAYir6_aa2kKKKhhpW_zUzv3d-Qc_7XeNqTHp27h4cxMCplzQCjQ2eZFvsJS9uP3Cfh3XhW6LsN5KWvJH9KSE6OtEvPfxBLK_Q7R6VC30chy_7nxkpTaILXRDetZI6oI1TbbGMVm1pOn7WKShZTnkjVL85ZcRw8B',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.person, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Rahul Dravid',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF205A28),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey[100]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.public,
                                      size: 14,
                                      color: Color(0xFF205A28),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Public',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF205A28).withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      size: 14,
                                      color: const Color(0xFF205A28).withOpacity(0.6),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Text Input Area
                    TextField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      maxLines: null,
                      minLines: 5,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF205A28),
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: TextStyle(
                          color: const Color(0xFF205A28).withOpacity(0.4),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Image Upload Section
                    GestureDetector(
                      onTap: _pickImageFromGallery,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF205A28).withOpacity(0.2),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _selectedImage != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _selectedImage = null;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF205A28).withOpacity(0.08),
                                          blurRadius: 20,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.add_photo_alternate,
                                      color: Color(0xFF205A28),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Upload Picture from Gallery',
                                    style: TextStyle(
                                      color: Color(0xFF205A28),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Hashtag Section
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _hashtagFocusNode.hasFocus
                                ? const Color(0xFF205A28)
                                : Colors.grey[100]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tag,
                            color: Color(0xFF205A28),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _hashtagsController,
                              focusNode: _hashtagFocusNode,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF205A28),
                              ),
                              decoration: InputDecoration(
                                hintText: 'AddHashtags',
                                hintStyle: TextStyle(
                                  color: const Color(0xFF205A28).withOpacity(0.4),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              onSubmitted: (_) => _addHashtag(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Hashtag Chips
                    if (_hashtagChips.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _hashtagChips.map((hashtag) {
                          return _buildRemovableHashtagChip(hashtag);
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[100]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ADD TO POST',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                      letterSpacing: 1.2,
                    ),
                  ),
                  Row(
                    children: [
                      _buildActionIcon(
                        Icons.image,
                        hasNotification: _selectedImage != null,
                        onTap: _pickImageFromGallery,
                      ),
                      const SizedBox(width: 24),
                      _buildActionIcon(
                        Icons.person_add,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tag people feature coming soon!')),
                          );
                        },
                      ),
                      const SizedBox(width: 24),
                      _buildActionIcon(
                        Icons.sentiment_satisfied,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Emoji picker coming soon!')),
                          );
                        },
                      ),
                      const SizedBox(width: 24),
                      _buildActionIcon(
                        Icons.location_on,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Location feature coming soon!')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHashtagChip(String hashtag) {
    return GestureDetector(
      onTap: () {
        if (!_hashtagChips.contains(hashtag)) {
          setState(() {
            _hashtagChips.add(hashtag);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF205A28).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          hashtag,
          style: const TextStyle(
            color: Color(0xFF205A28),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRemovableHashtagChip(String hashtag) {
    return GestureDetector(
      onTap: () => _removeHashtag(hashtag),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        decoration: BoxDecoration(
          color: const Color(0xFF205A28).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hashtag,
              style: const TextStyle(
                color: Color(0xFF205A28),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.close,
              size: 16,
              color: const Color(0xFF205A28).withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, {bool hasNotification = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Icon(
            icon,
            color: const Color(0xFF205A28),
            size: 24,
          ),
          if (hasNotification)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFC72B32),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
