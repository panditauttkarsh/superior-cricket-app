'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Badge } from '@/components/ui/badge'
import { 
    Trophy, TrendingUp, TrendingDown, Minus,
    Activity, Circle, BarChart3, Target, Zap, Shield
} from 'lucide-react'
import { getLeaderboard } from '@/lib/services/playerService'
import { Leaderboard, LeaderboardEntry } from '@/types/player'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'

const LEADERBOARD_TYPES = [
    { value: 'runs', label: 'Most Runs', icon: Activity },
    { value: 'wickets', label: 'Most Wickets', icon: Circle },
    { value: 'average', label: 'Best Average', icon: BarChart3 },
    { value: 'strike-rate', label: 'Best Strike Rate', icon: Zap },
    { value: 'economy', label: 'Best Economy', icon: Target },
    { value: 'catches', label: 'Most Catches', icon: Shield },
] as const

export default function LeaderboardsPage() {
    const [leaderboards, setLeaderboards] = useState<Record<string, Leaderboard>>({})
    const [activeType, setActiveType] = useState<'runs' | 'wickets' | 'average' | 'strike-rate' | 'economy' | 'catches'>('runs')
    const [period, setPeriod] = useState<'overall' | 'season' | 'month' | 'week'>('overall')
    const [isLoading, setIsLoading] = useState(true)

    useEffect(() => {
        loadLeaderboard()
    }, [activeType, period])

    const loadLeaderboard = async () => {
        setIsLoading(true)
        try {
            const data = await getLeaderboard(activeType, period)
            setLeaderboards(prev => ({
                ...prev,
                [`${activeType}-${period}`]: data
            }))
        } catch (error) {
            console.error('Failed to load leaderboard:', error)
        } finally {
            setIsLoading(false)
        }
    }

    const currentLeaderboard = leaderboards[`${activeType}-${period}`]

    const getRankIcon = (rank: number) => {
        if (rank === 1) return <Trophy className="h-5 w-5 text-yellow-400" />
        if (rank === 2) return <Trophy className="h-5 w-5 text-gray-300" />
        if (rank === 3) return <Trophy className="h-5 w-5 text-orange-400" />
        return null
    }

    const getChangeIcon = (change: number) => {
        if (change > 0) return <TrendingUp className="h-4 w-4 text-green-400" />
        if (change < 0) return <TrendingDown className="h-4 w-4 text-red-400" />
        return <Minus className="h-4 w-4 text-muted-foreground" />
    }

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight text-foreground/90">
                        Leaderboards
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        Top performers across all categories
                    </p>
                </div>
            </div>

            {/* Period Filter */}
            <div className="flex gap-2">
                {(['overall', 'season', 'month', 'week'] as const).map((p) => (
                    <Button
                        key={p}
                        variant={period === p ? 'default' : 'outline'}
                        size="sm"
                        onClick={() => setPeriod(p)}
                    >
                        {p.charAt(0).toUpperCase() + p.slice(1)}
                    </Button>
                ))}
            </div>

            {/* Leaderboard Type Tabs */}
            <Tabs value={activeType} onValueChange={(v) => setActiveType(v as typeof activeType)}>
                <TabsList className="grid w-full grid-cols-3 lg:grid-cols-6">
                    {LEADERBOARD_TYPES.map((type) => {
                        const Icon = type.icon
                        return (
                            <TabsTrigger key={type.value} value={type.value} className="flex items-center gap-2">
                                <Icon className="h-4 w-4" />
                                <span className="hidden sm:inline">{type.label}</span>
                            </TabsTrigger>
                        )
                    })}
                </TabsList>

                {LEADERBOARD_TYPES.map((type) => (
                    <TabsContent key={type.value} value={type.value} className="mt-6">
                        <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                            <CardHeader>
                                <CardTitle className="flex items-center gap-2">
                                    <type.icon className="h-5 w-5" />
                                    {type.label} - {period.charAt(0).toUpperCase() + period.slice(1)}
                                </CardTitle>
                            </CardHeader>
                            <CardContent>
                                {isLoading ? (
                                    <p className="text-muted-foreground text-center py-8">Loading leaderboard...</p>
                                ) : !currentLeaderboard || currentLeaderboard.entries.length === 0 ? (
                                    <p className="text-muted-foreground text-center py-8">No data available</p>
                                ) : (
                                    <div className="space-y-3">
                                        {currentLeaderboard.entries.map((entry: LeaderboardEntry) => (
                                            <div
                                                key={entry.playerId}
                                                className={`flex items-center gap-4 p-4 rounded-lg border transition-all ${
                                                    entry.rank <= 3
                                                        ? 'bg-gradient-to-r from-primary/10 to-primary/5 border-primary/30'
                                                        : 'bg-card/40 border-white/10 hover:bg-card/60'
                                                }`}
                                            >
                                                {/* Rank */}
                                                <div className="flex items-center justify-center w-12 h-12 rounded-full bg-background/50 border-2 border-primary/30">
                                                    {getRankIcon(entry.rank) || (
                                                        <span className="text-lg font-bold">{entry.rank}</span>
                                                    )}
                                                </div>

                                                {/* Avatar */}
                                                <Avatar className="h-12 w-12">
                                                    <AvatarImage src={entry.avatar} alt={entry.playerName} />
                                                    <AvatarFallback className="bg-primary text-primary-foreground">
                                                        {entry.playerName.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)}
                                                    </AvatarFallback>
                                                </Avatar>

                                                {/* Player Info */}
                                                <div className="flex-1">
                                                    <div className="flex items-center gap-2">
                                                        <p className="font-semibold">{entry.playerName}</p>
                                                        {entry.teamName && (
                                                            <Badge variant="outline" className="text-xs">
                                                                {entry.teamName}
                                                            </Badge>
                                                        )}
                                                    </div>
                                                </div>

                                                {/* Value */}
                                                <div className="text-right">
                                                    <p className="text-2xl font-bold">{entry.value}</p>
                                                    {type.value === 'average' || type.value === 'strike-rate' || type.value === 'economy' ? (
                                                        <p className="text-xs text-muted-foreground">Rate</p>
                                                    ) : (
                                                        <p className="text-xs text-muted-foreground">Total</p>
                                                    )}
                                                </div>

                                                {/* Change */}
                                                <div className="flex items-center gap-1">
                                                    {getChangeIcon(entry.change)}
                                                    {entry.change !== 0 && (
                                                        <span className={`text-sm font-medium ${
                                                            entry.change > 0 ? 'text-green-400' : 'text-red-400'
                                                        }`}>
                                                            {Math.abs(entry.change)}
                                                        </span>
                                                    )}
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </CardContent>
                        </Card>
                    </TabsContent>
                ))}
            </Tabs>
        </div>
    )
}

