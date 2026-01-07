import React from 'react'
import { CricketAnimation } from '@/components/auth/CricketAnimation'

export default function AuthLayout({
    children,
}: {
    children: React.ReactNode
}) {
    return (
        <div className="min-h-screen w-full lg:grid lg:grid-cols-2">
            <div className="hidden lg:block">
                <CricketAnimation />
            </div>
            <div className="flex items-center justify-center min-h-screen w-full py-12 px-4 sm:px-6 lg:px-8 bg-gradient-to-br from-background via-background to-secondary/10">
                <div className="w-full max-w-2xl">
                    {children}
                </div>
            </div>
        </div>
    )
}
