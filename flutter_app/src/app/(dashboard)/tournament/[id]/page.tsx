'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
    Trophy, Calendar, Users, MapPin, Award,
    BarChart3, Clock, ArrowLeft, TrendingUp
} from 'lucide-react'
import { getTournament, getTournamentStats } from '@/lib/services/tournamentService'
import { Tournament, TournamentStats } from '@/types/tournament'
import Link from 'next/link'

export default function TournamentDetailsPage() {
    const params = useParams()
    const router = useRouter()
    const tournamentId = params.id as string
    
    const [tournament, setTournament] = useState<Tournament | null>(null)
    const [stats, setStats] = useState<TournamentStats | null>(null)
    const [isLoading, setIsLoading] = useState(true)

    useEffect(() => {
        if (tournamentId) {
            loadTournament()
        }
    }, [tournamentId])

    const loadTournament = async () => {
        setIsLoading(true)
        try {
            const [tournamentData, statsData] = await Promise.all([
                getTournament(tournamentId),
                getTournamentStats(tournamentId)
            ])
            setTournament(tournamentData)
            setStats(statsData)
        } catch (error) {
            console.error('Failed to load tournament:', error)
        } finally {
            setIsLoading(false)
        }
    }

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'upcoming':
                return <Badge className="bg-blue-500/20 text-blue-400 border-blue-500/30">Upcoming</Badge>
            case 'registration':
                return <Badge className="bg-green-500/20 text-green-400 border-green-500/30">Registration Open</Badge>
            case 'ongoing':
                return <Badge className="bg-red-500/20 text-red-400 border-red-500/30 animate-pulse">Ongoing</Badge>
            case 'completed':
                return <Badge className="bg-gray-500/20 text-gray-400 border-gray-500/30">Completed</Badge>
            default:
                return <Badge variant="outline">{status}</Badge>
        }
    }

    if (isLoading) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <p className="text-muted-foreground">Loading tournament...</p>
            </div>
        )
    }

    if (!tournament) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-8 text-center">
                        <p className="text-muted-foreground mb-4">Tournament not found.</p>
                        <Button onClick={() => router.back()}>Go Back</Button>
                    </CardContent>
                </Card>
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
                    <div className="flex items-center gap-3">
                        <Trophy className="h-8 w-8 text-primary" />
                        <div>
                            <h1 className="text-3xl font-bold tracking-tight text-foreground/90">
                                {tournament.name}
                            </h1>
                            <div className="flex items-center gap-2 mt-1">
                                {getStatusBadge(tournament.status)}
                                <Badge variant="outline">{tournament.format}</Badge>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Quick Stats */}
            {stats && (
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                    <Card className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardContent className="p-6">
                            <div className="flex items-center justify-between">
                                <div>
                                    <p className="text-sm text-muted-foreground mb-1">Total Matches</p>
                                    <p className="text-3xl font-bold">{stats.totalMatches}</p>
                                </div>
                                <BarChart3 className="h-8 w-8 text-blue-400" />
                            </div>
                        </CardContent>
                    </Card>
                    <Card className="bg-gradient-to-br from-green-500/20 to-green-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardContent className="p-6">
                            <div className="flex items-center justify-between">
                                <div>
                                    <p className="text-sm text-muted-foreground mb-1">Completed</p>
                                    <p className="text-3xl font-bold">{stats.completedMatches}</p>
                                </div>
                                <Trophy className="h-8 w-8 text-green-400" />
                            </div>
                        </CardContent>
                    </Card>
                    <Card className="bg-gradient-to-br from-purple-500/20 to-purple-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardContent className="p-6">
                            <div className="flex items-center justify-between">
                                <div>
                                    <p className="text-sm text-muted-foreground mb-1">Upcoming</p>
                                    <p className="text-3xl font-bold">{stats.upcomingMatches}</p>
                                </div>
                                <Clock className="h-8 w-8 text-purple-400" />
                            </div>
                        </CardContent>
                    </Card>
                    <Card className="bg-gradient-to-br from-orange-500/20 to-orange-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardContent className="p-6">
                            <div className="flex items-center justify-between">
                                <div>
                                    <p className="text-sm text-muted-foreground mb-1">Total Runs</p>
                                    <p className="text-3xl font-bold">{stats.totalRuns}</p>
                                </div>
                                <TrendingUp className="h-8 w-8 text-orange-400" />
                            </div>
                        </CardContent>
                    </Card>
                </div>
            )}

            {/* Tournament Info Tabs */}
            <Tabs defaultValue="overview" className="space-y-6">
                <TabsList>
                    <TabsTrigger value="overview">Overview</TabsTrigger>
                    <TabsTrigger value="teams">Teams</TabsTrigger>
                    <TabsTrigger value="fixtures">Fixtures</TabsTrigger>
                    <TabsTrigger value="points">Points Table</TabsTrigger>
                    <TabsTrigger value="leaderboards">Leaderboards</TabsTrigger>
                </TabsList>

                <TabsContent value="overview" className="space-y-4">
                    <div className="grid gap-6 md:grid-cols-2">
                        <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                            <CardHeader>
                                <CardTitle>Tournament Information</CardTitle>
                            </CardHeader>
                            <CardContent className="space-y-4">
                                <div className="space-y-3">
                                    <div className="flex items-center gap-2">
                                        <Calendar className="h-4 w-4 text-muted-foreground" />
                                        <div>
                                            <p className="text-sm text-muted-foreground">Dates</p>
                                            <p className="font-medium">
                                                {new Date(tournament.startDate).toLocaleDateString()} - {new Date(tournament.endDate).toLocaleDateString()}
                                            </p>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-2">
                                        <MapPin className="h-4 w-4 text-muted-foreground" />
                                        <div>
                                            <p className="text-sm text-muted-foreground">Location</p>
                                            <p className="font-medium">{tournament.location}</p>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-2">
                                        <Users className="h-4 w-4 text-muted-foreground" />
                                        <div>
                                            <p className="text-sm text-muted-foreground">Teams</p>
                                            <p className="font-medium">
                                                {tournament.currentTeams}/{tournament.maxTeams}
                                            </p>
                                        </div>
                                    </div>
                                    {tournament.prizePool && (
                                        <div className="flex items-center gap-2">
                                            <Award className="h-4 w-4 text-muted-foreground" />
                                            <div>
                                                <p className="text-sm text-muted-foreground">Prize Pool</p>
                                                <p className="font-medium">{tournament.prizePool}</p>
                                            </div>
                                        </div>
                                    )}
                                </div>
                            </CardContent>
                        </Card>

                        <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                            <CardHeader>
                                <CardTitle>Description</CardTitle>
                            </CardHeader>
                            <CardContent>
                                <p className="text-muted-foreground">{tournament.description}</p>
                                {tournament.rules && tournament.rules.length > 0 && (
                                    <div className="mt-4">
                                        <h4 className="text-sm font-semibold mb-2">Rules</h4>
                                        <ul className="space-y-1">
                                            {tournament.rules.map((rule, i) => (
                                                <li key={i} className="text-sm text-muted-foreground flex items-start gap-2">
                                                    <span>•</span>
                                                    <span>{rule}</span>
                                                </li>
                                            ))}
                                        </ul>
                                    </div>
                                )}
                            </CardContent>
                        </Card>
                    </div>

                    {/* Tournament Stats Highlights */}
                    {stats && (
                        <div className="grid gap-6 md:grid-cols-2">
                            <Card className="bg-gradient-to-br from-green-900/40 to-emerald-900/40 border-green-500/30 backdrop-blur-sm">
                                <CardHeader>
                                    <CardTitle className="text-green-300">Highest Score</CardTitle>
                                </CardHeader>
                                <CardContent>
                                    <div className="space-y-2">
                                        <p className="text-2xl font-bold text-green-300">{stats.highestScore.score}</p>
                                        <p className="text-sm text-green-200">{stats.highestScore.teamName}</p>
                                    </div>
                                </CardContent>
                            </Card>
                            <Card className="bg-gradient-to-br from-purple-900/40 to-pink-900/40 border-purple-500/30 backdrop-blur-sm">
                                <CardHeader>
                                    <CardTitle className="text-purple-300">Best Bowling</CardTitle>
                                </CardHeader>
                                <CardContent>
                                    <div className="space-y-2">
                                        <p className="text-2xl font-bold text-purple-300">{stats.bestBowling.figures}</p>
                                        <p className="text-sm text-purple-200">{stats.bestBowling.playerName}</p>
                                    </div>
                                </CardContent>
                            </Card>
                        </div>
                    )}
                </TabsContent>

                <TabsContent value="teams" className="space-y-4">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardHeader>
                            <CardTitle>Registered Teams</CardTitle>
                        </CardHeader>
                        <CardContent>
                            {tournament.teams.length === 0 ? (
                                <p className="text-muted-foreground text-center py-8">No teams registered yet.</p>
                            ) : (
                                <div className="grid gap-4 md:grid-cols-2">
                                    {tournament.teams.map((team) => (
                                        <div
                                            key={team.teamId}
                                            className="p-4 rounded-lg border border-white/10 bg-card/40 flex items-center justify-between"
                                        >
                                            <div className="flex items-center gap-3">
                                                <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center">
                                                    <Users className="h-5 w-5 text-primary" />
                                                </div>
                                                <div>
                                                    <p className="font-semibold">{team.teamName}</p>
                                                    <p className="text-xs text-muted-foreground">
                                                        Registered: {new Date(team.registeredAt).toLocaleDateString()}
                                                    </p>
                                                </div>
                                            </div>
                                            <Badge variant="outline" className="capitalize">
                                                {team.status}
                                            </Badge>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>

                <TabsContent value="fixtures">
                    <div className="text-center py-8">
                        <Button asChild>
                            <Link href={`/tournament/${tournamentId}/fixtures`}>
                                View All Fixtures
                            </Link>
                        </Button>
                    </div>
                </TabsContent>

                <TabsContent value="points">
                    <div className="text-center py-8">
                        <Button asChild>
                            <Link href={`/tournament/${tournamentId}/points`}>
                                View Points Table
                            </Link>
                        </Button>
                    </div>
                </TabsContent>

                <TabsContent value="leaderboards">
                    <div className="text-center py-8">
                        <Button asChild>
                            <Link href={`/tournament/${tournamentId}/leaderboards`}>
                                View Leaderboards
                            </Link>
                        </Button>
                    </div>
                </TabsContent>
            </Tabs>
        </div>
    )
}

