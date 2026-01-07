'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
    Trophy, ArrowLeft, TrendingUp, TrendingDown, Minus,
    Award, BarChart3
} from 'lucide-react'
import { getPointsTable } from '@/lib/services/tournamentService'
import { PointsTable, PointsTableEntry } from '@/types/tournament'

export default function PointsTablePage() {
    const params = useParams()
    const router = useRouter()
    const tournamentId = params.id as string
    
    const [pointsTable, setPointsTable] = useState<PointsTable | null>(null)
    const [isLoading, setIsLoading] = useState(true)

    useEffect(() => {
        if (tournamentId) {
            loadPointsTable()
        }
    }, [tournamentId])

    const loadPointsTable = async () => {
        setIsLoading(true)
        try {
            const data = await getPointsTable(tournamentId)
            setPointsTable(data)
        } catch (error) {
            console.error('Failed to load points table:', error)
        } finally {
            setIsLoading(false)
        }
    }

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

    if (isLoading) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <p className="text-muted-foreground">Loading points table...</p>
            </div>
        )
    }

    if (!pointsTable || pointsTable.standings.length === 0) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <Button variant="ghost" onClick={() => router.back()} className="mb-2">
                    <ArrowLeft className="mr-2 h-4 w-4" />
                    Back
                </Button>
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-8 text-center">
                        <BarChart3 className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                        <p className="text-muted-foreground">Points table not available yet.</p>
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
                    <h1 className="text-3xl font-bold tracking-tight text-foreground/90">
                        Points Table
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        Updated: {new Date(pointsTable.updatedAt).toLocaleString()}
                    </p>
                </div>
            </div>

            {/* Points Table */}
            <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <Trophy className="h-5 w-5" />
                        Standings
                    </CardTitle>
                </CardHeader>
                <CardContent>
                    <div className="overflow-x-auto">
                        <table className="w-full">
                            <thead>
                                <tr className="border-b border-white/10">
                                    <th className="text-left p-4 text-sm font-semibold text-muted-foreground">Pos</th>
                                    <th className="text-left p-4 text-sm font-semibold text-muted-foreground">Team</th>
                                    <th className="text-center p-4 text-sm font-semibold text-muted-foreground">P</th>
                                    <th className="text-center p-4 text-sm font-semibold text-muted-foreground">W</th>
                                    <th className="text-center p-4 text-sm font-semibold text-muted-foreground">L</th>
                                    <th className="text-center p-4 text-sm font-semibold text-muted-foreground">T</th>
                                    <th className="text-center p-4 text-sm font-semibold text-muted-foreground">NR</th>
                                    <th className="text-center p-4 text-sm font-semibold text-muted-foreground">Pts</th>
                                    <th className="text-center p-4 text-sm font-semibold text-muted-foreground">NRR</th>
                                    <th className="text-center p-4 text-sm font-semibold text-muted-foreground">Change</th>
                                </tr>
                            </thead>
                            <tbody>
                                {pointsTable.standings.map((entry: PointsTableEntry) => (
                                    <tr
                                        key={entry.teamId}
                                        className={`border-b border-white/5 hover:bg-card/40 transition-colors ${
                                            entry.position <= 3 ? 'bg-gradient-to-r from-primary/5 to-primary/10' : ''
                                        }`}
                                    >
                                        <td className="p-4">
                                            <div className="flex items-center gap-2">
                                                {getRankIcon(entry.position) || (
                                                    <span className="font-bold">{entry.position}</span>
                                                )}
                                            </div>
                                        </td>
                                        <td className="p-4">
                                            <div className="flex items-center gap-3">
                                                <div className="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center">
                                                    <Award className="h-4 w-4 text-primary" />
                                                </div>
                                                <span className="font-semibold">{entry.teamName}</span>
                                            </div>
                                        </td>
                                        <td className="p-4 text-center font-medium">{entry.played}</td>
                                        <td className="p-4 text-center font-medium text-green-400">{entry.won}</td>
                                        <td className="p-4 text-center font-medium text-red-400">{entry.lost}</td>
                                        <td className="p-4 text-center font-medium">{entry.tied}</td>
                                        <td className="p-4 text-center font-medium">{entry.noResult}</td>
                                        <td className="p-4 text-center font-bold text-primary">{entry.points}</td>
                                        <td className="p-4 text-center font-medium">
                                            {entry.netRunRate > 0 ? '+' : ''}{entry.netRunRate.toFixed(3)}
                                        </td>
                                        <td className="p-4">
                                            <div className="flex items-center justify-center gap-1">
                                                {getChangeIcon(entry.change)}
                                                {entry.change !== 0 && (
                                                    <span className={`text-sm font-medium ${
                                                        entry.change > 0 ? 'text-green-400' : 'text-red-400'
                                                    }`}>
                                                        {Math.abs(entry.change)}
                                                    </span>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>

                    {/* Legend */}
                    <div className="mt-6 pt-4 border-t border-white/10">
                        <div className="grid gap-2 text-sm text-muted-foreground md:grid-cols-4">
                            <div><span className="font-semibold">P:</span> Played</div>
                            <div><span className="font-semibold">W:</span> Won</div>
                            <div><span className="font-semibold">L:</span> Lost</div>
                            <div><span className="font-semibold">T:</span> Tied</div>
                            <div><span className="font-semibold">NR:</span> No Result</div>
                            <div><span className="font-semibold">Pts:</span> Points</div>
                            <div><span className="font-semibold">NRR:</span> Net Run Rate</div>
                        </div>
                    </div>
                </CardContent>
            </Card>
        </div>
    )
}

