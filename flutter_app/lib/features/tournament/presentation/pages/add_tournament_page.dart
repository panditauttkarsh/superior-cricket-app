import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/models/tournament_model.dart';

class AddTournamentPage extends ConsumerStatefulWidget {
  final TournamentModel? initialTournament;
  const AddTournamentPage({super.key, this.initialTournament});

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
  String? _existingBannerUrl;
  String? _existingLogoUrl;
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
  final List<String> _grounds = ['MCG Stadium', 'Lord\'s Cricket Ground', 'Wankhede Stadium', 'Chepauk Stadium'];
  final List<String> _customGrounds = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialTournament != null) {
      final t = widget.initialTournament!;
      _nameController.text = t.name;
      _cityController.text = t.city;
      _groundController.text = t.ground ?? '';
      _organizerNameController.text = t.organizerName;
      _organizerMobileController.text = t.organizerMobile;
      _startDate = t.startDate;
      _endDate = t.endDate;
      
      // Fix for Ground Dropdown Crash
      // Ensure the existing ground is in the list of items
      if (t.ground != null && 
          t.ground!.isNotEmpty && 
          !_grounds.contains(t.ground) && 
          !_customGrounds.contains(t.ground)) {
        _customGrounds.add(t.ground!);
      }
      
      // Handle dropdowns - ensure value exists in list or add/handle 'other' logic if needed
      // For now assuming values match
      if (_categories.contains(t.category)) {
        _category = t.category;
      }
      if (_ballTypes.contains(t.ballType)) {
        _ballType = t.ballType;
      }
      if (_pitchTypes.contains(t.pitchType)) {
        _pitchType = t.pitchType;
      }
      
      _existingBannerUrl = t.bannerUrl;
      _existingLogoUrl = t.logoUrl;
    }
  }

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
        const SnackBar(content: Text('Please log in to manage tournaments')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tournamentRepo = ref.read(tournamentRepositoryProvider);
      final storageService = ref.read(storageServiceProvider);

      final isEdit = widget.initialTournament != null;
      TournamentModel tournament;

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
        if (!isEdit) 'created_by': user.id,
      };

      if (isEdit) {
        // Update existing tournament
        tournament = await tournamentRepo.updateTournament(widget.initialTournament!.id, tournamentData);
      } else {
        // Create new tournament
        tournament = await tournamentRepo.createTournament(tournamentData);
      }

      // Handle Image Uploads
      String? bannerUrl;
      String? logoUrl;

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

      // Update tournament with new image URLs if any
      if (bannerUrl != null || logoUrl != null) {
        await tournamentRepo.updateTournament(tournament.id, {
          if (bannerUrl != null) 'banner_url': bannerUrl,
          if (logoUrl != null) 'logo_url': logoUrl,
        });
      }

      if (mounted) {
        if (isEdit) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tournament updated successfully!')),
          );
          // Pop back to detail page with refreshed data (or just pop, parent should refresh)
          context.pop();
        } else {
          // Navigate to tournament home for new tournament
          context.go('/tournament/${tournament.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${widget.initialTournament != null ? 'update' : 'create'} tournament: $e'),
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
        title: Text(
          widget.initialTournament != null ? 'Edit Tournament' : 'Create Tournament',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 28),
          onPressed: () => context.pop(),
        ),
        shape: Border(
          bottom: BorderSide(
            color: AppColors.divider.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Identity Section (Banner & Logo)
                  _buildIdentitySection(),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildSectionTitle('General Information'),
                          const SizedBox(height: 20),
                          
                          // Tournament Name
                          _buildCustomTextField(
                            controller: _nameController,
                            label: 'Tournament Name',
                            hint: 'e.g. Champions Trophy 2024',
                            icon: Icons.emoji_events_outlined,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Tournament name is required' : null,
                          ),
                          const SizedBox(height: 20),

                          // City
                          _buildCustomTextField(
                            controller: _cityController,
                            label: 'City',
                            hint: 'Enter your city',
                            icon: Icons.location_on_outlined,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'City is required' : null,
                          ),
                          const SizedBox(height: 20),

                          // Ground
                          _buildCustomDropdownField(
                            label: 'Ground / Venue',
                            hint: 'Select Venue',
                            value: _groundController.text.isEmpty ? null : _groundController.text,
                            items: [..._grounds, ..._customGrounds],
                            icon: Icons.stadium_outlined,
                            showAddOption: true,
                            onChanged: (value) {
                              if (value == 'ADD_NEW') {
                                _showAddGroundDialog();
                              } else {
                                setState(() {
                                  _groundController.text = value ?? '';
                                });
                              }
                            },
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Ground is required' : null,
                          ),
                          
                          const SizedBox(height: 40),
                          _buildSectionTitle('Organization Details'),
                          const SizedBox(height: 24),

                          // Organizer Name
                          _buildCustomTextField(
                            controller: _organizerNameController,
                            label: 'Organizer Name',
                            hint: 'Full name',
                            icon: Icons.person_outline_rounded,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Organizer name is required' : null,
                          ),
                          const SizedBox(height: 20),

                          // Organizer Mobile
                          _buildCustomTextField(
                            controller: _organizerMobileController,
                            label: 'Contact Number',
                            hint: '10-digit mobile number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            validator: _validateMobile,
                          ),
                          
                          const SizedBox(height: 40),
                          _buildSectionTitle('Schedule & Specifications'),
                          const SizedBox(height: 24),

                          // Start Date
                          _buildCustomDateField(
                            label: 'Starts On',
                            date: _startDate,
                            icon: Icons.calendar_today_outlined,
                            onTap: () => _selectDate(true),
                          ),
                          const SizedBox(height: 20),

                          // End Date
                          _buildCustomDateField(
                            label: 'Ends On',
                            date: _endDate,
                            icon: Icons.event_available_outlined,
                            onTap: () => _selectDate(false),
                          ),
                          const SizedBox(height: 20),

                          // Tournament Category
                          _buildCustomDropdownField(
                            label: 'Tournament Category',
                            hint: 'Select Category',
                            value: _category,
                            items: _categories,
                            icon: Icons.category_outlined,
                            onChanged: (value) => setState(() => _category = value),
                            validator: (value) =>
                                value == null ? 'Category is required' : null,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Flexible(
                                flex: 1,
                                child: _buildCustomDropdownField(
                                  label: 'Ball Type',
                                  hint: 'Select Ball',
                                  value: _ballType,
                                  items: _ballTypes,
                                  icon: Icons.sports_baseball_outlined,
                                  onChanged: (value) => setState(() => _ballType = value),
                                  validator: (value) =>
                                      value == null ? 'Ball type is required' : null,
                                  showPrefix: false,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                flex: 1,
                                child: _buildCustomDropdownField(
                                  label: 'Pitch Type',
                                  hint: 'Select Pitch',
                                  value: _pitchType,
                                  items: _pitchTypes,
                                  icon: Icons.layers_outlined,
                                  onChanged: (value) => setState(() => _pitchType = value),
                                  validator: (value) =>
                                      value == null ? 'Pitch type is required' : null,
                                  showPrefix: false,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 48),

                          // Register Button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _registerTournament,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.emoji_events_rounded, size: 22, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text(
                                      widget.initialTournament != null ? 'UPDATE TOURNAMENT' : 'CREATE TOURNAMENT',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildIdentitySection() {
    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          // Banner Image
          GestureDetector(
            onTap: () => _showImageSourceOptions(true),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.elevated,
                image: _bannerImage != null
                    ? DecorationImage(image: FileImage(_bannerImage!), fit: BoxFit.cover)
                    : (_existingBannerUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_existingBannerUrl!),
                            fit: BoxFit.cover,
                          )
                        : null),
              ),
              child: (_bannerImage == null && _existingBannerUrl == null)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.textMeta.withOpacity(0.5)),
                        const SizedBox(height: 8),
                        Text('Add Tournament Banner', style: TextStyle(color: AppColors.textMeta.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                        ),
                      ),
                    ),
            ),
          ),
          // Logo Image (Overlapping)
          Positioned(
            bottom: 0,
            left: 20,
            child: GestureDetector(
              onTap: () => _showImageSourceOptions(false),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: ClipOval(
                  child: (_logoImage != null || _existingLogoUrl != null)
                      ? (_logoImage != null 
                          ? Image.file(_logoImage!, fit: BoxFit.cover)
                          : Image.network(_existingLogoUrl!, fit: BoxFit.cover))
                      : Container(
                          color: AppColors.surface,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 24, color: AppColors.primary.withOpacity(0.5)),
                              const SizedBox(height: 4),
                              const Text('LOGO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMeta)),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
          // Edit Banner Button
          if (_bannerImage != null)
            Positioned(
              top: 16,
              right: 16,
              child: _buildCircleToolButton(Icons.edit_outlined, () => _showImageSourceOptions(true)),
            ),
        ],
      ),
    );
  }

  Widget _buildCircleToolButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textMain),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain.withOpacity(0.8),
              fontFamily: 'Inter',
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textMeta.withOpacity(0.4),
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
            ),
            filled: true,
            fillColor: AppColors.surface,
            counterText: "",
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCustomDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
    bool showAddOption = false,
    bool showPrefix = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain.withOpacity(0.8),
              fontFamily: 'Inter',
            ),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: AppColors.textMeta.withOpacity(0.4),
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMeta.withOpacity(0.5)),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textMain,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: showPrefix
                ? Icon(icon, size: 20, color: AppColors.primary)
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          items: [
            ...items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item.toUpperCase()),
              );
            }).toList(),
            if (showAddOption)
              const DropdownMenuItem(
                value: 'ADD_NEW',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Add New Ground...',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCustomDateField({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain.withOpacity(0.8),
              fontFamily: 'Inter',
            ),
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Select Date',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: date != null ? AppColors.textMain : AppColors.textMeta.withOpacity(0.4),
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.textMeta.withOpacity(0.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddGroundDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 12,
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stadium_rounded,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Add New Ground',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a custom ground manually if it\'s not in the list.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMeta.withOpacity(0.6),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Input Field
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'e.g. Skyline Cricket Ground',
                      hintStyle: TextStyle(
                        color: AppColors.textMeta.withOpacity(0.4),
                        fontWeight: FontWeight.normal,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.divider.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.divider.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textMeta.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              final name = controller.text.trim();
                              if (name.isNotEmpty) {
                                setState(() {
                                  _customGrounds.add(name.toUpperCase());
                                  _groundController.text = name.toUpperCase();
                                });
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Add Ground',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                fontFamily: 'Inter',
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
          ),
        ),
      ),
    );
  }

  void _showImageSourceOptions(bool isBanner) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Update Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, isBanner);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, isBanner);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

