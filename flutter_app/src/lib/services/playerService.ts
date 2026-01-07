/**
 * Player Service
 * Handles player statistics, scorecards, and related operations
 */

import { PlayerProfile, PlayerStats, ScorecardEntry, Leaderboard, LeaderboardEntry, MatchTimelineEvent } from '@/types/player'

// Mock player data
const MOCK_PLAYER_PROFILES: PlayerProfile[] = [
    {
        id: '1',
        userId: '1',
        name: 'SCricPlayUser',
        city: 'Mumbai',
        state: 'Maharashtra',
        country: 'India',
        dateOfBirth: '1990-05-15',
        role: 'all-rounder',
        battingStyle: 'right-handed',
        bowlingStyle: 'Right-arm Medium',
        jerseyNumber: 7,
        teams: ['1', '2'],
        stats: {
            batting: {
                matches: 25,
                innings: 45,
                runs: 1250,
                balls: 1800,
                fours: 120,
                sixes: 35,
                highestScore: 89,
                average: 35.71,
                strikeRate: 69.44,
                centuries: 0,
                halfCenturies: 8,
                ducks: 3,
                notOuts: 10
            },
            bowling: {
                matches: 25,
                innings: 20,
                overs: 85.2,
                maidens: 8,
                runs: 450,
                wickets: 32,
                bestBowling: '4/25',
                average: 14.06,
                economy: 5.27,
                strikeRate: 16.0,
                fourWickets: 2,
                fiveWickets: 0
            },
            fielding: {
                catches: 18,
                stumpings: 0,
                runOuts: 5
            },
            totalMatches: 25,
            totalRuns: 1250,
            totalWickets: 32
        },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    }
]

/**
 * Get player profile by user ID
 */
export async function getPlayerProfileByUserId(userId: string): Promise<PlayerProfile | null> {
    await new Promise(resolve => setTimeout(resolve, 300))
    return MOCK_PLAYER_PROFILES.find(p => p.userId === userId) || null
}

/**
 * Get player profile by player ID
 */
export async function getPlayerProfile(playerId: string): Promise<PlayerProfile | null> {
    await new Promise(resolve => setTimeout(resolve, 300))
    return MOCK_PLAYER_PROFILES.find(p => p.id === playerId) || null
}

/**
 * Update player statistics
 */
export async function updatePlayerStats(
    playerId: string,
    stats: Partial<PlayerStats>
): Promise<PlayerProfile> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const playerIndex = MOCK_PLAYER_PROFILES.findIndex(p => p.id === playerId)
    if (playerIndex === -1) {
        throw new Error('Player not found')
    }
    
    const updatedPlayer: PlayerProfile = {
        ...MOCK_PLAYER_PROFILES[playerIndex],
        stats: {
            ...MOCK_PLAYER_PROFILES[playerIndex].stats,
            ...stats,
            batting: {
                ...MOCK_PLAYER_PROFILES[playerIndex].stats.batting,
                ...(stats.batting || {})
            },
            bowling: {
                ...MOCK_PLAYER_PROFILES[playerIndex].stats.bowling,
                ...(stats.bowling || {})
            },
            fielding: {
                ...MOCK_PLAYER_PROFILES[playerIndex].stats.fielding,
                ...(stats.fielding || {})
            }
        },
        updatedAt: new Date().toISOString()
    }
    
    MOCK_PLAYER_PROFILES[playerIndex] = updatedPlayer
    return updatedPlayer
}

/**
 * Get scorecards for a player
 */
