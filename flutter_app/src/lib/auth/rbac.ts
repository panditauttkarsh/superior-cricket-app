/**
 * Role-Based Access Control (RBAC)
 * Manages permissions and access control based on user roles
 */

import { User, UserRole } from '@/types/auth'

export interface Permission {
    resource: string
    action: string
}

// Define permissions for each role
const ROLE_PERMISSIONS: Record<UserRole, Permission[]> = {
    player: [
        { resource: 'profile', action: 'read' },
        { resource: 'profile', action: 'update' },
        { resource: 'matches', action: 'read' },
        { resource: 'matches', action: 'view' },
        { resource: 'stats', action: 'read' },
        { resource: 'teams', action: 'read' },
        { resource: 'teams', action: 'join' },
    ],
    coach: [
        { resource: 'profile', action: 'read' },
        { resource: 'profile', action: 'update' },
        { resource: 'matches', action: 'read' },
        { resource: 'matches', action: 'view' },
        { resource: 'matches', action: 'create' },
        { resource: 'stats', action: 'read' },
        { resource: 'stats', action: 'update' },
        { resource: 'teams', action: 'read' },
        { resource: 'teams', action: 'manage' },
        { resource: 'players', action: 'read' },
        { resource: 'players', action: 'manage' },
    ],
    admin: [
        { resource: '*', action: '*' }, // Full access
    ],
    academy: [
        { resource: 'profile', action: 'read' },
        { resource: 'profile', action: 'update' },
        { resource: 'academy', action: 'read' },
        { resource: 'academy', action: 'manage' },
        { resource: 'training', action: 'read' },
        { resource: 'training', action: 'create' },
        { resource: 'training', action: 'update' },
        { resource: 'players', action: 'read' },
        { resource: 'attendance', action: 'read' },
        { resource: 'attendance', action: 'update' },
    ],
    tournament: [
        { resource: 'profile', action: 'read' },
        { resource: 'profile', action: 'update' },
        { resource: 'tournament', action: 'read' },
        { resource: 'tournament', action: 'manage' },
        { resource: 'matches', action: 'read' },
        { resource: 'matches', action: 'create' },
        { resource: 'matches', action: 'update' },
        { resource: 'fixtures', action: 'read' },
        { resource: 'fixtures', action: 'create' },
        { resource: 'fixtures', action: 'update' },
        { resource: 'players', action: 'read' },
    ],
}

/**
 * Check if user has permission for a resource and action
 */
export function hasPermission(
    user: User | null,
    resource: string,
    action: string
): boolean {
    if (!user) return false

    // Admin has full access
    if (user.role === 'admin') return true

    const permissions = ROLE_PERMISSIONS[user.role] || []
    
    return permissions.some(
        (perm) =>
            (perm.resource === resource || perm.resource === '*') &&
            (perm.action === action || perm.action === '*')
    )
}

/**
 * Check if user can access a route
 */
export function canAccessRoute(user: User | null, route: string): boolean {
    if (!user) return false

    // Admin can access everything
    if (user.role === 'admin') return true

    // Define route-to-resource mapping
    const routeMap: Record<string, { resource: string; action: string }> = {
        '/profile': { resource: 'profile', action: 'read' },
        '/matches': { resource: 'matches', action: 'read' },
        '/teams': { resource: 'teams', action: 'read' },
        '/players': { resource: 'players', action: 'read' },
        '/admin': { resource: '*', action: '*' },
        '/coach': { resource: 'teams', action: 'manage' },
        '/academy': { resource: 'academy', action: 'read' },
        '/tournament': { resource: 'tournament', action: 'read' },
    }

    const routeConfig = routeMap[route]
    if (!routeConfig) return true // Allow unknown routes

    return hasPermission(user, routeConfig.resource, routeConfig.action)
}

/**
 * Get allowed routes for a user role
 */
export function getAllowedRoutes(role: UserRole): string[] {
    const roleRoutes: Record<UserRole, string[]> = {
        player: ['/profile', '/matches', '/teams', '/players', '/shop', '/grounds'],
        coach: ['/profile', '/matches', '/teams', '/players', '/coach', '/shop', '/grounds'],
        admin: ['*'], // All routes
        academy: ['/profile', '/academy', '/players', '/matches', '/shop', '/grounds'],
        tournament: ['/profile', '/tournament', '/matches', '/players', '/shop', '/grounds'],
    }

    return roleRoutes[role] || []
}

/**
 * Check if user role matches required role
 */
export function requireRole(user: User | null, roles: UserRole[]): boolean {
    if (!user) return false
    return roles.includes(user.role)
}

