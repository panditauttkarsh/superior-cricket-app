/**
 * Coach Service
 * Handles team management, player monitoring, and match analysis
 */

import { Team, TeamPlayer, MatchAnalysis, PlayerPerformance, TeamStats, SquadSelection } from '@/types/coach'
import { PlayerProfile } from '@/types/player'

// Mock team data
const MOCK_TEAMS: Team[] = [
    {
        id: '1',
        name: 'Royal Strikers',
        city: 'Mumbai',
        state: 'Maharashtra',
        coachId: '1',
        players: [
            {
                playerId: '1',
                playerName: 'SCricPlayUser',
                role: 'all-rounder',
                jerseyNumber: 7,
                joinedAt: new Date('2024-01-15').toISOString(),
                status: 'active'
            },
            {
                playerId: '2',
                playerName: 'Player 2',
                role: 'batsman',
                jerseyNumber: 10,
                joinedAt: new Date('2024-01-20').toISOString(),
                status: 'active'
            },
            {
                playerId: '3',
                playerName: 'Player 3',
                role: 'bowler',
                jerseyNumber: 15,
                joinedAt: new Date('2024-02-01').toISOString(),
                status: 'injured'
            }
        ],
        createdAt: new Date('2024-01-01').toISOString(),
        updatedAt: new Date().toISOString()
    }
]

/**
 * Get teams by coach ID
 */
export async function getTeamsByCoach(coachId: string): Promise<Team[]> {
    await new Promise(resolve => setTimeout(resolve, 300))
    return MOCK_TEAMS.filter(t => t.coachId === coachId)
}

/**
 * Get team by ID
 */
export async function getTeam(teamId: string): Promise<Team | null> {
    await new Promise(resolve => setTimeout(resolve, 300))
    return MOCK_TEAMS.find(t => t.id === teamId) || null
}

/**
 * Create new team
 */
export async function createTeam(team: Omit<Team, 'id' | 'createdAt' | 'updatedAt'>): Promise<Team> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const newTeam: Team = {
        ...team,
        id: Math.random().toString(36).substr(2, 9),
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    }
    
    MOCK_TEAMS.push(newTeam)
    return newTeam
}

/**
 * Update team
 */
export async function updateTeam(teamId: string, updates: Partial<Team>): Promise<Team> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const teamIndex = MOCK_TEAMS.findIndex(t => t.id === teamId)
    if (teamIndex === -1) {
        throw new Error('Team not found')
    }
    
    const updatedTeam: Team = {
        ...MOCK_TEAMS[teamIndex],
        ...updates,
        updatedAt: new Date().toISOString()
    }
    
    MOCK_TEAMS[teamIndex] = updatedTeam
    return updatedTeam
}

/**
 * Add player to team
 */
export async function addPlayerToTeam(teamId: string, player: TeamPlayer): Promise<Team> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const team = await getTeam(teamId)
    if (!team) {
        throw new Error('Team not found')
    }
    
    const updatedPlayers = [...team.players, player]
    return await updateTeam(teamId, { players: updatedPlayers })
}

/**
 * Remove player from team
 */
export async function removePlayerFromTeam(teamId: string, playerId: string): Promise<Team> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const team = await getTeam(teamId)
    if (!team) {
        throw new Error('Team not found')
    }
    
    const updatedPlayers = team.players.filter(p => p.playerId !== playerId)
    return await updateTeam(teamId, { players: updatedPlayers })
}

/**
 * Update player status in team
 */
export async function updatePlayerStatus(
    teamId: string,
    playerId: string,
    status: 'active' | 'injured' | 'suspended'
): Promise<Team> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const team = await getTeam(teamId)
    if (!team) {
        throw new Error('Team not found')
    }
    
    const updatedPlayers = team.players.map(p =>
        p.playerId === playerId ? { ...p, status } : p
    )
    
    return await updateTeam(teamId, { players: updatedPlayers })
}

/**
 * Get match analysis
 */
export async function getMatchAnalysis(matchId: string, teamId: string): Promise<MatchAnalysis | null> {
    await new Promise(resolve => setTimeout(resolve, 400))
    
    // Mock analysis data
    return {
        id: `analysis-${matchId}`,
        matchId,
        teamId,
        analysis: {
            batting: {
                totalRuns: 142,
                wickets: 3,
                overs: 16.4,
                runRate: 8.5,
                powerplay: { runs: 45, wickets: 1 },
                middleOvers: { runs: 67, wickets: 1 },
                deathOvers: { runs: 30, wickets: 1 },
                partnerships: [
                    { players: ['Player 1', 'Player 2'], runs: 45, balls: 38 },
                    { players: ['Player 2', 'Player 3'], runs: 67, balls: 52 }
                ]
            },
            bowling: {
                totalRuns: 135,
                wickets: 5,
                overs: 20,
                economy: 6.75,
                dotBalls: 48,
                boundaries: 12,
                extras: 8
            },
            fielding: {
                catches: 4,
                stumpings: 0,
                runOuts: 1,
                droppedCatches: 2
            },
            keyMoments: [
                {
                    timestamp: new Date().toISOString(),
                    description: 'Strong powerplay start with 45/1',
                    impact: 'positive'
                },
                {
                    timestamp: new Date().toISOString(),
                    description: 'Dropped catch in 12th over',
                    impact: 'negative'
                }
            ]
        },
        recommendations: [
            'Focus on improving fielding - 2 dropped catches',
            'Death over bowling needs improvement',
            'Partnership building was excellent'
        ],
        createdAt: new Date().toISOString()
    }
}

/**
 * Get player performance analysis
 */
export async function getPlayerPerformance(playerId: string): Promise<PlayerPerformance | null> {
    await new Promise(resolve => setTimeout(resolve, 400))
    
    return {
        playerId,
        playerName: 'SCricPlayUser',
        matches: 25,
        recentForm: {
            runs: [45, 67, 23, 89, 34],
            wickets: [2, 1, 3, 0, 2],
            catches: [1, 0, 2, 1, 0]
        },
        strengths: [
            'Excellent all-rounder capabilities',
            'Strong batting in middle overs',
            'Reliable medium-pace bowling'
        ],
        weaknesses: [
            'Struggles against spin in powerplay',
            'Fielding needs improvement'
        ],
        recommendations: [
            'Practice spin batting in nets',
            'Focus on fielding drills',
            'Consider promoting up the order'
        ]
    }
}

/**
 * Get team statistics
 */
export async function getTeamStats(teamId: string): Promise<TeamStats | null> {
    await new Promise(resolve => setTimeout(resolve, 400))
    
    return {
        teamId,
        totalMatches: 25,
        wins: 18,
        losses: 6,
        draws: 1,
        winPercentage: 72,
        totalRuns: 3250,
        totalWickets: 145,
        averageScore: 162.5,
        bestPerformance: {
            matchId: '1',
            score: 198,
            wickets: 2
        }
    }
}

/**
 * Create squad selection
 */
export async function createSquadSelection(selection: Omit<SquadSelection, 'createdAt'>): Promise<SquadSelection> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    return {
        ...selection,
        createdAt: new Date().toISOString()
    }
}

/**
 * Get all players for team selection
 */
export async function getAvailablePlayers(teamId: string): Promise<PlayerProfile[]> {
    await new Promise(resolve => setTimeout(resolve, 400))
    
    // In production, this would fetch players from database
    // For now, return mock data
    return []
}

