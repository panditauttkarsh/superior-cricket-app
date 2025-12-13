/**
 * AI Engine types for video analysis and predictions
 */

export interface VideoAnalysisRequest {
    videoUrl: string
    type: 'batting' | 'bowling' | 'fielding'
    playerId: string
    matchId?: string
}

export interface VideoAnalysisResult {
    id: string
    videoUrl: string
    analysis: {
        technique: {
            score: number // 0-100
            breakdown: Record<string, number>
        }
        recommendations: string[]
        strengths: string[]
        weaknesses: string[]
    }
    highlights: Highlight[]
    processedAt: string
}

export interface Highlight {
    id: string
    timestamp: number // seconds
    type: 'boundary' | 'wicket' | 'catch' | 'run-out' | 'stumping'
    description: string
    thumbnailUrl: string
}

export interface MatchPrediction {
    matchId: string
    winProbability: {
        team1: number
        team2: number
    }
    predictedScore: {
        team1: number
        team2: number
    }
    keyFactors: string[]
    confidence: number
    generatedAt: string
}

export interface PlayerPerformanceAnalysis {
    playerId: string
    matchId: string
    performance: {
        batting?: {
            expectedRuns: number
            strikeRate: number
            boundaryProbability: number
        }
        bowling?: {
            expectedWickets: number
            economy: number
            dotBallProbability: number
        }
    }
    recommendations: string[]
    generatedAt: string
}

export interface EventDetection {
    matchId: string
    events: DetectedEvent[]
    confidence: number
}

export interface DetectedEvent {
    id: string
    type: 'boundary' | 'wicket' | 'catch' | 'run-out'
    timestamp: number
    playerId?: string
    confidence: number
    frameUrl?: string
}

