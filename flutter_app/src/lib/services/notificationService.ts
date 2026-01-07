/**
 * Notification Service
 * Handles in-app, email, and push notifications
 */

import { Notification, NotificationPreferences } from '@/types/notifications'

/**
 * Get notifications for user
 */
export async function getNotifications(userId: string): Promise<Notification[]> {
    await new Promise(resolve => setTimeout(resolve, 300))
    
    return [
        {
            id: '1',
            userId,
            type: 'match',
            title: 'Match Starting Soon',
            message: 'Your match against Kings XI starts in 30 minutes',
            read: false,
            actionUrl: '/matches/1',
            createdAt: new Date().toISOString()
        }
    ]
}

/**
 * Mark notification as read
 */
export async function markAsRead(notificationId: string): Promise<void> {
    await new Promise(resolve => setTimeout(resolve, 200))
}

/**
 * Get notification preferences
 */
export async function getNotificationPreferences(userId: string): Promise<NotificationPreferences> {
    await new Promise(resolve => setTimeout(resolve, 200))
    
    return {
        userId,
        email: {
            matchUpdates: true,
            teamInvites: true,
            tournamentUpdates: true,
            paymentReceipts: true
        },
        push: {
            matchUpdates: true,
            teamInvites: true,
            tournamentUpdates: true
        },
        inApp: {
            matchUpdates: true,
            teamInvites: true,
            tournamentUpdates: true,
            academyUpdates: true
        }
    }
}

/**
 * Update notification preferences
 */
export async function updateNotificationPreferences(
    userId: string,
    preferences: Partial<NotificationPreferences>
): Promise<NotificationPreferences> {
    await new Promise(resolve => setTimeout(resolve, 300))
    
    const current = await getNotificationPreferences(userId)
    return { ...current, ...preferences }
}

/**
 * Send notification
 */
export async function sendNotification(notification: Omit<Notification, 'id' | 'createdAt'>): Promise<Notification> {
    await new Promise(resolve => setTimeout(resolve, 300))
    
    return {
        ...notification,
        id: Math.random().toString(36).substr(2, 9),
        createdAt: new Date().toISOString()
    }
}

