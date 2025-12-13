'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
    Trophy, TrendingUp, Target, Zap, 
    Activity, Circle, Shield, Award,
    BarChart3, Calendar, Users
} from 'lucide-react'
import { useAppStore } from '@/lib/store'
import { getPlayerProfileByUserId } from '@/lib/services/playerService'
import { PlayerProfile } from '@/types/player'
import Image from 'next/image'

export default function PlayerDashboardPage() {
    const { user } = useAppStore()
    const [playerProfile, setPlayerProfile] = useState<PlayerProfile | null>(null)
    const [isLoading, setIsLoading] = useState(true)

    useEffect(() => {
        if (user) {
            loadPlayerProfile()
        }
    }, [user])

    const loadPlayerProfile = async () => {
        if (!user) return
        
        setIsLoading(true)
        try {
            const profile = await getPlayerProfileByUserId(user.id)
            setPlayerProfile(profile)
        } catch (error) {
            console.error('Failed to load player profile:', error)
        } finally {
            setIsLoading(false)
        }
    }

    if (isLoading) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <p className="text-muted-foreground">Loading player dashboard...</p>
            </div>
        )
    }

    if (!playerProfile) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-8 text-center">
                        <p className="text-muted-foreground mb-4">No player profile found.</p>
                        <Button>Create Player Profile</Button>
                    </CardContent>
                </Card>
            </div>
        )
    }

    const { stats } = playerProfile
    const batting = stats.batting
    const bowling = stats.bowling
    const fielding = stats.fielding

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight text-foreground/90">
                        Player Dashboard
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        Welcome back, {playerProfile.name}
                    </p>
                </div>
            </div>

            {/* Quick Stats Cards */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <Card className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-sm text-muted-foreground mb-1">Total Matches</p>
                                <p className="text-3xl font-bold">{stats.totalMatches}</p>
                            </div>
                            <Calendar className="h-8 w-8 text-blue-400" />
                        </div>
                    </CardContent>
                </Card>

                <Card className="bg-gradient-to-br from-green-500/20 to-green-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-sm text-muted-foreground mb-1">Total Runs</p>
                                <p className="text-3xl font-bold">{stats.totalRuns}</p>
                            </div>
                            <Activity className="h-8 w-8 text-green-400" />
                        </div>
                    </CardContent>
                </Card>

                <Card className="bg-gradient-to-br from-purple-500/20 to-purple-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-sm text-muted-foreground mb-1">Total Wickets</p>
                                <p className="text-3xl font-bold">{stats.totalWickets}</p>
                            </div>
                            <Circle className="h-8 w-8 text-purple-400" />
                        </div>
                    </CardContent>
                </Card>

                <Card className="bg-gradient-to-br from-orange-500/20 to-orange-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-sm text-muted-foreground mb-1">Catches</p>
                                <p className="text-3xl font-bold">{fielding.catches}</p>
                            </div>
                            <Shield className="h-8 w-8 text-orange-400" />
                        </div>
                    </CardContent>
                </Card>
            </div>

            {/* Detailed Stats Tabs */}
            <Tabs defaultValue="batting" className="space-y-6">
                <TabsList className="grid w-full grid-cols-3">
                    <TabsTrigger value="batting" className="flex items-center gap-2">
                        <Activity className="h-4 w-4" />
                        Batting
                    </TabsTrigger>
                    <TabsTrigger value="bowling" className="flex items-center gap-2">
                        <Circle className="h-4 w-4" />
                        Bowling
                    </TabsTrigger>
                    <TabsTrigger value="fielding" className="flex items-center gap-2">
                        <Shield className="h-4 w-4" />
                        Fielding
                    </TabsTrigger>
                </TabsList>

                {/* Batting Stats */}
                <TabsContent value="batting" className="space-y-4">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2">
                                <Activity className="h-5 w-5" />
                                Batting Statistics
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Matches</p>
                                    <p className="text-2xl font-bold">{batting.matches}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Innings</p>
                                    <p className="text-2xl font-bold">{batting.innings}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Runs</p>
                                    <p className="text-2xl font-bold">{batting.runs}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Balls</p>
                                    <p className="text-2xl font-bold">{batting.balls}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Average</p>
                                    <p className="text-2xl font-bold">{batting.average.toFixed(2)}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Strike Rate</p>
                                    <p className="text-2xl font-bold">{batting.strikeRate.toFixed(2)}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Highest Score</p>
                                    <p className="text-2xl font-bold">{batting.highestScore}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Centuries</p>
                                    <p className="text-2xl font-bold">{batting.centuries}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Half Centuries</p>
                                    <p className="text-2xl font-bold">{batting.halfCenturies}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Fours</p>
                                    <p className="text-2xl font-bold">{batting.fours}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Sixes</p>
                                    <p className="text-2xl font-bold">{batting.sixes}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Ducks</p>
                                    <p className="text-2xl font-bold">{batting.ducks}</p>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </TabsContent>

                {/* Bowling Stats */}
                <TabsContent value="bowling" className="space-y-4">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2">
                                <Circle className="h-5 w-5" />
                                Bowling Statistics
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Matches</p>
                                    <p className="text-2xl font-bold">{bowling.matches}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Innings</p>
                                    <p className="text-2xl font-bold">{bowling.innings}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Overs</p>
                                    <p className="text-2xl font-bold">{bowling.overs}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Maidens</p>
                                    <p className="text-2xl font-bold">{bowling.maidens}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Runs</p>
                                    <p className="text-2xl font-bold">{bowling.runs}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Wickets</p>
                                    <p className="text-2xl font-bold">{bowling.wickets}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Average</p>
                                    <p className="text-2xl font-bold">{bowling.average.toFixed(2)}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Economy</p>
                                    <p className="text-2xl font-bold">{bowling.economy.toFixed(2)}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Strike Rate</p>
                                    <p className="text-2xl font-bold">{bowling.strikeRate.toFixed(2)}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Best Bowling</p>
                                    <p className="text-2xl font-bold">{bowling.bestBowling}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">4 Wickets</p>
                                    <p className="text-2xl font-bold">{bowling.fourWickets}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">5 Wickets</p>
                                    <p className="text-2xl font-bold">{bowling.fiveWickets}</p>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </TabsContent>

                {/* Fielding Stats */}
                <TabsContent value="fielding" className="space-y-4">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2">
                                <Shield className="h-5 w-5" />
                                Fielding Statistics
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="grid gap-6 md:grid-cols-3">
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Catches</p>
                                    <p className="text-4xl font-bold">{fielding.catches}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Stumpings</p>
                                    <p className="text-4xl font-bold">{fielding.stumpings}</p>
                                </div>
                                <div className="space-y-2">
                                    <p className="text-sm text-muted-foreground">Run Outs</p>
                                    <p className="text-4xl font-bold">{fielding.runOuts}</p>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </TabsContent>
            </Tabs>
        </div>
    )
}

