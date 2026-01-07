import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _battingStyleController = TextEditingController();
  final TextEditingController _bowlingStyleController = TextEditingController();
  final TextEditingController _jerseyNumberController = TextEditingController();

  bool _isEditing = false;
  Map<String, String> _profileData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  void _loadProfileData() {
    final user = ref.read(authStateProvider).user;
    setState(() {
      _profileData = {
        'name': user?.name ?? 'User Name',
        'email': user?.email ?? 'user@example.com',
        'phone': '+91 98765 43210',
        'location': 'Mumbai, Maharashtra',
        'dob': '1990-05-15',
        'role': 'All-rounder',
        'battingStyle': 'Right-handed',
        'bowlingStyle': 'Right-arm Medium',
        'jerseyNumber': '7',
      };
      _nameController.text = _profileData['name']!;
      _emailController.text = _profileData['email']!;
      _phoneController.text = _profileData['phone']!;
      _locationController.text = _profileData['location']!;
      _dobController.text = _profileData['dob']!;
      _roleController.text = _profileData['role']!;
      _battingStyleController.text = _profileData['battingStyle']!;
      _bowlingStyleController.text = _profileData['bowlingStyle']!;
      _jerseyNumberController.text = _profileData['jerseyNumber']!;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _dobController.dispose();
    _roleController.dispose();
    _battingStyleController.dispose();
    _bowlingStyleController.dispose();
    _jerseyNumberController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    setState(() {
      _profileData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'location': _locationController.text,
        'dob': _dobController.text,
        'role': _roleController.text,
        'battingStyle': _battingStyleController.text,
        'bowlingStyle': _bowlingStyleController.text,
        'jerseyNumber': _jerseyNumberController.text,
      };
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Color(0xFF00D26A),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F2A20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditField('Name', _nameController),
              _buildEditField('Email', _emailController),
              _buildEditField('Phone', _phoneController),
              _buildEditField('Location', _locationController),
              _buildEditField('Date of Birth', _dobController),
              _buildEditField('Role', _roleController),
              _buildEditField('Batting Style', _battingStyleController),
              _buildEditField('Bowling Style', _bowlingStyleController),
              _buildEditField('Jersey Number', _jerseyNumberController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D26A),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00D26A), width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Picture with camera icon overlay
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://api.dicebear.com/7.x/avataaars/svg?seed=${_profileData['name'] ?? 'User'}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 60,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Camera icon overlay at bottom-right
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary, // Blue color
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Profile Information Fields with dividers
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildProfileField(
                    'Username',
                    ref.read(authStateProvider).user?.username ?? _profileData['name'] ?? 'User Name',
                  ),
                  _buildDivider(),
                  _buildProfileField(
                    'Email',
                    _profileData['email'] ?? 'user@example.com',
                  ),
                  _buildDivider(),
                  _buildProfileField(
                    'Phone',
                    _profileData['phone'] ?? '+91 98765 43210',
                  ),
                  _buildDivider(),
                  _buildProfileField(
                    'Date of birth',
                    _profileData['dob'] ?? '1990-05-15',
                  ),
                  _buildDivider(),
                  _buildProfileField(
                    'Address',
                    _profileData['location'] ?? 'Mumbai, Maharashtra',
                  ),
                  _buildDivider(),
                  _buildProfileField(
                    'Role',
                    _profileData['role'] ?? 'All-rounder',
                  ),
                  _buildDivider(),
                  _buildProfileField(
                    'Batting Style',
                    _profileData['battingStyle'] ?? 'Right-handed',
                  ),
                  _buildDivider(),
                  _buildProfileField(
                    'Bowling Style',
                    _profileData['bowlingStyle'] ?? 'Right-arm Medium',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Edit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showEditDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Blue color
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(authStateProvider.notifier).logout();
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.urgent, // Red color for logout
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[300],
    );
  }
}
