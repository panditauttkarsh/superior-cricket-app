'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAppStore } from '@/lib/store'
import { canAccessRoute } from '@/lib/auth/rbac'

interface ProtectedRouteProps {
    children: React.ReactNode
    requiredRole?: string[]
    fallbackPath?: string
}

export function ProtectedRoute({ 
    children, 
    requiredRole,
    fallbackPath = '/login' 
}: ProtectedRouteProps) {
    const router = useRouter()
    const { user, isAuthenticated, checkAuth } = useAppStore()

    useEffect(() => {
        checkAuth()

        if (!isAuthenticated || !user) {
            router.push(fallbackPath)
            return
        }

        // Check route access
        const currentPath = window.location.pathname
        if (!canAccessRoute(user, currentPath)) {
            router.push('/') // Redirect to home if no access
            return
        }

        // Check role requirement
        if (requiredRole && !requiredRole.includes(user.role)) {
            router.push('/') // Redirect if role doesn't match
        }
    }, [isAuthenticated, user, router, checkAuth, requiredRole, fallbackPath])

    if (!isAuthenticated || !user) {
        return null // Or a loading spinner
    }

    return <>{children}</>
}

