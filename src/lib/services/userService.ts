/**
 * User Service
 * Handles user profile management and operations
 */

import { User, UserRole } from '@/types/auth'

// Mock user database (replace with actual API calls)
let MOCK_USERS: User[] = [
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
 * Get user by ID
 */
export async function getUserById(userId: string): Promise<User | null> {
    await new Promise(resolve => setTimeout(resolve, 300))
    return MOCK_USERS.find(u => u.id === userId) || null
}

/**
 * Get user by email
 */
export async function getUserByEmail(email: string): Promise<User | null> {
    await new Promise(resolve => setTimeout(resolve, 300))
    return MOCK_USERS.find(u => u.email === email) || null
}

/**
 * Update user profile
 */
export async function updateUserProfile(
    userId: string,
    updates: Partial<Omit<User, 'id' | 'createdAt' | 'updatedAt'>>
): Promise<User> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const userIndex = MOCK_USERS.findIndex(u => u.id === userId)
    if (userIndex === -1) {
        throw new Error('User not found')
    }
    
    const updatedUser: User = {
        ...MOCK_USERS[userIndex],
        ...updates,
        updatedAt: new Date().toISOString()
    }
    
    MOCK_USERS[userIndex] = updatedUser
    
    // Update localStorage if it's the current user
    const storedUser = localStorage.getItem('auth_user')
    if (storedUser) {
        try {
            const parsedUser = JSON.parse(storedUser)
            if (parsedUser.id === userId) {
                localStorage.setItem('auth_user', JSON.stringify(updatedUser))
            }
        } catch {
            // Ignore parse errors
        }
    }
    
    return updatedUser
}

/**
 * Update user role (Admin only)
 */
export async function updateUserRole(
    userId: string,
    role: UserRole
): Promise<User> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const userIndex = MOCK_USERS.findIndex(u => u.id === userId)
    if (userIndex === -1) {
        throw new Error('User not found')
    }
    
    const updatedUser: User = {
        ...MOCK_USERS[userIndex],
        role,
        updatedAt: new Date().toISOString()
    }
    
    MOCK_USERS[userIndex] = updatedUser
    return updatedUser
}

/**
 * Get all users (Admin only)
 */
export async function getAllUsers(): Promise<User[]> {
    await new Promise(resolve => setTimeout(resolve, 500))
    return [...MOCK_USERS]
}

/**
 * Delete user (Admin only)
 */
export async function deleteUser(userId: string): Promise<void> {
    await new Promise(resolve => setTimeout(resolve, 500))
    MOCK_USERS = MOCK_USERS.filter(u => u.id !== userId)
}

/**
 * Create new user
 */
export async function createUser(
    userData: Omit<User, 'id' | 'createdAt' | 'updatedAt'>
): Promise<User> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const newUser: User = {
        ...userData,
        id: Math.random().toString(36).substr(2, 9),
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    }
    
    MOCK_USERS.push(newUser)
    return newUser
}

