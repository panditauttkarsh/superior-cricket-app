'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Badge } from '@/components/ui/badge'
import { 
    Users, Trophy, TrendingUp, Target,
    Plus, UserPlus, UserMinus, BarChart3,
    Activity, Award, AlertCircle
} from 'lucide-react'
import { useAppStore } from '@/lib/store'
import { getTeamsByCoach, getTeamStats } from '@/lib/services/coachService'
import { Team, TeamStats } from '@/types/coach'
import Link from 'next/link'

export default function CoachDashboardPage() {
    const { user } = useAppStore()
    const [teams, setTeams] = useState<Team[]>([])
    const [teamStats, setTeamStats] = useState<Record<string, TeamStats>>({})
    const [isLoading, setIsLoading] = useState(true)

    useEffect(() => {
        if (user) {
            loadTeams()
        }
    }, [user])

    const loadTeams = async () => {
        if (!user) return
        
        setIsLoading(true)
        try {
            // In production, use actual coach ID from user
            const coachId = user.id
            const data = await getTeamsByCoach(coachId)
            setTeams(data)
            
            // Load stats for each team
            const stats: Record<string, TeamStats> = {}
            for (const team of data) {
                const stat = await getTeamStats(team.id)
                if (stat) {
                    stats[team.id] = stat
                }
            }
            setTeamStats(stats)
        } catch (error) {
            console.error('Failed to load teams:', error)
        } finally {
            setIsLoading(false)
        }
    }

    if (isLoading) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <p className="text-muted-foreground">Loading coach dashboard...</p>
            </div>
        )
    }

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight text-foreground/90">
                        Coach Dashboard
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        Manage your teams and analyze performance
                    </p>
                </div>
                <Button className="shadow-lg shadow-primary/20">
                    <Plus className="mr-2 h-4 w-4" />
                    New Team
                </Button>
            </div>

            {/* Quick Stats */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <Card className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-sm text-muted-foreground mb-1">Total Teams</p>
                                <p className="text-3xl font-bold">{teams.length}</p>
                            </div>
                            <Users className="h-8 w-8 text-blue-400" />
                        </div>
                    </CardContent>
                </Card>

                <Card className="bg-gradient-to-br from-green-500/20 to-green-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-sm text-muted-foreground mb-1">Total Players</p>
                                <p className="text-3xl font-bold">
                                    {teams.reduce((sum, team) => sum + team.players.length, 0)}
                                </p>
                            </div>
                            <UserPlus className="h-8 w-8 text-green-400" />
                        </div>
                    </CardContent>
                </Card>

                <Card className="bg-gradient-to-br from-purple-500/20 to-purple-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-sm text-muted-foreground mb-1">Total Matches</p>
                                <p className="text-3xl font-bold">
                                    {Object.values(teamStats).reduce((sum, stat) => sum + stat.totalMatches, 0)}
                                </p>
                            </div>
                            <Trophy className="h-8 w-8 text-purple-400" />
                        </div>
                    </CardContent>
                </Card>

                <Card className="bg-gradient-to-br from-orange-500/20 to-orange-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-sm text-muted-foreground mb-1">Win Rate</p>
                                <p className="text-3xl font-bold">
                                    {Object.values(teamStats).length > 0
                                        ? Math.round(
                                              Object.values(teamStats).reduce(
                                                  (sum, stat) => sum + stat.winPercentage,
                                                  0
                                              ) / Object.values(teamStats).length
                                          )
                                        : 0}
                                    %
                                </p>
                            </div>
                            <TrendingUp className="h-8 w-8 text-orange-400" />
                        </div>
                    </CardContent>
                </Card>
            </div>

            {/* Teams List */}
            <Tabs defaultValue="teams" className="space-y-6">
                <TabsList>
                    <TabsTrigger value="teams" className="flex items-center gap-2">
                        <Users className="h-4 w-4" />
                        My Teams
                    </TabsTrigger>
                    <TabsTrigger value="analysis" className="flex items-center gap-2">
                        <BarChart3 className="h-4 w-4" />
                        Analysis
                    </TabsTrigger>
                </TabsList>

                <TabsContent value="teams" className="space-y-4">
                    {teams.length === 0 ? (
                        <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                            <CardContent className="p-8 text-center">
                                <Users className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                                <p className="text-muted-foreground mb-4">No teams found.</p>
                                <Button>
                                    <Plus className="mr-2 h-4 w-4" />
                                    Create Your First Team
                                </Button>
                            </CardContent>
                        </Card>
                    ) : (
                        <div className="grid gap-6 md:grid-cols-2">
                            {teams.map((team) => {
                                const stats = teamStats[team.id]
                                const activePlayers = team.players.filter(p => p.status === 'active').length
                                const injuredPlayers = team.players.filter(p => p.status === 'injured').length

                                return (
                                    <Card
                                        key={team.id}
                                        className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl hover:shadow-2xl transition-all duration-300"
                                    >
                                        <CardHeader>
                                            <div className="flex items-center justify-between">
                                                <CardTitle className="flex items-center gap-2">
                                                    <Users className="h-5 w-5" />
                                                    {team.name}
                                                </CardTitle>
                                                <Button variant="outline" size="sm" asChild>
                                                    <Link href={`/coach/teams/${team.id}`}>
                                                        Manage
                                                    </Link>
                                                </Button>
                                            </div>
                                            <p className="text-sm text-muted-foreground">
                                                {team.city}, {team.state}
                                            </p>
                                        </CardHeader>
                                        <CardContent className="space-y-4">
                                            {/* Team Stats */}
                                            {stats && (
                                                <div className="grid grid-cols-3 gap-4">
                                                    <div className="text-center">
                                                        <p className="text-2xl font-bold">{stats.wins}</p>
                                                        <p className="text-xs text-muted-foreground">Wins</p>
                                                    </div>
                                                    <div className="text-center">
                                                        <p className="text-2xl font-bold">{stats.losses}</p>
                                                        <p className="text-xs text-muted-foreground">Losses</p>
                                                    </div>
                                                    <div className="text-center">
                                                        <p className="text-2xl font-bold">{stats.winPercentage}%</p>
                                                        <p className="text-xs text-muted-foreground">Win Rate</p>
                                                    </div>
                                                </div>
                                            )}

                                            {/* Players Info */}
                                            <div className="space-y-2">
                                                <div className="flex items-center justify-between text-sm">
                                                    <span className="text-muted-foreground">Total Players</span>
                                                    <span className="font-semibold">{team.players.length}</span>
                                                </div>
                                                <div className="flex items-center justify-between text-sm">
                                                    <span className="text-muted-foreground">Active</span>
                                                    <Badge variant="outline" className="bg-green-500/20 text-green-400 border-green-500/30">
                                                        {activePlayers}
                                                    </Badge>
                                                </div>
                                                {injuredPlayers > 0 && (
                                                    <div className="flex items-center justify-between text-sm">
                                                        <span className="text-muted-foreground">Injured</span>
                                                        <Badge variant="outline" className="bg-red-500/20 text-red-400 border-red-500/30">
                                                            {injuredPlayers}
                                                        </Badge>
                                                    </div>
                                                )}
                                            </div>

                                            {/* Quick Actions */}
                                            <div className="flex gap-2 pt-2 border-t border-white/10">
                                                <Button variant="outline" size="sm" className="flex-1" asChild>
                                                    <Link href={`/coach/teams/${team.id}/players`}>
                                                        <UserPlus className="mr-2 h-4 w-4" />
                                                        Players
                                                    </Link>
                                                </Button>
                                                <Button variant="outline" size="sm" className="flex-1" asChild>
                                                    <Link href={`/coach/teams/${team.id}/analysis`}>
                                                        <BarChart3 className="mr-2 h-4 w-4" />
                                                        Analysis
                                                    </Link>
                                                </Button>
                                            </div>
                                        </CardContent>
                                    </Card>
                                )
                            })}
                        </div>
                    )}
                </TabsContent>

                <TabsContent value="analysis" className="space-y-4">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2">
                                <BarChart3 className="h-5 w-5" />
                                Performance Overview
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-muted-foreground">
                                Detailed analysis and insights coming soon...
                            </p>
                        </CardContent>
                    </Card>
                </TabsContent>
            </Tabs>
        </div>
    )
}

