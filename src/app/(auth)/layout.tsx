import React from 'react'
import { Trophy } from 'lucide-react'

export default function AuthLayout({
    children,
}: {
    children: React.ReactNode
}) {
    return (
        <div className="min-h-screen w-full lg:grid lg:grid-cols-2">
            <div className="hidden bg-primary lg:flex flex-col justify-between p-10 text-primary-foreground">
                <div className="flex items-center gap-2 text-2xl font-bold">
                    <Trophy className="h-8 w-8 text-accent" />
                    <span>Superior Cricket</span>
                </div>
                <div className="space-y-4">
                    <blockquote className="space-y-2">
                        <p className="text-lg">
                            &ldquo;The best cricket scoring app I've ever used. It's not just about the numbers, it's about the experience.&rdquo;
                        </p>
                        <footer className="text-sm opacity-80">
                            - Virat K., Club Captain
                        </footer>
                    </blockquote>
                </div>
            </div>
            <div className="flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8 bg-background">
                {children}
            </div>
        </div>
    )
}
