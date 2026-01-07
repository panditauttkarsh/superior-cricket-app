'use client'

import { useParams } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { useAppStore } from '@/lib/store'
import { User, Trophy, BarChart, Settings, Plus } from 'lucide-react'
import Image from 'next/image'

export default function TeamDetailsPage() {
    const params = useParams()
    const { teams } = useAppStore()
    const team = teams.find(t => t.id === params.id)

    if (!team) {
        return <div className="p-8 text-center text-muted-foreground">Team not found</div>
    }

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="relative h-48 rounded-xl overflow-hidden bg-gradient-to-r from-primary/80 to-blue-900/80 backdrop-blur-md">
                <div className="absolute inset-0 bg-black/20" />
                <div className="relative z-10 p-8 flex items-end h-full">
                    <div className="flex items-end gap-6">
                        <div className="h-24 w-24 rounded-full border-4 border-white bg-white overflow-hidden shadow-xl">
                            <Image src={team.logo} alt={team.name} width={96} height={96} className="object-cover" />
                        </div>
                        <div className="mb-2 text-white">
                            <h1 className="text-4xl font-bold">{team.name}</h1>
                            <p className="opacity-90 flex items-center gap-2">
                                <span className="font-semibold">{team.city}</span> • {team.players} Players
                            </p>
                        </div>
                    </div>
                </div>
            </div>

            <div className="grid gap-6 md:grid-cols-3">
                {/* Roster Section */}
                <Card className="md:col-span-2 bg-card/60 backdrop-blur-sm border-white/20">
                    <CardHeader className="flex flex-row items-center justify-between">
                        <CardTitle>Squad</CardTitle>
                        <Button size="sm" variant="outline">
                            <Plus className="mr-2 h-4 w-4" /> Add Player
                        </Button>
                    </CardHeader>
                    <CardContent>
                        <div className="space-y-4">
                            {/* Mock Captain (You) */}
                            <div className="flex items-center justify-between p-3 rounded-lg bg-white/5 border border-white/10 hover:border-primary/50 transition-colors">
                                <div className="flex items-center gap-4">
                                    <div className="h-10 w-10 rounded-full bg-primary/20 flex items-center justify-center font-bold text-primary">
                                        You
                                    </div>
                                    <div>
                                        <div className="font-semibold flex items-center gap-2">
                                            You (Captain) <span className="text-[10px] bg-yellow-500/20 text-yellow-500 px-1 rounded border border-yellow-500/50">C</span>
                                        </div>
                                        <div className="text-xs text-muted-foreground">All-Rounder • RHB</div>
                                    </div>
                                </div>
                                <div className="flex gap-2">
                                    <Button variant="ghost" size="icon"><Settings className="h-4 w-4" /></Button>
                                </div>
                            </div>

                            {/* Mock Other Players */}
                            {[1, 2, 3, 4, 5].map(i => (
                                <div key={i} className="flex items-center justify-between p-3 rounded-lg hover:bg-white/5 transition-colors border border-transparent hover:border-white/10">
                                    <div className="flex items-center gap-4">
                                        <div className="h-10 w-10 rounded-full bg-muted flex items-center justify-center">
                                            <User className="h-5 w-5 text-muted-foreground" />
                                        </div>
                                        <div>
                                            <div className="font-semibold">Player {i}</div>
                                            <div className="text-xs text-muted-foreground">Batsman</div>
                                        </div>
                                    </div>
                                    <div className="text-sm font-mono text-muted-foreground">
                                        Avg: 32.5
                                    </div>
                                </div>
                            ))}
                        </div>
                    </CardContent>
                </Card>

                {/* Stats Section */}
                <div className="space-y-6">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20">
                        <CardHeader>
                            <CardTitle>Team Stats</CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            <div className="flex justify-between items-center">
                                <span className="text-muted-foreground">Matches</span>
                                <span className="font-bold">12</span>
                            </div>
                            <div className="flex justify-between items-center">
                                <span className="text-muted-foreground">Won</span>
                                <span className="font-bold text-green-500">8</span>
                            </div>
                            <div className="flex justify-between items-center">
                                <span className="text-muted-foreground">Lost</span>
                                <span className="font-bold text-red-500">4</span>
                            </div>
                            <div className="flex justify-between items-center">
                                <span className="text-muted-foreground">Win Rate</span>
                                <span className="font-bold">66%</span>
                            </div>
                        </CardContent>
                    </Card>

                    <Card className="bg-gradient-to-br from-primary to-blue-600 text-white border-none">
                        <CardContent className="p-6 text-center">
                            <Trophy className="h-12 w-12 mx-auto mb-2 opacity-80" />
                            <h3 className="font-bold text-lg">Pro Membership</h3>
                            <p className="text-sm opacity-90 mb-4">Unlock advanced analytics for your team.</p>
                            <Button variant="secondary" className="w-full">Upgrade Now</Button>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    )
}
