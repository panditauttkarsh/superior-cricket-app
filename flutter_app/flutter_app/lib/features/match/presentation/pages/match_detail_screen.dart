import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;
  
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7), // background-light
      body: SafeArea(
        child: Column(
          children: [
            // Status Bar (simulated)
            Container(
              height: 12,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '9:41',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[900],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.signal_cellular_alt, size: 14, color: Colors.grey[900]),
                      const SizedBox(width: 4),
                      Icon(Icons.wifi, size: 14, color: Colors.grey[900]),
                      const SizedBox(width: 4),
                      Icon(Icons.battery_full, size: 14, color: Colors.grey[900]),
                    ],
                  ),
                ],
              ),
            ),
            
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF205A28)),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Text(
                    'Match Detail',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF205A28),
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Color(0xFF205A28)),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    children: [
                      // Match Header Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: _buildMatchHeaderCard(),
                      ),
                      
                      // Tabs
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTab('Scorecard', 0),
                              _buildTab('Commentary', 1),
                              _buildTab('Highlights', 2),
                              _buildTab('Squads', 3),
                            ],
                          ),
                        ),
                      ),
                      
                      // Tab Content
                      _buildTabContent(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom indicator
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              width: 128,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // card-dark
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background blur circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF205A28).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF205A28).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Content
          Column(
            children: [
              // LIVE badge and Tournament
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLiveBadge(),
                  Text(
                    'T20 World Cup • Final',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Teams and Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Team 1
                  Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[700]!.withOpacity(0.5),
                          border: Border.all(
                            color: Colors.grey[600]!,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'IND',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Score
                  Column(
                    children: [
                      const Text(
                        '182/4',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '18.4 Overs',
                        style: TextStyle(
                          color: Color(0xFF66BB6A),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CRR: 9.75',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  
                  // Team 2
                  Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[700]!.withOpacity(0.5),
                          border: Border.all(
                            color: Colors.grey[600]!,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'AUS',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Status Text
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    const TextSpan(text: 'IND need '),
                    const TextSpan(
                      text: '12 runs',
                      style: TextStyle(
                        color: Color(0xFF66BB6A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' in '),
                    const TextSpan(
                      text: '8 balls',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFC72B32), // accent red
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red[900]!.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.75 * (1 - value)),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                  onEnd: () {
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _tabController.animateTo(index);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF205A28) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? const Color(0xFF205A28)
                : Colors.grey[400],
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildScorecardTab();
      case 1:
        return _buildCommentaryTab();
      case 2:
        return _buildHighlightsTab();
      case 3:
        return _buildSquadsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildScorecardTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Batting Section
          _buildBattingSection(),
          
          const SizedBox(height: 24),
          
          // Bowling Section
          _buildBowlingSection(),
          
          const SizedBox(height: 24),
          
          // Fall of Wickets
          _buildFallOfWickets(),
        ],
      ),
    );
  }

  Widget _buildBattingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'BATTING',
              style: TextStyle(
                color: Color(0xFF205A28),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              'IND Innings',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
              5: FlexColumnWidth(1),
            },
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                children: [
                  _buildTableHeader('Batter'),
                  _buildTableHeader('R', TextAlign.right),
                  _buildTableHeader('B', TextAlign.right),
                  _buildTableHeader('4s', TextAlign.right),
                  _buildTableHeader('6s', TextAlign.right),
                  _buildTableHeader('SR', TextAlign.right),
                ],
              ),
              // Row 1
              _buildBattingRow(
                name: 'Rohit Sharma',
                dismissal: 'c Smith b Starc',
                runs: '45',
                balls: '32',
                fours: '4',
                sixes: '2',
                sr: '140.6',
                isNotOut: false,
              ),
              // Row 2
              _buildBattingRow(
                name: 'Virat Kohli',
                dismissal: 'not out',
                runs: '82',
                balls: '53',
                fours: '6',
                sixes: '4',
                sr: '154.7',
                isNotOut: true,
              ),
              // Row 3
              _buildBattingRow(
                name: 'Suryakumar Yadav',
                dismissal: 'b Zampa',
                runs: '12',
                balls: '8',
                fours: '1',
                sixes: '1',
                sr: '150.0',
                isNotOut: false,
              ),
              // Row 4
              _buildBattingRow(
                name: 'Hardik Pandya',
                dismissal: 'not out',
                runs: '18',
                balls: '10',
                fours: '2',
                sixes: '1',
                sr: '180.0',
                isNotOut: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(String text, [TextAlign align = TextAlign.left]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  TableRow _buildBattingRow({
    required String name,
    required String dismissal,
    required String runs,
    required String balls,
    required String fours,
    required String sixes,
    required String sr,
    required bool isNotOut,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[100]!),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFF205A28),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isNotOut) ...[
                    const SizedBox(width: 4),
                    const Text(
                      '*',
                      style: TextStyle(
                        color: Color(0xFFC72B32),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                dismissal,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        _buildTableCell(runs, isBold: true),
        _buildTableCell(balls),
        _buildTableCell(fours),
        _buildTableCell(sixes),
        _buildTableCell(sr),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isBold = false, bool isAccent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: isAccent
              ? const Color(0xFFC72B32)
              : isBold
                  ? Colors.black87
                  : Colors.grey[500],
          fontSize: 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildBowlingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'BOWLING',
              style: TextStyle(
                color: Color(0xFF205A28),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              'AUS',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
              5: FlexColumnWidth(1),
            },
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                children: [
                  _buildTableHeader('Bowler'),
                  _buildTableHeader('O', TextAlign.right),
                  _buildTableHeader('M', TextAlign.right),
                  _buildTableHeader('R', TextAlign.right),
                  _buildTableHeader('W', TextAlign.right),
                  _buildTableHeader('ECO', TextAlign.right),
                ],
              ),
              // Row 1
              _buildBowlingRow(
                name: 'Mitchell Starc',
                overs: '3.4',
                maidens: '0',
                runs: '32',
                wickets: '2',
                economy: '8.7',
                isActive: true,
              ),
              // Row 2
              _buildBowlingRow(
                name: 'Pat Cummins',
                overs: '4.0',
                maidens: '0',
                runs: '28',
                wickets: '0',
                economy: '7.0',
                isActive: false,
              ),
              // Row 3
              _buildBowlingRow(
                name: 'Adam Zampa',
                overs: '4.0',
                maidens: '0',
                runs: '35',
                wickets: '1',
                economy: '8.75',
                isActive: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildBowlingRow({
    required String name,
    required String overs,
    required String maidens,
    required String runs,
    required String wickets,
    required String economy,
    required bool isActive,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[100]!),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF205A28),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 4),
                const Text(
                  '●',
                  style: TextStyle(
                    color: Color(0xFFC72B32),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildTableCell(overs),
        _buildTableCell(maidens),
        _buildTableCell(runs),
        _buildTableCell(wickets, isBold: true, isAccent: true),
        _buildTableCell(economy),
      ],
    );
  }

  Widget _buildFallOfWickets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FALL OF WICKETS',
          style: TextStyle(
            color: Color(0xFF205A28),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.6,
              ),
              children: [
                TextSpan(
                  text: '1-55',
                  style: const TextStyle(
                    color: Color(0xFF205A28),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' (Gill, 5.2 ov), '),
                TextSpan(
                  text: '2-110',
                  style: const TextStyle(
                    color: Color(0xFF205A28),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' (Rohit, 11.4 ov), '),
                TextSpan(
                  text: '3-145',
                  style: const TextStyle(
                    color: Color(0xFF205A28),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' (Suryakumar, 15.1 ov), '),
                TextSpan(
                  text: '4-162',
                  style: const TextStyle(
                    color: Color(0xFF205A28),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' (Pant, 17.3 ov)'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentaryTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Commentary',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildHighlightsTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Highlights',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSquadsTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Squads',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
