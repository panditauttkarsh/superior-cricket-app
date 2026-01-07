'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { 
    User, Search, TrendingUp, TrendingDown,
    Target, AlertCircle, CheckCircle, BarChart3
} from 'lucide-react'
import { getPlayerPerformance } from '@/lib/services/coachService'
import { PlayerPerformance } from '@/types/coach'
import { useAppStore } from '@/lib/store'
import { getTeamsByCoach } from '@/lib/services/coachService'
import { Team } from '@/types/coach'

export default function PlayerMonitoringPage() {
    const { user } = useAppStore()
    const [teams, setTeams] = useState<Team[]>([])
    const [selectedTeam, setSelectedTeam] = useState<string>('')
    const [searchTerm, setSearchTerm] = useState('')
    const [playerPerformance, setPlayerPerformance] = useState<Record<string, PlayerPerformance>>({})
    const [isLoading, setIsLoading] = useState(true)

    useEffect(() => {
        if (user) {
            loadTeams()
        }
    }, [user])

    useEffect(() => {
        if (selectedTeam) {
            loadPlayerPerformance()
        }
    }, [selectedTeam])

    const loadTeams = async () => {
        if (!user) return
        
        setIsLoading(true)
        try {
            const coachId = user.id
            const data = await getTeamsByCoach(coachId)
            setTeams(data)
            if (data.length > 0) {
                setSelectedTeam(data[0].id)
            }
        } catch (error) {
            console.error('Failed to load teams:', error)
        } finally {
            setIsLoading(false)
        }
    }

    const loadPlayerPerformance = async () => {
        if (!selectedTeam) return
        
        const team = teams.find(t => t.id === selectedTeam)
        if (!team) return

        const performance: Record<string, PlayerPerformance> = {}
        
        for (const player of team.players) {
            try {
                const perf = await getPlayerPerformance(player.playerId)
                if (perf) {
                    performance[player.playerId] = perf
                }
            } catch (error) {
                console.error(`Failed to load performance for ${player.playerId}:`, error)
            }
        }
        
        setPlayerPerformance(performance)
    }

    const filteredPlayers = selectedTeam
        ? teams
              .find(t => t.id === selectedTeam)
              ?.players.filter(p =>
                  p.playerName.toLowerCase().includes(searchTerm.toLowerCase())
              ) || []
        : []

    if (isLoading) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <p className="text-muted-foreground">Loading player monitoring...</p>
            </div>
        )
    }

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight text-foreground/90">
                        Player Monitoring
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        Track and analyze player performance
                    </p>
                </div>
            </div>

            {/* Filters */}
            <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                <CardContent className="p-4">
                    <div className="flex gap-4">
                        <div className="flex-1">
                            <div className="relative">
                                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                                <Input
                                    placeholder="Search players..."
                                    value={searchTerm}
                                    onChange={(e) => setSearchTerm(e.target.value)}
                                    className="pl-10"
                                />
                            </div>
                        </div>
                        <select
                            value={selectedTeam}
                            onChange={(e) => setSelectedTeam(e.target.value)}
                            className="px-4 py-2 rounded-md bg-background border border-white/20 focus:outline-none focus:ring-2 focus:ring-primary"
                        >
                            {teams.map((team) => (
                                <option key={team.id} value={team.id}>
                                    {team.name}
                                </option>
                            ))}
                        </select>
                    </div>
                </CardContent>
            </Card>

            {/* Players List */}
            {filteredPlayers.length === 0 ? (
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-8 text-center">
                        <User className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                        <p className="text-muted-foreground">No players found.</p>
                    </CardContent>
                </Card>
            ) : (
                <div className="grid gap-6 md:grid-cols-2">
                    {filteredPlayers.map((player) => {
                        const performance = playerPerformance[player.playerId]

                        return (
                            <Card
                                key={player.playerId}
                                className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl hover:shadow-2xl transition-all duration-300"
                            >
                                <CardHeader>
                                    <div className="flex items-center justify-between">
                                        <CardTitle className="flex items-center gap-2">
                                            <User className="h-5 w-5" />
                                            {player.playerName}
                                        </CardTitle>
                                        <Badge variant="outline" className="capitalize">
                                            {player.role}
                                        </Badge>
                                    </div>
                                </CardHeader>
                                <CardContent className="space-y-4">
                                    {performance ? (
                                        <>
                                            {/* Recent Form */}
                                            <div>
                                                <h4 className="text-sm font-semibold mb-2 flex items-center gap-2">
                                                    <BarChart3 className="h-4 w-4" />
                                                    Recent Form
                                                </h4>
                                                <div className="grid grid-cols-3 gap-2 text-xs">
                                                    <div className="text-center p-2 bg-card/40 rounded">
                                                        <p className="font-bold">Runs</p>
                                                        <p className="text-muted-foreground">
                                                            {performance.recentForm.runs.slice(-3).join(', ')}
                                                        </p>
                                                    </div>
                                                    <div className="text-center p-2 bg-card/40 rounded">
                                                        <p className="font-bold">Wickets</p>
                                                        <p className="text-muted-foreground">
                                                            {performance.recentForm.wickets.slice(-3).join(', ')}
                                                        </p>
                                                    </div>
                                                    <div className="text-center p-2 bg-card/40 rounded">
                                                        <p className="font-bold">Catches</p>
                                                        <p className="text-muted-foreground">
                                                            {performance.recentForm.catches.slice(-3).join(', ')}
                                                        </p>
                                                    </div>
                                                </div>
                                            </div>

                                            {/* Strengths */}
                                            {performance.strengths.length > 0 && (
                                                <div>
                                                    <h4 className="text-sm font-semibold mb-2 flex items-center gap-2 text-green-400">
                                                        <CheckCircle className="h-4 w-4" />
                                                        Strengths
                                                    </h4>
                                                    <ul className="space-y-1">
                                                        {performance.strengths.map((strength, i) => (
                                                            <li key={i} className="text-sm text-muted-foreground flex items-start gap-2">
                                                                <span className="text-green-400 mt-1">•</span>
                                                                <span>{strength}</span>
                                                            </li>
                                                        ))}
                                                    </ul>
                                                </div>
                                            )}

                                            {/* Weaknesses */}
                                            {performance.weaknesses.length > 0 && (
                                                <div>
                                                    <h4 className="text-sm font-semibold mb-2 flex items-center gap-2 text-red-400">
                                                        <AlertCircle className="h-4 w-4" />
                                                        Areas for Improvement
                                                    </h4>
                                                    <ul className="space-y-1">
                                                        {performance.weaknesses.map((weakness, i) => (
                                                            <li key={i} className="text-sm text-muted-foreground flex items-start gap-2">
                                                                <span className="text-red-400 mt-1">•</span>
                                                                <span>{weakness}</span>
                                                            </li>
                                                        ))}
                                                    </ul>
                                                </div>
                                            )}

                                            {/* Recommendations */}
                                            {performance.recommendations.length > 0 && (
                                                <div>
                                                    <h4 className="text-sm font-semibold mb-2 flex items-center gap-2 text-blue-400">
                                                        <Target className="h-4 w-4" />
                                                        Recommendations
                                                    </h4>
                                                    <ul className="space-y-1">
                                                        {performance.recommendations.map((rec, i) => (
                                                            <li key={i} className="text-sm text-muted-foreground flex items-start gap-2">
                                                                <span className="text-blue-400 mt-1">•</span>
                                                                <span>{rec}</span>
                                                            </li>
                                                        ))}
                                                    </ul>
                                                </div>
                                            )}
                                        </>
                                    ) : (
                                        <p className="text-muted-foreground text-sm">Loading performance data...</p>
                                    )}
                                </CardContent>
                            </Card>
                        )
                    })}
                </div>
            )}
        </div>
    )
}

