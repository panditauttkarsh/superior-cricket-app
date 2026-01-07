/**
 * Payment types
 */

export interface Payment {
    id: string
    userId: string
    amount: number
    currency: string
    status: 'pending' | 'completed' | 'failed' | 'refunded'
    method: 'stripe' | 'razorpay' | 'other'
    description: string
    invoiceId?: string
    createdAt: string
    completedAt?: string
}

export interface Subscription {
    id: string
    userId: string
    plan: 'basic' | 'premium' | 'enterprise'
    status: 'active' | 'cancelled' | 'expired'
    startDate: string
    endDate: string
    amount: number
    billingCycle: 'monthly' | 'yearly'
    autoRenew: boolean
}

export interface Invoice {
    id: string
    userId: string
    paymentId: string
    amount: number
    currency: string
    items: InvoiceItem[]
    status: 'draft' | 'sent' | 'paid' | 'overdue'
    issuedAt: string
    dueDate: string
    paidAt?: string
}

export interface InvoiceItem {
    description: string
    quantity: number
    price: number
    total: number
}

