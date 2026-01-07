/**
 * Player-specific types and interfaces
 */

export interface PlayerStats {
    // Batting Stats
    batting: {
        matches: number
        innings: number
        runs: number
        balls: number
        fours: number
        sixes: number
        highestScore: number
        average: number
        strikeRate: number
        centuries: number
        halfCenturies: number
        ducks: number
        notOuts: number
    }
    
    // Bowling Stats
    bowling: {
        matches: number
        innings: number
        overs: number
        maidens: number
        runs: number
        wickets: number
        bestBowling: string // "5/20"
        average: number
        economy: number
        strikeRate: number
        fourWickets: number
        fiveWickets: number
    }
    
    // Fielding Stats
    fielding: {
        catches: number
        stumpings: number
        runOuts: number
    }
    
    // Overall
    totalMatches: number
    totalRuns: number
    totalWickets: number
}

export interface PlayerProfile {
    id: string
    userId: string
    name: string
    avatar?: string
    dateOfBirth: string
    city: string
    state: string
    country: string
    role: 'batsman' | 'bowler' | 'all-rounder' | 'wicket-keeper'
    battingStyle: 'right-handed' | 'left-handed'
    bowlingStyle?: string
    jerseyNumber: number
    teams: string[] // Team IDs
    stats: PlayerStats
    createdAt: string
    updatedAt: string
}

export interface ScorecardEntry {
    id: string
    matchId: string
    playerId: string
    playerName: string
    // Batting
    batting: {
        runs: number
        balls: number
        fours: number
        sixes: number
        strikeRate: number
        dismissed: boolean
        dismissalType?: 'bowled' | 'caught' | 'lbw' | 'run-out' | 'stumped' | 'hit-wicket'
        dismissedBy?: string
    } | null
    // Bowling
    bowling: {
        overs: number
        maidens: number
        runs: number
        wickets: number
        economy: number
    } | null
    // Fielding
    fielding: {
        catches: number
        stumpings: number
        runOuts: number
    } | null
}

export interface LeaderboardEntry {
    playerId: string
    playerName: string
    avatar?: string
    teamName?: string
    value: number
    rank: number
    change: number // Position change from previous period
}

export interface Leaderboard {
    id: string
    title: string
    type: 'runs' | 'wickets' | 'average' | 'strike-rate' | 'economy' | 'catches'
    period: 'overall' | 'season' | 'month' | 'week'
    entries: LeaderboardEntry[]
    updatedAt: string
}

export interface MatchTimelineEvent {
    id: string
    matchId: string
    timestamp: string
    type: 'ball' | 'wicket' | 'boundary' | 'milestone' | 'over' | 'match-event'
    description: string
    playerId?: string
    playerName?: string
    runs?: number
    isHighlight?: boolean
}

