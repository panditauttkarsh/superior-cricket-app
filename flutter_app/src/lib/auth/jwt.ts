/**
 * JWT Token Management
 * Handles token creation, validation, and refresh
 */

export interface JWTPayload {
    userId: string
    email: string
    role: string
    iat?: number
    exp?: number
}

/**
 * Generate JWT token (client-side simulation)
 * In production, this would be done on the server
 */
export function generateToken(payload: Omit<JWTPayload, 'iat' | 'exp'>): string {
    // Simulated token generation
    // In production, use a proper JWT library like 'jsonwebtoken'
    const tokenData = {
        ...payload,
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60) // 7 days
    }
    
    // Base64 encode (simplified - use proper JWT in production)
    return btoa(JSON.stringify(tokenData))
}

/**
 * Decode JWT token
 */
export function decodeToken(token: string): JWTPayload | null {
    try {
        const decoded = JSON.parse(atob(token))
        return decoded as JWTPayload
    } catch (error) {
        console.error('Token decode error:', error)
        return null
    }
}

/**
 * Check if token is expired
 */
export function isTokenExpired(token: string): boolean {
    const payload = decodeToken(token)
    if (!payload || !payload.exp) return true
    
    return Date.now() / 1000 >= payload.exp
}

/**
 * Get token expiration time
 */
export function getTokenExpiration(token: string): number | null {
    const payload = decodeToken(token)
    return payload?.exp || null
}

/**
 * Store token in localStorage
 */
export function storeToken(token: string, refreshToken?: string): void {
    localStorage.setItem('auth_token', token)
    if (refreshToken) {
        localStorage.setItem('auth_refresh_token', refreshToken)
    }
}

/**
 * Get token from localStorage
 */
export function getStoredToken(): string | null {
    return localStorage.getItem('auth_token')
}

/**
 * Get refresh token from localStorage
 */
export function getStoredRefreshToken(): string | null {
    return localStorage.getItem('auth_refresh_token')
}

/**
 * Remove tokens from localStorage
 */
export function clearTokens(): void {
    localStorage.removeItem('auth_token')
    localStorage.removeItem('auth_refresh_token')
}

