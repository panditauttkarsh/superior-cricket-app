export type UserRole = 'player' | 'coach' | 'admin' | 'academy' | 'tournament'

export interface User {
    id: string
    email: string
    name: string
    role: UserRole
    avatar?: string
    phone?: string
    createdAt: string
    updatedAt: string
}

export interface AuthSession {
    token: string
    refreshToken: string
    user: User
    expiresAt: number
}

export interface LoginCredentials {
    email: string
    password: string
}

export interface OAuthProvider {
    provider: 'google' | 'apple'
    token: string
}

export interface AuthState {
    isAuthenticated: boolean
    user: User | null
    token: string | null
    refreshToken: string | null
    isLoading: boolean
}

