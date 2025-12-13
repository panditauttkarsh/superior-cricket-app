import { NextResponse } from 'next/server'
import { logout } from '@/lib/auth/authService'

export async function POST() {
    try {
        logout()
        return NextResponse.json({ success: true, message: 'Logged out successfully' })
    } catch (error: any) {
        return NextResponse.json(
            { error: error.message || 'Logout failed' },
            { status: 500 }
        )
    }
}

