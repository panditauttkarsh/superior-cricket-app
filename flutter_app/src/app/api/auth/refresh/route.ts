import { NextRequest, NextResponse } from 'next/server'
import { refreshToken } from '@/lib/auth/authService'

export async function POST(request: NextRequest) {
    try {
        const body = await request.json()
        const { refreshToken: token } = body

        if (!token) {
            return NextResponse.json(
                { error: 'Refresh token is required' },
                { status: 400 }
            )
        }

        const session = await refreshToken(token)

        return NextResponse.json({
            success: true,
            session
        })
    } catch (error: any) {
        return NextResponse.json(
            { error: error.message || 'Token refresh failed' },
            { status: 401 }
        )
    }
}

