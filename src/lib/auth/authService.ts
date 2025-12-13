/**
 * Authentication Service
 * Handles all authentication operations
 */

import { User, LoginCredentials, OAuthProvider, AuthSession, UserRole } from '@/types/auth'
import { generateToken, storeToken, clearTokens, isTokenExpired, getStoredToken } from './jwt'

// Mock user database (replace with actual API calls)
const MOCK_USERS: User[] = [
    {
        id: '1',
        email: 'user@example.com',
        name: 'SCricPlayUser',
        role: 'player',
        phone: '+91 98765 43210',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    }
]

/**
 * Email/Password Login
 */
export async function loginWithEmail(credentials: LoginCredentials): Promise<AuthSession> {
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    // Find user (in production, this would be an API call)
    const user = MOCK_USERS.find(u => u.email === credentials.email)
    
    if (!user) {
        throw new Error('Invalid email or password')
    }
    
    // In production, verify password hash on server
    // For now, accept any password for demo
    if (credentials.password.length < 6) {
        throw new Error('Password must be at least 6 characters')
    }
    
    // Generate tokens
    const token = generateToken({
        userId: user.id,
        email: user.email,
        role: user.role
    })
    
    const refreshToken = generateToken({
        userId: user.id,
        email: user.email,
        role: user.role
    })
    
    const session: AuthSession = {
        token,
        refreshToken,
        user,
        expiresAt: Date.now() + (7 * 24 * 60 * 60 * 1000) // 7 days
    }
    
    // Store tokens
    storeToken(token, refreshToken)
    
    return session
}

/**
 * Google OAuth Login
 */
export async function loginWithGoogle(oauthToken: string): Promise<AuthSession> {
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    // In production, verify OAuth token with Google
    // For now, create a mock user
    const user: User = {
        id: Math.random().toString(36).substr(2, 9),
        email: 'google.user@example.com',
        name: 'Google User',
        role: 'player',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    }
    
    const token = generateToken({
        userId: user.id,
        email: user.email,
        role: user.role
    })
    
    const refreshToken = generateToken({
        userId: user.id,
        email: user.email,
        role: user.role
    })
    
    const session: AuthSession = {
        token,
        refreshToken,
        user,
        expiresAt: Date.now() + (7 * 24 * 60 * 60 * 1000)
    }
    
    storeToken(token, refreshToken)
    
    return session
}

/**
 * Apple OAuth Login
 */
export async function loginWithApple(oauthToken: string): Promise<AuthSession> {
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    // In production, verify OAuth token with Apple
    const user: User = {
        id: Math.random().toString(36).substr(2, 9),
        email: 'apple.user@example.com',
        name: 'Apple User',
        role: 'player',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    }
    
    const token = generateToken({
        userId: user.id,
        email: user.email,
        role: user.role
    })
    
    const refreshToken = generateToken({
        userId: user.id,
        email: user.email,
        role: user.role
    })
    
    const session: AuthSession = {
        token,
        refreshToken,
        user,
        expiresAt: Date.now() + (7 * 24 * 60 * 60 * 1000)
    }
    
    storeToken(token, refreshToken)
    
    return session
}

/**
 * Refresh JWT Token
 */
export async function refreshToken(refreshToken: string): Promise<AuthSession> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    // In production, verify refresh token with server
    // For now, decode and create new tokens
    const storedToken = getStoredToken()
    if (!storedToken || isTokenExpired(storedToken)) {
        throw new Error('Invalid or expired token')
    }
    
    // Get user from token (in production, fetch from database)
    // For now, return mock session
    const user: User = {
        id: '1',
        email: 'user@example.com',
        name: 'SCricPlayUser',
        role: 'player',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    }
    
    const newToken = generateToken({
        userId: user.id,
        email: user.email,
        role: user.role
    })
    
    const newRefreshToken = generateToken({
        userId: user.id,
        email: user.email,
        role: user.role
    })
    
    storeToken(newToken, newRefreshToken)
    
    return {
        token: newToken,
        refreshToken: newRefreshToken,
        user,
        expiresAt: Date.now() + (7 * 24 * 60 * 60 * 1000)
    }
}

/**
 * Logout
 */
export function logout(): void {
    clearTokens()
    // Clear user data from localStorage
    localStorage.removeItem('superior_user')
}

/**
 * Get current user from token
 */
export function getCurrentUser(): User | null {
    const token = getStoredToken()
    if (!token || isTokenExpired(token)) {
        return null
    }
    
    // In production, decode token and fetch user from database
    // For now, return mock user
    return MOCK_USERS[0] || null
}

/**
 * Check if user is authenticated
 */
export function isAuthenticated(): boolean {
    const token = getStoredToken()
    return token !== null && !isTokenExpired(token)
}

/**
 * Check user role
 */
export function hasRole(user: User | null, role: UserRole): boolean {
    return user?.role === role
}

/**
 * Check if user has any of the specified roles
 */
export function hasAnyRole(user: User | null, roles: UserRole[]): boolean {
    return user ? roles.includes(user.role) : false
}

