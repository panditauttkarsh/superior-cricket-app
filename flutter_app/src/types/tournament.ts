/**
 * Tournament-specific types and interfaces
 */

export interface Tournament {
    id: string
    name: string
    description: string
    organizerId: string
    organizerName: string
    startDate: string
    endDate: string
    registrationDeadline: string
    format: 'T20' | 'ODI' | 'Test' | 'Custom'
    status: 'upcoming' | 'registration' | 'ongoing' | 'completed' | 'cancelled'
    maxTeams: number
    currentTeams: number
    teams: TournamentTeam[]
    prizePool?: string
    location: string
    rules?: string[]
    createdAt: string
    updatedAt: string
}

export interface TournamentTeam {
    teamId: string
    teamName: string
    logo?: string
    registeredAt: string
    status: 'registered' | 'confirmed' | 'withdrawn'
}

export interface Fixture {
    id: string
    tournamentId: string
    matchNumber: number
    round: 'group' | 'quarterfinal' | 'semifinal' | 'final'
    team1Id: string
    team1Name: string
    team2Id: string
    team2Name: string
    scheduledDate: string
    scheduledTime: string
    venue: string
    status: 'scheduled' | 'live' | 'completed' | 'cancelled' | 'postponed'
    result?: MatchResult
    createdAt: string
    updatedAt: string
}

export interface MatchResult {
    winnerId: string
    winnerName: string
    team1Score: string
    team2Score: string
    team1Wickets: number
    team2Wickets: number
    team1Overs: number
    team2Overs: number
    manOfTheMatch?: string
    completedAt: string
}

export interface PointsTable {
    tournamentId: string
    standings: PointsTableEntry[]
    updatedAt: string
}

export interface PointsTableEntry {
    teamId: string
    teamName: string
    logo?: string
    played: number
    won: number
    lost: number
    tied: number
    noResult: number
    points: number
    netRunRate: number
    position: number
    change: number // Position change from previous update
}

export interface TournamentLeaderboard {
    tournamentId: string
    type: 'runs' | 'wickets' | 'average' | 'strike-rate' | 'economy'
    entries: TournamentLeaderboardEntry[]
    updatedAt: string
}

export interface TournamentLeaderboardEntry {
    playerId: string
    playerName: string
    teamId: string
    teamName: string
    avatar?: string
    value: number
    rank: number
    matches: number
}

export interface TournamentStats {
    tournamentId: string
    totalMatches: number
    completedMatches: number
    upcomingMatches: number
    totalRuns: number
    totalWickets: number
    highestScore: {
        teamId: string
        teamName: string
        score: string
        matchId: string
    }
    bestBowling: {
        playerId: string
        playerName: string
        figures: string
        matchId: string
    }
    mostRuns: {
        playerId: string
        playerName: string
        runs: number
    }
    mostWickets: {
        playerId: string
        playerName: string
        wickets: number
    }
}

