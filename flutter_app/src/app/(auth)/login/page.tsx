'use client'

import { useState, useEffect } from 'react'
import { LoginForm } from '@/components/auth/LoginForm'
import { OnboardingWizard } from '@/components/auth/OnboardingWizard'
import { useAppStore } from '@/lib/store'
import { useRouter } from 'next/navigation'

export default function LoginPage() {
    const router = useRouter()
    const { isAuthenticated, checkAuth } = useAppStore()
    const [isNewUser, setIsNewUser] = useState(false)

    useEffect(() => {
        checkAuth()
        if (isAuthenticated) {
            router.push('/')
        }
    }, [isAuthenticated, router, checkAuth])

    return (
        <div className="flex min-h-screen items-center justify-center p-4">
            {isNewUser ? (
                <OnboardingWizard onBackToLogin={() => setIsNewUser(false)} />
            ) : (
                <div className="w-full max-w-2xl">
                    <LoginForm onSignUp={() => setIsNewUser(true)} />
                </div>
            )}
        </div>
    )
}
