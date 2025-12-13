/**
 * Tournament Service
 * Handles tournament management, fixtures, and statistics
 */

import { Tournament, TournamentTeam, Fixture, PointsTable, PointsTableEntry, TournamentLeaderboard, TournamentStats } from '@/types/tournament'

// Mock tournament data
const MOCK_TOURNAMENTS: Tournament[] = [
    {
        id: '1',
        name: 'CricPlay Championship 2024',
        description: 'The premier cricket tournament featuring the best teams',
        organizerId: '1',
        organizerName: 'CricPlay Organizers',
        startDate: '2024-03-01',
        endDate: '2024-03-31',
        registrationDeadline: '2024-02-25',
        format: 'T20',
        status: 'ongoing',
        maxTeams: 8,
        currentTeams: 6,
        teams: [
            {
                teamId: '1',
                teamName: 'Royal Strikers',
                registeredAt: new Date('2024-02-15').toISOString(),
                status: 'confirmed'
            },
            {
                teamId: '2',
                teamName: 'Kings XI',
                registeredAt: new Date('2024-02-16').toISOString(),
                status: 'confirmed'
            }
        ],
        prizePool: '₹1,00,000',
        location: 'Mumbai',
        rules: [
            'T20 format',
            'Maximum 16 players per team',
            'All matches will be played at designated venues'
        ],
        createdAt: new Date('2024-01-15').toISOString(),
        updatedAt: new Date().toISOString()
    }
]

/**
 * Get all tournaments
 */
export async function getAllTournaments(): Promise<Tournament[]> {
    await new Promise(resolve => setTimeout(resolve, 300))
    return [...MOCK_TOURNAMENTS]
}

/**
 * Get tournament by ID
 */
export async function getTournament(tournamentId: string): Promise<Tournament | null> {
    await new Promise(resolve => setTimeout(resolve, 300))
    return MOCK_TOURNAMENTS.find(t => t.id === tournamentId) || null
}

/**
 * Get tournaments by organizer
 */
export async function getTournamentsByOrganizer(organizerId: string): Promise<Tournament[]> {
    await new Promise(resolve => setTimeout(resolve, 300))
    return MOCK_TOURNAMENTS.filter(t => t.organizerId === organizerId)
}

/**
 * Create tournament
 */
export async function createTournament(tournament: Omit<Tournament, 'id' | 'createdAt' | 'updatedAt' | 'currentTeams' | 'teams'>): Promise<Tournament> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const newTournament: Tournament = {
        ...tournament,
        id: Math.random().toString(36).substr(2, 9),
        currentTeams: 0,
        teams: [],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    }
    
    MOCK_TOURNAMENTS.push(newTournament)
    return newTournament
}

/**
 * Update tournament
 */
export async function updateTournament(tournamentId: string, updates: Partial<Tournament>): Promise<Tournament> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const tournamentIndex = MOCK_TOURNAMENTS.findIndex(t => t.id === tournamentId)
    if (tournamentIndex === -1) {
        throw new Error('Tournament not found')
    }
    
    const updatedTournament: Tournament = {
        ...MOCK_TOURNAMENTS[tournamentIndex],
        ...updates,
        updatedAt: new Date().toISOString()
    }
    
    MOCK_TOURNAMENTS[tournamentIndex] = updatedTournament
    return updatedTournament
}

/**
 * Register team for tournament
 */
export async function registerTeamForTournament(
    tournamentId: string,
    team: TournamentTeam
): Promise<Tournament> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const tournament = await getTournament(tournamentId)
    if (!tournament) {
        throw new Error('Tournament not found')
    }
    
    if (tournament.currentTeams >= tournament.maxTeams) {
        throw new Error('Tournament is full')
    }
    
    if (tournament.status !== 'registration' && tournament.status !== 'upcoming') {
        throw new Error('Registration is closed')
    }
    
    const updatedTeams = [...tournament.teams, team]
    return await updateTournament(tournamentId, {
        teams: updatedTeams,
        currentTeams: updatedTeams.length
    })
}

/**
 * Get fixtures for tournament
 */
