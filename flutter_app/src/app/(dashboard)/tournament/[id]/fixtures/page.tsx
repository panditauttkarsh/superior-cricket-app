'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
    Calendar, Clock, MapPin, Trophy, ArrowLeft,
    Plus, CheckCircle, XCircle
} from 'lucide-react'
import { getTournamentFixtures, createFixture } from '@/lib/services/tournamentService'
import { Fixture } from '@/types/tournament'
import Link from 'next/link'

export default function FixturesPage() {
    const params = useParams()
    const router = useRouter()
    const tournamentId = params.id as string
    
    const [fixtures, setFixtures] = useState<Fixture[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [filter, setFilter] = useState<'all' | 'scheduled' | 'live' | 'completed'>('all')

    useEffect(() => {
        if (tournamentId) {
            loadFixtures()
        }
    }, [tournamentId])

    const loadFixtures = async () => {
        setIsLoading(true)
        try {
            const data = await getTournamentFixtures(tournamentId)
            setFixtures(data)
        } catch (error) {
            console.error('Failed to load fixtures:', error)
        } finally {
            setIsLoading(false)
        }
    }

    const filteredFixtures = fixtures.filter(fixture => {
        if (filter === 'all') return true
        return fixture.status === filter
    })

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'scheduled':
                return <Badge className="bg-blue-500/20 text-blue-400 border-blue-500/30">Scheduled</Badge>
            case 'live':
                return <Badge className="bg-red-500/20 text-red-400 border-red-500/30 animate-pulse">Live</Badge>
            case 'completed':
                return <Badge className="bg-green-500/20 text-green-400 border-green-500/30">Completed</Badge>
            case 'cancelled':
                return <Badge className="bg-gray-500/20 text-gray-400 border-gray-500/30">Cancelled</Badge>
            case 'postponed':
                return <Badge className="bg-yellow-500/20 text-yellow-400 border-yellow-500/30">Postponed</Badge>
            default:
                return <Badge variant="outline">{status}</Badge>
        }
    }

    if (isLoading) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <p className="text-muted-foreground">Loading fixtures...</p>
            </div>
        )
    }

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <Button variant="ghost" onClick={() => router.back()} className="mb-2">
                        <ArrowLeft className="mr-2 h-4 w-4" />
                        Back
                    </Button>
                    <h1 className="text-3xl font-bold tracking-tight text-foreground/90">
                        Tournament Fixtures
                    </h1>
                </div>
                <Button>
                    <Plus className="mr-2 h-4 w-4" />
                    Add Fixture
                </Button>
            </div>

            {/* Filters */}
            <div className="flex gap-2">
                {(['all', 'scheduled', 'live', 'completed'] as const).map((f) => (
                    <Button
                        key={f}
                        variant={filter === f ? 'default' : 'outline'}
                        size="sm"
                        onClick={() => setFilter(f)}
                    >
                        {f.charAt(0).toUpperCase() + f.slice(1)}
                    </Button>
                ))}
            </div>

            {/* Fixtures List */}
            {filteredFixtures.length === 0 ? (
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-8 text-center">
                        <Calendar className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                        <p className="text-muted-foreground mb-4">No fixtures found.</p>
                        <Button>
                            <Plus className="mr-2 h-4 w-4" />
                            Create First Fixture
                        </Button>
                    </CardContent>
                </Card>
            ) : (
                <div className="space-y-4">
                    {filteredFixtures.map((fixture) => (
                        <Card
                            key={fixture.id}
                            className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl hover:shadow-2xl transition-all duration-300"
                        >
                            <CardHeader>
                                <div className="flex items-center justify-between">
                                    <div>
                                        <CardTitle className="flex items-center gap-2">
                                            <Trophy className="h-5 w-5" />
                                            Match #{fixture.matchNumber} - {fixture.round.charAt(0).toUpperCase() + fixture.round.slice(1)}
                                        </CardTitle>
                                        <div className="flex items-center gap-2 mt-2">
                                            {getStatusBadge(fixture.status)}
                                            <Badge variant="outline" className="capitalize">
                                                {fixture.round}
                                            </Badge>
                                        </div>
                                    </div>
                                </div>
                            </CardHeader>
                            <CardContent>
                                <div className="space-y-4">
                                    {/* Teams */}
                                    <div className="flex items-center justify-between">
                                        <div className="flex-1 text-center">
                                            <p className="font-semibold text-lg">{fixture.team1Name}</p>
                                            {fixture.result && (
                                                <p className="text-sm text-muted-foreground mt-1">
                                                    {fixture.result.team1Score} ({fixture.result.team1Overs} ov)
                                                </p>
                                            )}
                                        </div>
                                        <div className="px-4">
                                            <span className="text-muted-foreground">vs</span>
                                        </div>
                                        <div className="flex-1 text-center">
                                            <p className="font-semibold text-lg">{fixture.team2Name}</p>
                                            {fixture.result && (
                                                <p className="text-sm text-muted-foreground mt-1">
                                                    {fixture.result.team2Score} ({fixture.result.team2Overs} ov)
                                                </p>
                                            )}
                                        </div>
                                    </div>

                                    {/* Result */}
                                    {fixture.result && (
                                        <div className="p-4 bg-primary/10 rounded-lg border border-primary/20">
                                            <div className="flex items-center justify-between">
                                                <div>
                                                    <p className="text-sm text-muted-foreground">Winner</p>
                                                    <p className="font-bold text-primary">{fixture.result.winnerName}</p>
                                                </div>
                                                {fixture.result.manOfTheMatch && (
                                                    <div className="text-right">
                                                        <p className="text-sm text-muted-foreground">Man of the Match</p>
                                                        <p className="font-semibold">{fixture.result.manOfTheMatch}</p>
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                    )}

                                    {/* Match Details */}
                                    <div className="grid gap-4 md:grid-cols-3 pt-4 border-t border-white/10">
                                        <div className="flex items-center gap-2 text-sm text-muted-foreground">
                                            <Calendar className="h-4 w-4" />
                                            <span>{new Date(fixture.scheduledDate).toLocaleDateString()}</span>
                                        </div>
                                        <div className="flex items-center gap-2 text-sm text-muted-foreground">
                                            <Clock className="h-4 w-4" />
                                            <span>{fixture.scheduledTime}</span>
                                        </div>
                                        <div className="flex items-center gap-2 text-sm text-muted-foreground">
                                            <MapPin className="h-4 w-4" />
                                            <span className="truncate">{fixture.venue}</span>
                                        </div>
                                    </div>

                                    {/* Actions */}
                                    <div className="flex gap-2 pt-2">
                                        <Button variant="outline" size="sm" className="flex-1" asChild>
                                            <Link href={`/matches/${fixture.id}`}>
                                                View Match
                                            </Link>
                                        </Button>
                                        {fixture.status === 'scheduled' && (
                                            <Button variant="outline" size="sm" className="flex-1">
                                                Edit Fixture
                                            </Button>
                                        )}
                                    </div>
                                </div>
                            </CardContent>
                        </Card>
                    ))}
                </div>
            )}
        </div>
    )
}

