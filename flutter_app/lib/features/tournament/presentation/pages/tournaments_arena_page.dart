import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../mycricket/presentation/widgets/enhanced_create_match_dialog.dart';

class TournamentsArenaPage extends ConsumerStatefulWidget {
  const TournamentsArenaPage({super.key});

  @override
  ConsumerState<TournamentsArenaPage> createState() => _TournamentsArenaPageState();
}

class _TournamentsArenaPageState extends ConsumerState<TournamentsArenaPage> {
  String _activeTab = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _matchesFilter = 'My';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D1F18),
              const Color(0xFF0A1A14),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 30),
                          
                          // Header
                          _buildHeader(),
                          
                          const SizedBox(height: 16),
                          
                          // My Matches Section
                          _buildMyMatchesSection(),
                          
                          const SizedBox(height: 24),
                          
                          // Search Bar
                          _buildSearchBar(),
                          
                          const SizedBox(height: 16),
                          
                          // Filter Tabs
                          _buildFilterTabs(),
                          
                          const SizedBox(height: 24),
                          
                          // Featured Event Section
                          _buildFeaturedEventSection(),
                          
                          const SizedBox(height: 28),
                          
                          // Open Tournaments Section
                          _buildOpenTournamentsSection(),
                          
                          const SizedBox(height: 100), // Space for bottom nav
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Bottom Navigation
              _buildBottomNavBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyMatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Want to start a match section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Want to start a match?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const EnhancedCreateMatchDialog(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D26A),
                foregroundColor: const Color(0xFF0A1A14),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Start'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Filter tabs
        Row(
          children: [
            _buildMatchFilterTab('My', _matchesFilter == 'My'),
            _buildMatchFilterTab('Upcoming', _matchesFilter == 'Upcoming'),
            _buildMatchFilterTab('Nearby', _matchesFilter == 'Nearby'),
          ],
        ),
        const SizedBox(height: 16),
        
        // Match list based on filter
        _buildMatchesList(),
      ],
    );
  }

  Widget _buildMatchFilterTab(String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _matchesFilter = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0F2A20) : Colors.transparent,
            border: Border.all(
              color: isActive ? const Color(0xFF00D26A) : const Color(0xFF1A3D30),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? const Color(0xFF00D26A) : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchesList() {
    List<Map<String, dynamic>> matches = [];
    
    if (_matchesFilter == 'My') {
      // Playing/Played matches
      matches = [
        {
          'opponent': 'vs Super Kings',
          'result': 'Won by 25 runs',
          'resultColor': const Color(0xFF00D26A),
          'score': '185/4',
          'format': 'T20',
          'status': 'Played',
          'date': 'Dec 10, 2024',
        },
        {
          'opponent': 'vs Titans',
          'result': 'Lost by 3 wickets',
          'resultColor': const Color(0xFFFF3B30),
          'score': '142/8',
          'format': 'ODI',
          'status': 'Played',
          'date': 'Dec 8, 2024',
        },
        {
          'opponent': 'vs Royal Strikers',
          'result': 'Playing',
          'resultColor': const Color(0xFF00D26A),
          'score': '142/3',
          'format': 'T20',
          'status': 'Playing',
          'date': 'Today',
        },
      ];
    } else if (_matchesFilter == 'Upcoming') {
      // Upcoming matches
      matches = [
        {
          'opponent': 'vs Royal Strikers',
          'date': 'Tomorrow, 2:00 PM',
          'format': 'T20',
          'status': 'Upcoming',
        },
        {
          'opponent': 'vs Thunder XI',
          'date': 'Dec 15, 3:00 PM',
          'format': 'ODI',
          'status': 'Upcoming',
        },
        {
          'opponent': 'vs Warriors',
          'date': 'Dec 18, 4:00 PM',
          'format': 'T20',
          'status': 'Upcoming',
        },
      ];
    } else if (_matchesFilter == 'Nearby') {
      // Coming soon
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 64, color: Colors.grey[500]),
              const SizedBox(height: 16),
              Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find nearby matches feature will be available soon',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'No matches found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: matches.map((match) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMatchCard(match),
        );
      }).toList(),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final isPlayed = match['status'] == 'Played' || match['status'] == 'Playing';
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A3D30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPlayed
                  ? (match['resultColor'] as Color).withOpacity(0.2)
                  : const Color(0xFF00D26A).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPlayed ? Icons.sports_cricket : Icons.calendar_today,
              color: isPlayed ? (match['resultColor'] as Color) : const Color(0xFF00D26A),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match['opponent'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                if (isPlayed)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: match['resultColor'] as Color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          match['result'] as String,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (match['score'] != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          match['score'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: match['resultColor'] as Color,
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  Text(
                    match['date'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3D30),
              border: Border.all(color: const Color(0xFF00D26A).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              match['format'] as String,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00D26A),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // User Info
        Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00D26A),
                  width: 2,
                ),
                color: const Color(0xFFC0AEDE),
              ),
              child: ClipOval(
                child: Image.network(
                  'https://api.dicebear.com/7.x/avataaars/svg?seed=John&backgroundColor=c0aede&hair=short',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFC0AEDE),
                      child: const Icon(Icons.person, color: Colors.white),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),
            // User Text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WELCOME BACK',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'CricPlay Arena',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Notification Button
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00D26A).withOpacity(0.1),
            border: Border.all(
              color: const Color(0xFF00D26A).withOpacity(0.2),
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF00D26A),
              size: 22,
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F2A20),
              border: Border.all(
                color: const Color(0xFF1A3D30),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Colors.grey[500],
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search tournaments, leagues...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF0F2A20),
            border: Border.all(
              color: const Color(0xFF1A3D30),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.tune,
              color: Color(0xFF00D26A),
              size: 20,
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    final tabs = ['All', 'Live Now', 'Upcoming', 'T20 Bash'];
    
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: tabs.map((tab) {
          final isActive = _activeTab == tab;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = tab),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF00D26A) : Colors.transparent,
                border: Border.all(
                  color: isActive ? const Color(0xFF00D26A) : const Color(0xFF1A3D30),
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tab == 'Live Now') ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF0A1A14) : const Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    tab,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive ? const Color(0xFF0A1A14) : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturedEventSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured Event',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF00D26A),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F2A20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF1A3D30),
            ),
          ),
          child: Column(
            children: [
              // Featured Image
              Stack(
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=400&h=250&fit=crop',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF0F2A20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Badges
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'T20 Format',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Featured Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Global Super League',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The biggest T20 showdown of the year is here.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRIZE POOL',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '\$500,000',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF00D26A),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0A1A14),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Register Now',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 16),
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
        ),
      ],
    );
  }

  Widget _buildOpenTournamentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Open Tournaments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildTournamentCard(
          imageUrl: 'https://images.unsplash.com/photo-1624526267942-ab0ff8a3e972?w=120&h=100&fit=crop',
          title: 'Premier Championship',
          entryFee: '100 Gold',
          entryFeeColor: const Color(0xFFFFD700),
          teams: '32/64 Teams',
          date: 'Oct 24',
          daysLeft: '4 Days Left',
          participants: 29,
          isLocked: false,
        ),
        const SizedBox(height: 14),
        _buildTournamentCard(
          imageUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=120&h=100&fit=crop',
          title: 'Super Sixes League',
          entryFee: 'Free',
          entryFeeColor: const Color(0xFF00D26A),
          teams: '120/500',
          date: 'Oct 26',
          specialTag: 'WEEKEND SPECIAL',
          isLocked: false,
        ),
        const SizedBox(height: 14),
        _buildTournamentCard(
          imageUrl: 'https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff?w=120&h=100&fit=crop',
          title: 'Pro Master Cup',
          entryFee: 'Level 10',
          entryFeeColor: const Color(0xFF00D26A),
          teams: 'Starts in 2h',
          date: '',
          isLocked: true,
        ),
      ],
    );
  }

  Widget _buildTournamentCard({
    required String imageUrl,
    required String title,
    required String entryFee,
    required Color entryFeeColor,
    required String teams,
    required String date,
    String? daysLeft,
    int? participants,
    String? specialTag,
    required bool isLocked,
  }) {
    return Opacity(
      opacity: isLocked ? 0.7 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F2A20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1A3D30),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Tournament Image
            Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (daysLeft != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        daysLeft,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Tournament Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.bookmark_border,
                          color: Colors.grey[500],
                          size: 18,
                        ),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Entry Fee
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      children: [
                        const TextSpan(text: 'Entry: '),
                        TextSpan(
                          text: entryFee,
                          style: TextStyle(
                            color: entryFeeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Meta
                  Row(
                    children: [
                      _buildMetaItem(Icons.people_outline, teams),
                      if (date.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        _buildMetaItem(Icons.calendar_today, date),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (participants != null)
                        _buildParticipants(participants)
                      else if (specialTag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D26A).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            specialTag,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00D26A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      if (isLocked)
                        Text(
                          'Locked',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF00D26A), width: 1.5),
                            foregroundColor: const Color(0xFF00D26A),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'JOIN NOW',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
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

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipants(int moreCount) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0F2A20), width: 2),
              ),
              child: ClipOval(
                child: Image.network(
                  'https://api.dicebear.com/7.x/avataaars/svg?seed=1',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              left: 16,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0F2A20), width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://api.dicebear.com/7.x/avataaars/svg?seed=2',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Text(
          '+$moreCount',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A1A14).withOpacity(0.95),
            const Color(0xFF0A1A14),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, null, 'home'),
          _buildNavItem(Icons.layers, 'Events', 'events', isActive: true),
          Transform.translate(
            offset: const Offset(0, -22),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00FF82),
                    Color(0xFF00D26A),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D26A).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Color(0xFF0A1A14),
                size: 28,
              ),
            ),
          ),
          _buildNavItem(Icons.grid_view, null, 'grid'),
          _buildNavItem(Icons.person, null, 'profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String? label, String navKey, {bool isActive = false}) {
    return GestureDetector(
      onTap: () {
        switch (navKey) {
          case 'home':
            context.go('/');
            break;
          case 'events':
            // Already on events page
            break;
          case 'grid':
            // Navigate to grid
            break;
          case 'profile':
            context.go('/profile');
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF00D26A) : Colors.grey[500],
            size: 24,
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isActive ? const Color(0xFF00D26A) : Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
