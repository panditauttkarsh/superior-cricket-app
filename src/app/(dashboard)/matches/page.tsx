'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Modal } from '@/components/ui/modal'
import { Plus, Calendar, Trophy, MapPin, Play, Loader2 } from 'lucide-react'
import Image from 'next/image'
import { useAppStore } from '@/lib/store'
import Link from 'next/link'
import { cn } from '@/lib/utils'

export default function MatchesPage() {
    const matches = useAppStore((state) => state.matches)
    const addMatch = useAppStore((state) => state.addMatch)
    const [isModalOpen, setIsModalOpen] = useState(false)
    const [isLoading, setIsLoading] = useState(false)
    const [matchOpponent, setMatchOpponent] = useState('')
    const [matchDate, setMatchDate] = useState('')
    const [matchType, setMatchType] = useState<'T20' | 'ODI' | 'Test'>('T20')

    const liveMatches = matches.filter(m => m.status === 'live')
    const upcomingMatches = matches.filter(m => m.status === 'upcoming')
    const completedMatches = matches.filter(m => m.status === 'completed')

    const handleCreateMatch = async () => {
        if (!matchOpponent || !matchDate) {
            return
        }

        setIsLoading(true)
        // Simulate network delay
        await new Promise(resolve => setTimeout(resolve, 800))

        addMatch({
            opponent: matchOpponent,
            date: matchDate,
            type: matchType
        })

        setIsLoading(false)
        setIsModalOpen(false)
        setMatchOpponent('')
        setMatchDate('')
        setMatchType('T20')
    }

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold tracking-tight text-foreground/90">Matches</h1>
                <Button 
                    onClick={() => setIsModalOpen(true)}
                    className="shadow-lg shadow-primary/20"
                >
                        <Plus className="mr-2 h-4 w-4" />
                        New Match
                    </Button>
            </div>

            {/* New Match Modal */}
            <Modal
                isOpen={isModalOpen}
                onClose={() => setIsModalOpen(false)}
                title="Schedule New Match"
                description="Create a new cricket match fixture."
            >
                <div className="space-y-4">
                    <div className="space-y-2">
                        <Label>Opponent Team</Label>
                        <Input
                            placeholder="Enter opponent team name"
                            value={matchOpponent}
                            onChange={(e) => setMatchOpponent(e.target.value)}
                            disabled={isLoading}
                        />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <Label>Match Date</Label>
                            <Input
                                type="date"
                                value={matchDate}
                                onChange={(e) => setMatchDate(e.target.value)}
                                disabled={isLoading}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Match Type</Label>
                            <select
                                value={matchType}
                                onChange={(e) => setMatchType(e.target.value as 'T20' | 'ODI' | 'Test')}
                                disabled={isLoading}
                                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                            >
                                <option value="T20">T20</option>
                                <option value="ODI">ODI</option>
                                <option value="Test">Test</option>
                            </select>
                        </div>
                    </div>
                    <div className="flex gap-3 pt-4">
                        <Button
                            variant="outline"
                            onClick={() => setIsModalOpen(false)}
                            className="flex-1"
                            disabled={isLoading}
                        >
                            Cancel
                        </Button>
                        <Button
                            onClick={handleCreateMatch}
                            className="flex-1"
                            disabled={isLoading || !matchOpponent || !matchDate}
                        >
                            {isLoading ? (
                                <>
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    Creating...
                                </>
                            ) : (
                                'Create Match'
                            )}
                        </Button>
                    </div>
                </div>
            </Modal>

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
