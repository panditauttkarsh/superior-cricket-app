'use client'

import { useEffect } from 'react'
import { Sidebar } from '@/components/layout/Sidebar'
import { Header } from '@/components/layout/Header'
import { ProtectedRoute } from '@/components/auth/ProtectedRoute'
import { useAppStore } from '@/lib/store'
import Image from 'next/image'

export default function DashboardLayout({
    children,
}: {
    children: React.ReactNode
}) {
    const { checkAuth } = useAppStore()

    useEffect(() => {
        checkAuth()
    }, [checkAuth])

    return (
        <ProtectedRoute>
        <div className="relative min-h-screen flex flex-col md:flex-row overflow-hidden">
            {/* Background Image */}
            <div className="fixed inset-0 z-0">
                <Image
                    src="/background.png"
                    alt="Cricket Stadium Background"
                    fill
                    className="object-cover"
                    priority
                />
                <div className="absolute inset-0 bg-background/80 backdrop-blur-sm" />
            </div>

            {/* Sidebar */}
            <Sidebar className="fixed left-0 top-0 bottom-0 w-64 h-full bg-sidebar/60 backdrop-blur-md border-r border-sidebar-border/50 z-10 hidden md:block" />
            
            {/* Content */}
            <div className="relative z-10 flex-1 flex flex-col md:ml-64">
                <Header />
                <main className="flex-1 pt-4 pb-4 pr-4 md:pt-6 md:pb-6 md:pr-6 lg:pt-8 lg:pb-8 lg:pr-8 pl-0 w-full overflow-x-hidden">
                    {children}
                </main>
            </div>
        </div>
        </ProtectedRoute>
    )
}
