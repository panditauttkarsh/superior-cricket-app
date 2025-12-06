'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Plus, Calendar, Trophy, MapPin, Play } from 'lucide-react'
import Image from 'next/image'
import { useAppStore } from '@/lib/store'
import Link from 'next/link'
import { cn } from '@/lib/utils'

export default function MatchesPage() {
    const matches = useAppStore((state) => state.matches)

    const liveMatches = matches.filter(m => m.status === 'live')
    const upcomingMatches = matches.filter(m => m.status === 'upcoming')
    const completedMatches = matches.filter(m => m.status === 'completed')

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold tracking-tight text-foreground/90">Matches</h1>
                <Link href="/">
                    <Button className="shadow-lg shadow-primary/20">
                        <Plus className="mr-2 h-4 w-4" />
                        New Match
                    </Button>
                </Link>
            </div>

            {/* Live Matches Section */}
            {liveMatches.length > 0 && (
                <div className="space-y-4">
                    <h2 className="text-xl font-semibold flex items-center gap-2">
                        <span className="relative flex h-3 w-3">
                            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
                            <span className="relative inline-flex rounded-full h-3 w-3 bg-red-500"></span>
                        </span>
                        Live Now
                    </h2>
                    <div className="grid gap-4 md:grid-cols-1 lg:grid-cols-2">
                        {liveMatches.map(match => (
                            <Card key={match.id} className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl overflow-hidden relative group">
                                <div className="absolute inset-0 bg-gradient-to-r from-red-500/5 to-transparent animate-pulse" />
                                <CardContent className="p-6 relative z-10">
                                    <div className="flex justify-between items-start mb-4">
                                        <div className="flex items-center gap-2 px-2 py-1 bg-red-500/10 text-red-500 rounded text-xs font-bold uppercase tracking-wider">
                                            Live • {match.type}
                                        </div>
                                        <Link href={`/matches/${match.id}`}>
                                            <Button size="sm" className="bg-red-600 hover:bg-red-700 text-white animate-pulse">
                                                <Play className="mr-2 h-3 w-3" /> Watch Commentary
                                            </Button>
                                        </Link>
                                    </div>
                                    <div className="flex items-center justify-between">
                                        <div className="text-center w-1/3">
                                            <div className="font-bold text-lg">Royal Strikers</div>
                                            <div className="text-3xl font-black mt-1">142/3</div>
                                            <div className="text-xs text-muted-foreground">16.4 Overs</div>
                                        </div>
                                        <div className="text-center px-4">
                                            <span className="text-lg font-bold text-muted-foreground">VS</span>
                                        </div>
                                        <div className="text-center w-1/3">
                                            <div className="font-bold text-lg">{match.opponent}</div>
                                            <div className="text-sm font-medium mt-2 text-muted-foreground">Yet to Bat</div>
                                        </div>
                                    </div>
                                </CardContent>
                            </Card>
                        ))}
                    </div>
                </div>
            )}

            {/* Upcoming Matches */}
            <div className="space-y-4">
                <h2 className="text-xl font-semibold">Upcoming</h2>
                {upcomingMatches.length === 0 ? (
                    <p className="text-muted-foreground text-sm">No upcoming matches scheduled.</p>
                ) : (
                    <div className="grid gap-4">
                        {upcomingMatches.map(match => (
                            <Card key={match.id} className="bg-card/60 backdrop-blur-sm border-white/20 hover:bg-white/5 transition-colors">
                                <CardContent className="p-4 flex items-center justify-between">
                                    <div className="flex items-center gap-4">
                                        <div className="h-12 w-12 rounded-full bg-primary/10 flex items-center justify-center font-bold text-primary">
                                            {match.opponent[0]}
                                        </div>
                                        <div>
                                            <h3 className="font-semibold text-lg">vs {match.opponent}</h3>
                                            <div className="flex items-center gap-3 text-sm text-muted-foreground">
                                                <span className="flex items-center"><Calendar className="mr-1 h-3 w-3" /> {match.date}</span>
                                                <span className="flex items-center"><Trophy className="mr-1 h-3 w-3" /> {match.type}</span>
                                            </div>
                                        </div>
                                    </div>
                                    <Link href={`/matches/${match.id}`}>
                                        <Button variant="outline" size="sm">Details</Button>
                                    </Link>
                                </CardContent>
                            </Card>
                        ))}
                    </div>
                )}
            </div>

            {/* Completed Matches */}
            {completedMatches.length > 0 && (
                <div className="space-y-4 pt-4 border-t border-white/10">
                    <h2 className="text-xl font-semibold text-muted-foreground">Completed</h2>
                    <div className="grid gap-4 opacity-75 hover:opacity-100 transition-opacity">
                        {completedMatches.map(match => (
                            <Card key={match.id} className="bg-card/40 backdrop-blur-sm border-white/10">
                                <CardContent className="p-4 flex items-center justify-between">
                                    <div className="flex items-center gap-4">
                                        <div className="h-10 w-10 rounded-full bg-muted flex items-center justify-center filter grayscale">
                                            <Image src="/team-logo.png" alt="Team" width={24} height={24} className="opacity-50" />
                                        </div>
                                        <div>
                                            <h3 className="font-medium">vs {match.opponent}</h3>
                                            <div className="text-xs text-muted-foreground">Result Pending</div>
                                        </div>
                                    </div>
                                    <span className="text-xs font-mono bg-muted px-2 py-1 rounded">COMPLETED</span>
                                </CardContent>
                            </Card>
                        ))}
                    </div>
                </div>
            )}
        </div>
    )
}