export async function getTournamentFixtures(tournamentId: string): Promise<Fixture[]> {
    await new Promise(resolve => setTimeout(resolve, 400))
    
    // Mock fixtures
    return [
        {
            id: '1',
            tournamentId,
            matchNumber: 1,
            round: 'group',
            team1Id: '1',
            team1Name: 'Royal Strikers',
            team2Id: '2',
            team2Name: 'Kings XI',
            scheduledDate: '2024-03-05',
            scheduledTime: '14:00',
            venue: 'Wankhede Stadium, Mumbai',
            status: 'completed',
            result: {
                winnerId: '1',
                winnerName: 'Royal Strikers',
                team1Score: '142/3',
                team2Score: '135/5',
                team1Wickets: 3,
                team2Wickets: 5,
                team1Overs: 20,
                team2Overs: 20,
                manOfTheMatch: 'Player Name',
                completedAt: new Date().toISOString()
            },
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        },
        {
            id: '2',
            tournamentId,
            matchNumber: 2,
            round: 'group',
            team1Id: '3',
            team1Name: 'Super Giants',
            team2Id: '4',
            team2Name: 'Thunder Bolts',
            scheduledDate: '2024-03-06',
            scheduledTime: '14:00',
            venue: 'Eden Gardens, Kolkata',
            status: 'scheduled',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        }
    ]
}

/**
 * Create fixture
 */
export async function createFixture(fixture: Omit<Fixture, 'id' | 'createdAt' | 'updatedAt'>): Promise<Fixture> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    return {
        ...fixture,
        id: Math.random().toString(36).substr(2, 9),
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    }
}

/**
 * Get points table
 */
export async function getPointsTable(tournamentId: string): Promise<PointsTable | null> {
    await new Promise(resolve => setTimeout(resolve, 400))
    
    const standings: PointsTableEntry[] = [
        {
            teamId: '1',
            teamName: 'Royal Strikers',
            played: 5,
            won: 4,
            lost: 1,
            tied: 0,
            noResult: 0,
            points: 8,
            netRunRate: 0.85,
            position: 1,
            change: 0
        },
        {
            teamId: '2',
            teamName: 'Kings XI',
            played: 5,
            won: 3,
            lost: 2,
            tied: 0,
            noResult: 0,
            points: 6,
            netRunRate: 0.42,
            position: 2,
            change: 1
        },
        {
            teamId: '3',
            teamName: 'Super Giants',
            played: 5,
            won: 2,
            lost: 3,
            tied: 0,
            noResult: 0,
            points: 4,
            netRunRate: -0.15,
            position: 3,
            change: -1
        }
    ]
    
    return {
        tournamentId,
        standings,
        updatedAt: new Date().toISOString()
    }
}

/**
 * Get tournament leaderboard
 */
export async function getTournamentLeaderboard(
    tournamentId: string,
    type: 'runs' | 'wickets' | 'average' | 'strike-rate' | 'economy'
): Promise<TournamentLeaderboard | null> {
    await new Promise(resolve => setTimeout(resolve, 400))
    
    const entries = [
        {
            playerId: '1',
            playerName: 'SCricPlayUser',
            teamId: '1',
            teamName: 'Royal Strikers',
            value: type === 'runs' ? 245 : type === 'wickets' ? 12 : 45.2,
            rank: 1,
            matches: 5
        },
        {
            playerId: '2',
            playerName: 'Player 2',
            teamId: '2',
            teamName: 'Kings XI',
            value: type === 'runs' ? 198 : type === 'wickets' ? 10 : 38.5,
            rank: 2,
            matches: 5
        }
    ]
    
    return {
        tournamentId,
        type,
        entries,
        updatedAt: new Date().toISOString()
    }
}

/**
 * Get tournament statistics
 */
export async function getTournamentStats(tournamentId: string): Promise<TournamentStats | null> {
    await new Promise(resolve => setTimeout(resolve, 400))
    
    return {
        tournamentId,
        totalMatches: 15,
        completedMatches: 10,
        upcomingMatches: 5,
        totalRuns: 2450,
        totalWickets: 120,
        highestScore: {
            teamId: '1',
            teamName: 'Royal Strikers',
            score: '198/2',
            matchId: '1'
        },
        bestBowling: {
            playerId: '1',
            playerName: 'SCricPlayUser',
            figures: '5/25',
            matchId: '1'
        },
        mostRuns: {
            playerId: '1',
            playerName: 'SCricPlayUser',
            runs: 245
        },
        mostWickets: {
            playerId: '1',
            playerName: 'SCricPlayUser',
            wickets: 12
        }
    }
}