export async function getPlayerScorecards(playerId: string): Promise<ScorecardEntry[]> {
    await new Promise(resolve => setTimeout(resolve, 400))
    
    // Mock scorecard data
    return [
        {
            id: '1',
            matchId: '1',
            playerId,
            playerName: 'SCricPlayUser',
            batting: {
                runs: 45,
                balls: 38,
                fours: 5,
                sixes: 2,
                strikeRate: 118.42,
                dismissed: true,
                dismissalType: 'caught',
                dismissedBy: 'Player Name'
            },
            bowling: {
                overs: 4.0,
                maidens: 0,
                runs: 28,
                wickets: 2,
                economy: 7.0
            },
            fielding: {
                catches: 1,
                stumpings: 0,
                runOuts: 0
            }
        },
        {
            id: '2',
            matchId: '2',
            playerId,
            playerName: 'SCricPlayUser',
            batting: {
                runs: 67,
                balls: 52,
                fours: 8,
                sixes: 1,
                strikeRate: 128.85,
                dismissed: false,
            },
            bowling: null,
            fielding: {
                catches: 0,
                stumpings: 0,
                runOuts: 1
            }
        }
    ]
}

/**
 * Get leaderboard
 */
export async function getLeaderboard(
    type: 'runs' | 'wickets' | 'average' | 'strike-rate' | 'economy' | 'catches',
    period: 'overall' | 'season' | 'month' | 'week' = 'overall'
): Promise<Leaderboard> {
    await new Promise(resolve => setTimeout(resolve, 400))
    
    // Mock leaderboard data
    const mockEntries: LeaderboardEntry[] = [
        {
            playerId: '1',
            playerName: 'SCricPlayUser',
            avatar: '/avatars/01.png',
            teamName: 'Royal Strikers',
            value: type === 'runs' ? 1250 : type === 'wickets' ? 32 : 35.71,
            rank: 1,
            change: 0
        },
        {
            playerId: '2',
            playerName: 'Player 2',
            avatar: '/avatars/02.png',
            teamName: 'Kings XI',
            value: type === 'runs' ? 1100 : type === 'wickets' ? 28 : 32.5,
            rank: 2,
            change: 1
        },
        {
            playerId: '3',
            playerName: 'Player 3',
            avatar: '/avatars/03.png',
            teamName: 'Super Giants',
            value: type === 'runs' ? 980 : type === 'wickets' ? 25 : 29.8,
            rank: 3,
            change: -1
        }
    ]
    
    return {
        id: `${type}-${period}`,
        title: `${type.charAt(0).toUpperCase() + type.slice(1)} Leaderboard`,
        type,
        period,
        entries: mockEntries,
        updatedAt: new Date().toISOString()
    }
}

/**
 * Get match timeline events
 */
export async function getMatchTimeline(matchId: string): Promise<MatchTimelineEvent[]> {
    await new Promise(resolve => setTimeout(resolve, 300))
    
    return [
        {
            id: '1',
            matchId,
            timestamp: new Date(Date.now() - 3600000).toISOString(),
            type: 'match-event',
            description: 'Match started',
            isHighlight: false
        },
        {
            id: '2',
            matchId,
            timestamp: new Date(Date.now() - 3300000).toISOString(),
            type: 'ball',
            description: 'FOUR! Beautiful cover drive',
            playerId: '1',
            playerName: 'SCricPlayUser',
            runs: 4,
            isHighlight: true
        },
        {
            id: '3',
            matchId,
            timestamp: new Date(Date.now() - 3000000).toISOString(),
            type: 'ball',
            description: 'SIX! That is huge!',
            playerId: '1',
            playerName: 'SCricPlayUser',
            runs: 6,
            isHighlight: true
        },
        {
            id: '4',
            matchId,
            timestamp: new Date(Date.now() - 2700000).toISOString(),
            type: 'wicket',
            description: 'WICKET! Caught by fielder',
            playerId: '2',
            playerName: 'Opponent Player',
            isHighlight: true
        },
        {
            id: '5',
            matchId,
            timestamp: new Date(Date.now() - 2400000).toISOString(),
            type: 'milestone',
            description: '50 runs up for the team',
            isHighlight: false
        }
    ]
}

/**
 * Get all players
 */
export async function getAllPlayers(): Promise<PlayerProfile[]> {
    await new Promise(resolve => setTimeout(resolve, 400))
    return [...MOCK_PLAYER_PROFILES]
}

