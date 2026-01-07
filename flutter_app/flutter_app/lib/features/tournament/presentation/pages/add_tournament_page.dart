import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/storage_service.dart';

class AddTournamentPage extends ConsumerStatefulWidget {
  const AddTournamentPage({super.key});

  @override
  ConsumerState<AddTournamentPage> createState() => _AddTournamentPageState();
}

class _AddTournamentPageState extends ConsumerState<AddTournamentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _groundController = TextEditingController();
  final _organizerNameController = TextEditingController();
  final _organizerMobileController = TextEditingController();

  File? _bannerImage;
  File? _logoImage;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _category;
  String? _ballType;
  String? _pitchType;

  bool _isLoading = false;

  final List<String> _categories = [
    'open',
    'corporate',
    'community',
    'school',
    'college',
    'series',
    'other',
  ];

  final List<String> _ballTypes = ['leather', 'tennis', 'other'];
  final List<String> _pitchTypes = ['matting', 'rough', 'cemented', 'astro-turf'];

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _groundController.dispose();
    _organizerNameController.dispose();
    _organizerMobileController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, bool isBanner) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        if (isBanner) {
          _bannerImage = File(pickedFile.path);
        } else {
          _logoImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? (_startDate ?? DateTime.now().add(const Duration(days: 7)))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Reset end date if it's before new start date
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }
    if (value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Please enter a valid 10-digit mobile number';
    }
    return null;
  }

  Future<void> _registerTournament() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    if (_category == null || _ballType == null || _pitchType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all required fields')),
      );
      return;
    }

    final authState = ref.read(authStateProvider);
    final user = authState.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create a tournament')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tournamentRepo = ref.read(tournamentRepositoryProvider);
      final storageService = ref.read(storageServiceProvider);

      // Upload images first
      String? bannerUrl;
      String? logoUrl;

      // Create tournament first to get ID for image naming
      final tournamentData = {
        'name': _nameController.text.trim(),
        'city': _cityController.text.trim(),
        'ground': _groundController.text.trim(),
        'organizer_name': _organizerNameController.text.trim(),
        'organizer_mobile': _organizerMobileController.text.trim(),
        'start_date': _startDate!.toIso8601String().split('T')[0],
        'end_date': _endDate!.toIso8601String().split('T')[0],
        'category': _category,
        'ball_type': _ballType,
        'pitch_type': _pitchType,
        'created_by': user.id,
      };

      final tournament = await tournamentRepo.createTournament(tournamentData);

      // Upload images after tournament creation
      if (_bannerImage != null) {
        bannerUrl = await storageService.uploadTournamentBanner(
          _bannerImage!,
          tournament.id,
        );
      }

      if (_logoImage != null) {
        logoUrl = await storageService.uploadTournamentLogo(
          _logoImage!,
          tournament.id,
        );
      }

      // Update tournament with image URLs
      if (bannerUrl != null || logoUrl != null) {
        await tournamentRepo.updateTournament(tournament.id, {
          if (bannerUrl != null) 'banner_url': bannerUrl,
          if (logoUrl != null) 'logo_url': logoUrl,
        });
      }

      if (mounted) {
        // Navigate to tournament home
        context.go('/tournament/${tournament.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create tournament: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add A Tournament'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textMain,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tournament Banner
                    _buildImageUploadSection(
                      title: 'Add Tournament Banner',
                      image: _bannerImage,
                      isBanner: true,
                    ),
                    const SizedBox(height: 24),

                    // Tournament Logo
                    _buildImageUploadSection(
                      title: 'Add Tournament Logo',
                      image: _logoImage,
                      isBanner: false,
                    ),
                    const SizedBox(height: 24),

                    // Tournament Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tournament Name*',
                        hintText: 'Enter tournament name',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Tournament name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // City
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City*',
                        hintText: 'Enter city',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'City is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Ground
                    _buildDropdownField(
                      label: 'Ground*',
                      value: _groundController.text.isEmpty ? null : _groundController.text,
                      items: const ['Ground 1', 'Ground 2', 'Ground 3'], // You can fetch from API
                      onChanged: (value) {
                        setState(() {
                          _groundController.text = value ?? '';
                        });
                      },
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Ground is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Organizer Name
                    TextFormField(
                      controller: _organizerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Organizer Name*',
                        hintText: 'Enter organizer name',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Organizer name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Organizer Mobile
                    TextFormField(
                      controller: _organizerMobileController,
                      decoration: const InputDecoration(
                        labelText: 'Organizer Number*',
                        hintText: 'Enter 10-digit mobile number',
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      validator: _validateMobile,
                    ),
                    const SizedBox(height: 16),

                    // Start Date
                    _buildDateField(
                      label: 'Tournament Start Date*',
                      date: _startDate,
                      onTap: () => _selectDate(true),
                    ),
                    const SizedBox(height: 16),

                    // End Date
                    _buildDateField(
                      label: 'Tournament End Date*',
                      date: _endDate,
                      onTap: () => _selectDate(false),
                    ),
                    const SizedBox(height: 16),

                    // Tournament Category
                    _buildDropdownField(
                      label: 'Tournament Category*',
                      value: _category,
                      items: _categories,
                      onChanged: (value) => setState(() => _category = value),
                      validator: (value) =>
                          value == null ? 'Category is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Ball Type
                    _buildDropdownField(
                      label: 'Ball Type*',
                      value: _ballType,
                      items: _ballTypes,
                      onChanged: (value) => setState(() => _ballType = value),
                      validator: (value) =>
                          value == null ? 'Ball type is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Pitch Type
                    _buildDropdownField(
                      label: 'Pitch Type*',
                      value: _pitchType,
                      items: _pitchTypes,
                      onChanged: (value) => setState(() => _pitchType = value),
                      validator: (value) =>
                          value == null ? 'Pitch type is required' : null,
                    ),
                    const SizedBox(height: 32),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _registerTournament,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageUploadSection({
    required String title,
    required File? image,
    required bool isBanner,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_library),
                      title: const Text('Choose from Gallery'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery, isBanner);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Take Photo'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera, isBanner);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            height: isBanner ? 200 : 120,
            decoration: BoxDecoration(
              color: AppColors.elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: image != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(image, fit: BoxFit.cover),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isBanner ? Icons.image : Icons.account_circle,
                        size: 48,
                        color: AppColors.textMeta,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(color: AppColors.textMeta),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item.toUpperCase()),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null
              ? '${date.day}/${date.month}/${date.year}'
              : 'Select date',
          style: TextStyle(
            color: date != null ? AppColors.textMain : AppColors.textMeta,
          ),
        ),
      ),
    );
  }
}

