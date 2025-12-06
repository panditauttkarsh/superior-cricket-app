'use client'

import { useParams } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { useAppStore } from '@/lib/store'
import { Calendar, MapPin, Trophy, User } from 'lucide-react'
import Image from 'next/image'
import { useState } from 'react'
import { cn } from '@/lib/utils'

export default function MatchDetailsPage() {
    const params = useParams()
    const { matches } = useAppStore()
    const match = matches.find(m => m.id === params.id)
    const [activeTab, setActiveTab] = useState<'info' | 'squads' | 'scorecard' | 'commentary'>('info')

    if (!match) {
        return <div className="p-8 text-center text-muted-foreground">Match not found</div>
    }

    return (
        <div className="space-y-6">
            {/* Match Header */}
            <div className="relative rounded-xl overflow-hidden bg-gradient-to-br from-gray-900 to-gray-800 text-white p-8">
                <div className="absolute inset-0 bg-[url('/stadium-pattern.png')] opacity-10" />
                <div className="relative z-10 flex flex-col md:flex-row items-center justify-between gap-8">
                    <div className="text-center md:text-left">
                        <div className="flex items-center gap-2 text-gray-400 mb-2">
                            <Calendar className="h-4 w-4" /> {match.date} • {match.type} Match
                        </div>
                        <h1 className="text-3xl font-bold flex items-center gap-4">
                            <span className="text-primary">Royal Strikers</span>
                            <span className="text-xl text-gray-500">vs</span>
                            <span>{match.opponent}</span>
                        </h1>
                        <div className="mt-2 flex items-center gap-2 text-gray-400">
                            <MapPin className="h-4 w-4" /> Wankhede Stadium, Mumbai
                        </div>
                    </div>

                    <div className="flex items-center gap-8">
                        {match.status === 'live' ? (
                            <div className="text-center">
                                <div className="text-4xl font-black text-red-500 animate-pulse">LIVE</div>
                                <div className="text-sm font-semibold">142/3 (16.4)</div>
                            </div>
                        ) : (
                            <div className="px-6 py-2 rounded-full bg-white/10 backdrop-blur-sm border border-white/20 font-semibold uppercase tracking-widest text-sm">
                                {match.status}
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* Navigation Tabs */}
            <div className="flex border-b border-white/10 overflow-x-auto">
                {['info', 'squads', 'scorecard', 'commentary'].map((tab) => (
                    <button
                        key={tab}
                        onClick={() => setActiveTab(tab as any)}
                        className={cn(
                            "px-6 py-3 text-sm font-medium transition-colors relative whitespace-nowrap",
                            activeTab === tab ? "text-primary" : "text-muted-foreground hover:text-white"
                        )}
                    >
                        {tab.charAt(0).toUpperCase() + tab.slice(1)}
                        {activeTab === tab && (
                            <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-primary" />
                        )}
                    </button>
                ))}
            </div>

            {/* Tab Content */}
            <div className="min-h-[300px]">
                {activeTab === 'info' && (
                    <div className="grid gap-6 md:grid-cols-2">
                        <Card className="bg-card/60 backdrop-blur-sm border-white/20">
                            <CardHeader><CardTitle>Match Info</CardTitle></CardHeader>
                            <CardContent className="space-y-4">
                                <div className="flex justify-between py-2 border-b border-white/5">
                                    <span className="text-muted-foreground">Series</span>
                                    <span className="font-medium">Premier League 2024</span>
                                </div>
                                <div className="flex justify-between py-2 border-b border-white/5">
                                    <span className="text-muted-foreground">Umpires</span>
                                    <span className="font-medium">J. Srinath, A. Kumble</span>
                                </div>
                                <div className="flex justify-between py-2 border-b border-white/5">
                                    <span className="text-muted-foreground">Toss</span>
                                    <span className="font-medium">To be decided</span>
                                </div>
                            </CardContent>
                        </Card>
                        <Card className="bg-card/60 backdrop-blur-sm border-white/20">
                            <CardHeader><CardTitle>Venue Guide</CardTitle></CardHeader>
                            <CardContent>
                                <div className="h-40 bg-muted rounded-lg flex items-center justify-center text-muted-foreground mb-4">
                                    <MapPin className="h-8 w-8 mb-2" />
                                    <span>Stadium Map Visualization</span>
                                </div>
                                <p className="text-sm text-muted-foreground">
                                    Batting friendly track with some assistance for spinners in the later half. Average 1st innings score: 180.
                                </p>
                            </CardContent>
                        </Card>
                    </div>
                )}

                {activeTab === 'squads' && (
                    <div className="grid gap-6 md:grid-cols-2">
                        {/* Team 1 */}
                        <Card className="bg-card/60 backdrop-blur-sm border-white/20">
                            <CardHeader className="bg-primary/10 border-b border-white/10">
                                <CardTitle className="text-primary">Royal Strikers</CardTitle>
                            </CardHeader>
                            <CardContent className="p-0">
                                {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map(i => (
                                    <div key={i} className="flex items-center gap-3 p-3 border-b border-white/5 last:border-0 hover:bg-white/5">
                                        <div className="h-8 w-8 rounded-full bg-white/10 flex items-center justify-center text-xs font-bold">
                                            {i}
                                        </div>
                                        <div>
                                            <div className="font-medium">Player Name {i}</div>
                                            <div className="text-xs text-muted-foreground">{i === 1 ? 'Batting All-rounder (C)' : 'Batsman'}</div>
                                        </div>
                                    </div>
                                ))}
                            </CardContent>
                        </Card>
                        {/* Team 2 */}
                        <Card className="bg-card/60 backdrop-blur-sm border-white/20">
                            <CardHeader className="bg-white/5 border-b border-white/10">
                                <CardTitle>{match.opponent}</CardTitle>
                            </CardHeader>
                            <CardContent className="p-0">
                                {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map(i => (
                                    <div key={i} className="flex items-center gap-3 p-3 border-b border-white/5 last:border-0 hover:bg-white/5">
                                        <div className="h-8 w-8 rounded-full bg-white/10 flex items-center justify-center text-xs font-bold">
                                            {i}
                                        </div>
                                        <div>
                                            <div className="font-medium">Opponent Player {i}</div>
                                            <div className="text-xs text-muted-foreground">{i === 1 ? 'Bowler (C)' : 'Bowler'}</div>
                                        </div>
                                    </div>
                                ))}
                            </CardContent>
                        </Card>
                    </div>
                )}

                {activeTab === 'scorecard' && (
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 text-center py-12">
                        <CardContent>
                            <Trophy className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                            <h3 className="text-xl font-semibold mb-2">Scorecard Unavailable</h3>
                            <p className="text-muted-foreground">The match hasn't started yet. Check back later!</p>
                        </CardContent>
                    </Card>
                )}

                {activeTab === 'commentary' && (
                    <div className="grid gap-6 md:grid-cols-3">
                        <div className="md:col-span-2 space-y-4">
                            {[
                                { ball: '16.4', comm: 'FOUR! Beautiful cover drive. Walks into the shot and caresses it through the covers.', score: '4' },
                                { ball: '16.3', comm: 'No run, good length delivery outside off, left alone.', score: '0' },
                                { ball: '16.2', comm: 'SIX! That is huge! Short ball and he pulls it over deep mid-wicket.', score: '6' },
                                { ball: '16.1', comm: '1 run, pushed to long on for a single.', score: '1' }
                            ].map((c, i) => (
                                <div key={i} className="flex gap-4 p-4 rounded-lg bg-white/5 border border-white/10">
                                    <div className="flex-shrink-0">
                                        <div className="h-12 w-12 rounded-full bg-white/10 flex items-center justify-center font-bold text-lg">
                                            {c.ball}
                                        </div>
                                    </div>
                                    <div>
                                        <div className="font-semibold text-lg mb-1 flex items-center gap-2">
                                            {c.score === '4' && <span className="bg-blue-600 px-2 py-0.5 rounded text-xs text-white">FOUR</span>}
                                            {c.score === '6' && <span className="bg-red-600 px-2 py-0.5 rounded text-xs text-white">SIX</span>}
                                        </div>
                                        <p className="text-muted-foreground">{c.comm}</p>
                                    </div>
                                </div>
                            ))}
                        </div>
                        <Card className="bg-indigo-900/40 border-indigo-500/30 backdrop-blur-sm">
                            <CardHeader className="pb-2">
                                <CardTitle className="text-sm font-medium text-indigo-300">AI Analysis (CricBot)</CardTitle>
                            </CardHeader>
                            <CardContent className="space-y-4">
                                <div className="flex items-start gap-3">
                                    <div className="h-8 w-8 rounded-full bg-indigo-500 flex items-center justify-center text-xs">🤖</div>
                                    <div className="bg-white/10 p-3 rounded-tr-xl rounded-br-xl rounded-bl-xl text-sm">
                                        The current run rate is 8.5 but they need 12.0 to win. The batsman is weak against short balls. Expect a bouncer next.
                                    </div>
                                </div>
                                <div className="flex items-start gap-3">
                                    <div className="h-8 w-8 rounded-full bg-indigo-500 flex items-center justify-center text-xs">🤖</div>
                                    <div className="bg-white/10 p-3 rounded-tr-xl rounded-br-xl rounded-bl-xl text-sm">
                                        Opponent bowler has conceded 15 runs in the last over. Momentum shifting!
                                    </div>
                                </div>
                            </CardContent>
                        </Card>
                    </div>
                )}
            </div>
        </div>
    )
}
