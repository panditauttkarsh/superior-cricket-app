/**
 * Match Center types for real-time match updates
 */

export interface MatchEvent {
    id: string
    matchId: string
    type: 'ball' | 'wicket' | 'boundary' | 'over' | 'powerplay' | 'drinks' | 'strategic-timeout' | 'match-event'
    timestamp: string
    over: number
    ball: number
    runs: number
    description: string
    playerId?: string
    playerName?: string
    bowlerId?: string
    bowlerName?: string
    isHighlight: boolean
}

export interface LiveScore {
    matchId: string
    team1: {
        id: string
        name: string
        runs: number
        wickets: number
        overs: number
        balls: number
        runRate: number
    }
    team2: {
        id: string
        name: string
        runs: number
        wickets: number
        overs: number
        balls: number
        runRate: number
    }
    currentBatting: 'team1' | 'team2'
    currentOver: number
    currentBall: number
    requiredRunRate?: number
    target?: number
    lastUpdated: string
}

export interface CommentaryEntry {
    id: string
    matchId: string
    over: number
    ball: number
    commentary: string
    runs: number
    timestamp: string
    type: 'four' | 'six' | 'wicket' | 'dot' | 'run' | 'wide' | 'no-ball' | 'bye' | 'leg-bye'
    playerId?: string
    playerName?: string
}

