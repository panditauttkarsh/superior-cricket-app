/**
 * Match Center Service
 * Handles real-time match updates, live commentary, and score tracking
 */

import { MatchEvent, LiveScore, CommentaryEntry } from '@/types/matchCenter'

/**
 * Get live score for match
 */
export async function getLiveScore(matchId: string): Promise<LiveScore | null> {
    await new Promise(resolve => setTimeout(resolve, 300))
    
    return {
        matchId,
        team1: {
            id: '1',
            name: 'Royal Strikers',
            runs: 142,
            wickets: 3,
            overs: 16,
            balls: 4,
            runRate: 8.68
        },
        team2: {
            id: '2',
            name: 'Opponent',
            runs: 0,
            wickets: 0,
            overs: 0,
            balls: 0,
            runRate: 0
        },
        currentBatting: 'team1',
        currentOver: 16,
        currentBall: 4,
        target: 143,
        lastUpdated: new Date().toISOString()
    }
}

/**
 * Get match events
 */
export async function getMatchEvents(matchId: string): Promise<MatchEvent[]> {
    await new Promise(resolve => setTimeout(resolve, 300))
    
    return [
        {
            id: '1',
            matchId,
            type: 'boundary',
            timestamp: new Date().toISOString(),
            over: 16,
            ball: 4,
            runs: 4,
            description: 'FOUR! Beautiful cover drive',
            playerId: '1',
            playerName: 'Player Name',
            isHighlight: true
        }
    ]
}

/**
 * Get live commentary
 */
export async function getLiveCommentary(matchId: string): Promise<CommentaryEntry[]> {
    await new Promise(resolve => setTimeout(resolve, 300))
    
    return [
        {
            id: '1',
            matchId,
            over: 16,
            ball: 4,
            commentary: 'FOUR! Beautiful cover drive. Walks into the shot and caresses it through the covers.',
            runs: 4,
            timestamp: new Date().toISOString(),
            type: 'four',
            playerId: '1',
            playerName: 'Player Name'
        }
    ]
}

/**
 * Subscribe to match updates (WebSocket simulation)
 */
export function subscribeToMatchUpdates(
    matchId: string,
    callback: (event: MatchEvent) => void
): () => void {
    // In production, this would use WebSocket
    const interval = setInterval(() => {
        // Simulate new events
        const event: MatchEvent = {
            id: Math.random().toString(36).substr(2, 9),
            matchId,
            type: 'ball',
            timestamp: new Date().toISOString(),
            over: 17,
            ball: 1,
            runs: 1,
            description: '1 run, pushed to long on',
            isHighlight: false
        }
        callback(event)
    }, 5000) // Simulate every 5 seconds
    
    return () => clearInterval(interval)
}

