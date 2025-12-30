import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/models/tournament_model.dart';
import '../providers/tournament_providers.dart';

class AddTeamsPage extends ConsumerStatefulWidget {
  final String tournamentId;

  const AddTeamsPage({
    super.key,
    required this.tournamentId,
  });

  @override
  ConsumerState<AddTeamsPage> createState() => _AddTeamsPageState();
}

class _AddTeamsPageState extends ConsumerState<AddTeamsPage> {
  bool _inviteLinkEnabled = true;
  File? _teamLogo;
  final _teamNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _toggleInviteLink() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tournamentRepo = ref.read(tournamentRepositoryProvider);
      final tournament = await tournamentRepo.getTournamentById(widget.tournamentId);
      if (tournament != null) {
        await tournamentRepo.toggleInviteLink(
          widget.tournamentId,
          !_inviteLinkEnabled,
        );
        setState(() {
          _inviteLinkEnabled = !_inviteLinkEnabled;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle invite link: $e')),
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

  Future<void> _shareInviteLink() async {
    try {
      final tournamentRepo = ref.read(tournamentRepositoryProvider);
      final tournament = await tournamentRepo.getTournamentById(widget.tournamentId);
      if (tournament != null && tournament.inviteLink.isNotEmpty) {
        await Share.share(tournament.inviteLink);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share link: $e')),
        );
      }
    }
  }

  Future<void> _shareViaWhatsApp() async {
    try {
      final tournamentRepo = ref.read(tournamentRepositoryProvider);
      final tournament = await tournamentRepo.getTournamentById(widget.tournamentId);
      if (tournament != null && tournament.inviteLink.isNotEmpty) {
        await Share.share(
          tournament.inviteLink,
          subject: 'Join ${tournament.name} Tournament',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share via WhatsApp: $e')),
        );
      }
    }
  }

  Future<void> _pickTeamLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _teamLogo = File(pickedFile.path);
      });
    }
  }

  Future<void> _addTeamManually() async {
    if (_teamNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter team name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final teamRepo = ref.read(tournamentTeamRepositoryProvider);
      final storageService = ref.read(storageServiceProvider);
      final authState = ref.read(authStateProvider);
      final user = authState.user;

      String? logoUrl;
      if (_teamLogo != null) {
        // Generate a temporary ID for the team
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        logoUrl = await storageService.uploadTeamLogo(_teamLogo!, tempId);
      }

      await teamRepo.addTeamToTournament(
        tournamentId: widget.tournamentId,
        teamName: _teamNameController.text.trim(),
        teamLogo: logoUrl,
        captainId: user?.id,
        captainName: user?.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add team: $e'),
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
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Teams'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textMain,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : tournamentAsync.when(
              data: (tournament) {
                if (tournament == null) {
                  return const Center(child: Text('Tournament not found'));
                }
                return _buildContent(tournament);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
    );
  }

  Widget _buildContent(TournamentModel tournament) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invite Link Section
          _buildInviteLinkSection(tournament),
          const SizedBox(height: 24),

          // My Teams Section
          _buildMyTeamsSection(),
          const SizedBox(height: 24),

          // Add New Teams Section
          _buildAddNewTeamsSection(),
          const SizedBox(height: 24),

          // QR Code Section
          _buildQRCodeSection(tournament),
        ],
      ),
    );
  }

  Widget _buildInviteLinkSection(TournamentModel tournament) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.link,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invite Link',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      'Easiest way to add teams.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSec,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _inviteLinkEnabled,
                onChanged: (_) => _toggleInviteLink(),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Share this link with captains and let them add their respective teams directly to your tournament.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSec,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _shareInviteLink,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Share'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareViaWhatsApp,
                  icon: const Icon(Icons.chat, size: 20),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyTeamsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Teams',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  'Quickly add teams from your network.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSec,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.textMeta),
            onPressed: () {
              // Navigate to my teams
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewTeamsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Teams',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      'Add one or more teams manually.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSec,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Team Logo
          GestureDetector(
            onTap: _pickTeamLogo,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.elevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: _teamLogo != null
                  ? ClipOval(
                      child: Image.file(_teamLogo!, fit: BoxFit.cover),
                    )
                  : Icon(
                      Icons.add_photo_alternate,
                      color: AppColors.textMeta,
                      size: 40,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Team Name
          TextField(
            controller: _teamNameController,
            decoration: const InputDecoration(
              labelText: 'Team Name',
              hintText: 'Enter team name',
            ),
          ),
          const SizedBox(height: 16),
          // Add Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addTeamManually,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Team'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection(TournamentModel tournament) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add via QR Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      'Add teams by scanning their QR Codes.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSec,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // QR Code Display
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: tournament.inviteLink.isNotEmpty
                    ? tournament.inviteLink
                    : 'https://pitchpoint.app/tournament/${tournament.id}',
                version: QrVersions.auto,
                size: 200,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

