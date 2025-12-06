import { create } from 'zustand'

export interface Team {
    id: string
    name: string
    city: string
    logo: string
    players: number
}

export interface Match {
    id: string
    opponent: string
    date: string
    type: string
    status: 'upcoming' | 'live' | 'completed'
}

interface AppState {
    teams: Team[]
    matches: Match[]
    addTeam: (team: Omit<Team, 'id' | 'players' | 'logo'>) => void
    addMatch: (match: Omit<Match, 'id' | 'status'>) => void
}

export const useAppStore = create<AppState>((set) => ({
    // Initial Mock Data
    teams: [
        { id: '1', name: 'Royal Strikers', city: 'Mumbai', logo: '/team-logo.png', players: 11 },
        { id: '2', name: 'Kings XI', city: 'Delhi', logo: '/team-logo.png', players: 12 },
    ],
    matches: [
        { id: '1', opponent: 'Kings XI', date: '2024-02-15', type: 'T20', status: 'completed' },
        { id: '2', opponent: 'Super Giants', date: '2024-02-20', type: 'ODI', status: 'upcoming' },
    ],

    addTeam: (team) => set((state) => ({
        teams: [...state.teams, {
            ...team,
            id: Math.random().toString(36).substr(2, 9),
            players: 1, // Start with just the creator
            logo: '/team-logo.png' // Default logo
        }]
    })),

    addMatch: (match) => set((state) => ({
        matches: [
            {
                ...match,
                id: Math.random().toString(36).substr(2, 9),
                status: 'upcoming'
            },
            ...state.matches
        ]
    }))
}))
