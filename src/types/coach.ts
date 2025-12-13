/**
 * Coach-specific types and interfaces
 */

import { PlayerProfile, PlayerStats } from './player'

export interface Team {
    id: string
    name: string
    city: string
    state: string
    logo?: string
    coachId: string
    players: TeamPlayer[]
    createdAt: string
    updatedAt: string
}

export interface TeamPlayer {
    playerId: string
    playerName: string
    role: 'batsman' | 'bowler' | 'all-rounder' | 'wicket-keeper'
    jerseyNumber: number
    joinedAt: string
    status: 'active' | 'injured' | 'suspended'
    stats?: PlayerStats
}

export interface MatchAnalysis {
    id: string
    matchId: string
    teamId: string
    analysis: {
        batting: {
            totalRuns: number
            wickets: number
            overs: number
            runRate: number
            powerplay: { runs: number; wickets: number }
            middleOvers: { runs: number; wickets: number }
            deathOvers: { runs: number; wickets: number }
            partnerships: Array<{
                players: string[]
                runs: number
                balls: number
            }>
        }
        bowling: {
            totalRuns: number
            wickets: number
            overs: number
            economy: number
            dotBalls: number
            boundaries: number
            extras: number
        }
        fielding: {
            catches: number
            stumpings: number
            runOuts: number
            droppedCatches: number
        }
        keyMoments: Array<{
            timestamp: string
            description: string
            impact: 'positive' | 'negative' | 'neutral'
        }>
    }
    recommendations: string[]
    createdAt: string
}

export interface PlayerPerformance {
    playerId: string
    playerName: string
    matches: number
    recentForm: {
        runs: number[]
        wickets: number[]
        catches: number[]
    }
    strengths: string[]
    weaknesses: string[]
    recommendations: string[]
}

export interface TeamStats {
    teamId: string
    totalMatches: number
    wins: number
    losses: number
    draws: number
    winPercentage: number
    totalRuns: number
    totalWickets: number
    averageScore: number
    bestPerformance: {
        matchId: string
        score: number
        wickets: number
    }
}

export interface SquadSelection {
    matchId: string
    teamId: string
    selectedPlayers: string[] // Player IDs
    playingXI: string[] // Player IDs
    captain: string // Player ID
    viceCaptain: string // Player ID
    createdAt: string
}

