import { create } from 'zustand'
import { User, AuthSession, UserRole } from '@/types/auth'
import { getCurrentUser, isAuthenticated } from './auth/authService'

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

export interface CartItem {
    id: number
    name: string
    price: string
    quantity: number
    category: string
}

export interface SellItem {
    id: string
    name: string
    description: string
    price: string
    condition: string
    quantity: number
    category: string
}

interface AppState {
    // Auth State
    user: User | null
    isAuthenticated: boolean
    setAuth: (session: AuthSession) => void
    clearAuth: () => void
    checkAuth: () => void
    
    // App State
    teams: Team[]
    matches: Match[]
    cart: CartItem[]
    sellItems: SellItem[]
    addTeam: (team: Omit<Team, 'id' | 'players' | 'logo'>) => void
    addMatch: (match: Omit<Match, 'id' | 'status'>) => void
    addToCart: (item: Omit<CartItem, 'quantity'>) => void
    removeFromCart: (id: number) => void
    updateCartQuantity: (id: number, quantity: number) => void
    clearCart: () => void
    addSellItem: (item: Omit<SellItem, 'id'>) => void
}

export const useAppStore = create<AppState>((set, get) => ({
    // Auth State
    user: null,
    isAuthenticated: false,
    
    setAuth: (session) => {
        localStorage.setItem('auth_user', JSON.stringify(session.user))
        set({ user: session.user, isAuthenticated: true })
    },
    
    clearAuth: () => {
        localStorage.removeItem('auth_user')
        set({ user: null, isAuthenticated: false })
    },
    
    checkAuth: () => {
        const user = getCurrentUser()
        const authenticated = isAuthenticated()
        if (user && authenticated) {
            set({ user, isAuthenticated: true })
        } else {
            // Try to get from localStorage
            const storedUser = localStorage.getItem('auth_user')
            if (storedUser) {
                try {
                    const parsedUser = JSON.parse(storedUser)
                    set({ user: parsedUser, isAuthenticated: authenticated })
                } catch {
                    set({ user: null, isAuthenticated: false })
                }
            } else {
                set({ user: null, isAuthenticated: false })
            }
        }
    },
    
    // Initial Mock Data
    teams: [
        { id: '1', name: 'Royal Strikers', city: 'Mumbai', logo: '/team-logo.png', players: 11 },
        { id: '2', name: 'Kings XI', city: 'Delhi', logo: '/team-logo.png', players: 12 },
    ],
    matches: [
        { id: '1', opponent: 'Kings XI', date: '2024-02-15', type: 'T20', status: 'completed' },
        { id: '2', opponent: 'Super Giants', date: '2024-02-20', type: 'ODI', status: 'upcoming' },
    ],
    cart: [],
    sellItems: [],

    addTeam: (team) => set((state) => ({
        teams: [...state.teams, {
            ...team,
            id: Math.random().toString(36).substr(2, 9),
            players: 1,
            logo: '/team-logo.png'
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
    })),

    addToCart: (item) => set((state) => {
        const existingItem = state.cart.find(cartItem => cartItem.id === item.id)
        if (existingItem) {
            return {
                cart: state.cart.map(cartItem =>
                    cartItem.id === item.id
                        ? { ...cartItem, quantity: cartItem.quantity + 1 }
                        : cartItem
                )
            }
        }
        return {
            cart: [...state.cart, { ...item, quantity: 1 }]
        }
    }),

    removeFromCart: (id) => set((state) => ({
        cart: state.cart.filter(item => item.id !== id)
    })),

    updateCartQuantity: (id, quantity) => set((state) => ({
        cart: state.cart.map(item =>
            item.id === id ? { ...item, quantity } : item
        ).filter(item => item.quantity > 0)
    })),

    clearCart: () => set({ cart: [] }),

    addSellItem: (item) => set((state) => ({
        sellItems: [...state.sellItems, {
            ...item,
            id: Math.random().toString(36).substr(2, 9)
        }]
    }))
}))
