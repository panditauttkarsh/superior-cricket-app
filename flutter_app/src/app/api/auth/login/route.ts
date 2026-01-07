import { NextRequest, NextResponse } from 'next/server'
import { loginWithEmail, loginWithGoogle, loginWithApple } from '@/lib/auth/authService'

export async function POST(request: NextRequest) {
    try {
        const body = await request.json()
        const { method, credentials, oauthToken } = body

        let session

        switch (method) {
            case 'email':
                if (!credentials?.email || !credentials?.password) {
                    return NextResponse.json(
                        { error: 'Email and password are required' },
                        { status: 400 }
                    )
                }
                session = await loginWithEmail(credentials)
                break

            case 'google':
                if (!oauthToken) {
                    return NextResponse.json(
                        { error: 'OAuth token is required' },
                        { status: 400 }
                    )
                }
                session = await loginWithGoogle(oauthToken)
                break

            case 'apple':
                if (!oauthToken) {
                    return NextResponse.json(
                        { error: 'OAuth token is required' },
                        { status: 400 }
                    )
                }
                session = await loginWithApple(oauthToken)
                break

            default:
                return NextResponse.json(
                    { error: 'Invalid authentication method' },
                    { status: 400 }
                )
        }

        return NextResponse.json({
            success: true,
            session
        })
    } catch (error: any) {
        return NextResponse.json(
            { error: error.message || 'Authentication failed' },
            { status: 401 }
        )
    }
}

