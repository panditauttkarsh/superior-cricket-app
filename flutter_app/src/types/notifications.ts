/**
 * Notification types
 */

export interface Notification {
    id: string
    userId: string
    type: 'match' | 'team' | 'tournament' | 'academy' | 'payment' | 'system'
    title: string
    message: string
    read: boolean
    actionUrl?: string
    createdAt: string
}

export interface NotificationPreferences {
    userId: string
    email: {
        matchUpdates: boolean
        teamInvites: boolean
        tournamentUpdates: boolean
        paymentReceipts: boolean
    }
    push: {
        matchUpdates: boolean
        teamInvites: boolean
        tournamentUpdates: boolean
    }
    inApp: {
        matchUpdates: boolean
        teamInvites: boolean
        tournamentUpdates: boolean
        academyUpdates: boolean
    }
}

