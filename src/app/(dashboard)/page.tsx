'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Plus, Calendar, Users, Trophy } from 'lucide-react'
import Image from 'next/image'
import { QuickActions } from '@/components/dashboard/QuickActions'
import { useAppStore } from '@/lib/store'

export default function DashboardPage() {
    const { matches, teams } = useAppStore()

    const liveMatches = matches.filter(m => m.status === 'live').length
    const upcomingMatches = matches.filter(m => m.status === 'upcoming').length

    return (
        <div className="space-y-6 max-w-6xl mx-auto w-full">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold tracking-tight text-foreground/90">Dashboard</h1>
                <Button className="shadow-lg shadow-primary/20 hover:scale-105 transition-transform">
                    <Plus className="mr-2 h-4 w-4" />
                    New Match
                </Button>
            </div>

            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {/* Live Matches Card */}
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl hover:shadow-2xl transition-all duration-300 group overflow-hidden relative">
                    <div className="absolute inset-0 bg-gradient-to-br from-primary/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2 relative z-10">
                        <CardTitle className="text-sm font-medium">Live Matches</CardTitle>
                        <div className="h-2 w-2 rounded-full bg-accent animate-pulse shadow-[0_0_10px_#10b981]" />
                    </CardHeader>
                    <CardContent className="relative z-10">
                        <div className="text-2xl font-bold">{liveMatches}</div>
                        <p className="text-xs text-muted-foreground">+{upcomingMatches} starting soon</p>
                        <div className="mt-4 h-24 w-full relative rounded-md overflow-hidden">
                            <Image src="/match-thumb.png" alt="Live Match" fill className="object-cover group-hover:scale-110 transition-transform duration-500" />
                            <div className="absolute inset-0 bg-black/40 flex items-center justify-center">
                                <span className="text-white text-xs font-bold px-2 py-1 bg-accent rounded-full">LIVE</span>
                            </div>
                        </div>
                    </CardContent>
                </Card>

                {/* Total Matches Card */}
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl hover:shadow-2xl transition-all duration-300 group">
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                        <CardTitle className="text-sm font-medium">Total Matches</CardTitle>
                        <Trophy className="h-4 w-4 text-muted-foreground group-hover:text-primary transition-colors" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold">{matches.length}</div>
                        <p className="text-xs text-muted-foreground">+3 this week</p>
                    </CardContent>
                </Card>

                {/* Your Teams Card */}
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl hover:shadow-2xl transition-all duration-300 group">
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                        <CardTitle className="text-sm font-medium">Your Teams</CardTitle>
                        <Users className="h-4 w-4 text-muted-foreground group-hover:text-primary transition-colors" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold">{teams.length}</div>
                        <p className="text-xs text-muted-foreground">Active in 2 leagues</p>
                        <div className="mt-4 flex -space-x-2 overflow-hidden">
                            {teams.slice(0, 3).map((team) => (
                                <div key={team.id} className="relative h-8 w-8 rounded-full border-2 border-background overflow-hidden bg-white">
                                    <Image src={team.logo} alt="Team" fill className="object-cover p-1" />
                                </div>
                            ))}
                            {teams.length > 3 && (
                                <div className="flex h-8 w-8 items-center justify-center rounded-full border-2 border-background bg-muted text-xs font-medium">+{teams.length - 3}</div>
                            )}
                        </div>
                    </CardContent>
                </Card>
            </div>

            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
                <Card className="col-span-4 bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardHeader>
                        <CardTitle>Recent Activity</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="space-y-4">
                            {matches.length === 0 ? (
                                <p className="text-muted-foreground text-sm">No recent matches found.</p>
                            ) : (
                                matches.slice(0, 5).map((match) => (
                                    <div key={match.id} className="flex items-center p-3 rounded-lg hover:bg-white/5 transition-colors group cursor-pointer border border-transparent hover:border-white/10">
                                        <div className="relative h-10 w-10 rounded-full overflow-hidden flex-shrink-0 bg-white/10 flex items-center justify-center">
                                            {match.status === 'completed' ? (
                                                <Image src="/team-logo.png" alt="Team" width={40} height={40} className="object-cover" />
                                            ) : (
                                                <Calendar className="h-5 w-5 text-primary" />
                                            )}
                                        </div>
                                        <div className="ml-4 space-y-1">
                                            <p className="text-sm font-medium leading-none group-hover:text-primary transition-colors">
                                                vs {match.opponent}
                                            </p>
                                            <p className="text-sm text-muted-foreground">
                                                {match.status === 'completed' ? 'Match Completed' : `Scheduled for ${match.date} (${match.type})`}
                                            </p>
                                        </div>
                                        <div className="ml-auto font-medium text-xs text-muted-foreground capitalize">
                                            {match.status}
                                        </div>
                                    </div>
                                ))
                            )}
                        </div>
                    </CardContent>
                </Card>

                <QuickActions />
            </div>
        </div>
    )
}
