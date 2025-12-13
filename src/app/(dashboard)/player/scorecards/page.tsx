'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Activity, Circle, Shield, Calendar, Trophy } from 'lucide-react'
import { useAppStore } from '@/lib/store'
import { getPlayerScorecards } from '@/lib/services/playerService'
import { ScorecardEntry } from '@/types/player'
import Link from 'next/link'

export default function ScorecardsPage() {
    const { user } = useAppStore()
    const [scorecards, setScorecards] = useState<ScorecardEntry[]>([])
    const [isLoading, setIsLoading] = useState(true)

    useEffect(() => {
        if (user) {
            loadScorecards()
        }
    }, [user])

    const loadScorecards = async () => {
        if (!user) return
        
        setIsLoading(true)
        try {
            // In production, get playerId from user profile
            const playerId = '1' // Mock player ID
            const data = await getPlayerScorecards(playerId)
            setScorecards(data)
        } catch (error) {
            console.error('Failed to load scorecards:', error)
        } finally {
            setIsLoading(false)
        }
    }

    if (isLoading) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <p className="text-muted-foreground">Loading scorecards...</p>
            </div>
        )
    }

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight text-foreground/90">
                        My Scorecards
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        View your match performance history
                    </p>
                </div>
            </div>

            {scorecards.length === 0 ? (
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-8 text-center">
                        <Trophy className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                        <p className="text-muted-foreground mb-4">No scorecards found.</p>
                        <Button asChild>
                            <Link href="/matches">View Matches</Link>
                        </Button>
                    </CardContent>
                </Card>
            ) : (
                <div className="space-y-4">
                    {scorecards.map((scorecard) => (
                        <Card 
                            key={scorecard.id} 
                            className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl hover:shadow-2xl transition-all duration-300"
                        >
                            <CardHeader>
                                <div className="flex items-center justify-between">
                                    <CardTitle className="flex items-center gap-2">
                                        <Calendar className="h-5 w-5" />
                                        Match #{scorecard.matchId}
                                    </CardTitle>
                                    <Button variant="outline" size="sm" asChild>
                                        <Link href={`/matches/${scorecard.matchId}`}>
                                            View Match
                                        </Link>
                                    </Button>
                                </div>
                            </CardHeader>
                            <CardContent>
                                <div className="grid gap-6 md:grid-cols-3">
                                    {/* Batting */}
                                    {scorecard.batting && (
                                        <div className="space-y-3">
                                            <div className="flex items-center gap-2 mb-3">
                                                <Activity className="h-5 w-5 text-green-400" />
                                                <h3 className="font-semibold">Batting</h3>
                                            </div>
                                            <div className="space-y-2">
                                                <div className="flex justify-between">
                                                    <span className="text-muted-foreground">Runs</span>
                                                    <span className="font-bold text-2xl">{scorecard.batting.runs}</span>
                                                </div>
                                                <div className="flex justify-between">
                                                    <span className="text-muted-foreground">Balls</span>
                                                    <span className="font-medium">{scorecard.batting.balls}</span>
                                                </div>
                                                <div className="flex justify-between">
                                                    <span className="text-muted-foreground">Strike Rate</span>
                                                    <span className="font-medium">{scorecard.batting.strikeRate.toFixed(2)}</span>
                                                </div>
                                                <div className="flex gap-4 mt-3">
                                                    <Badge variant="outline" className="flex items-center gap-1">
                                                        <span>4s:</span> {scorecard.batting.fours}
                                                    </Badge>
                                                    <Badge variant="outline" className="flex items-center gap-1">
                                                        <span>6s:</span> {scorecard.batting.sixes}
                                                    </Badge>
                                                </div>
                                                {scorecard.batting.dismissed && (
                                                    <div className="mt-2 text-sm text-muted-foreground">
                                                        {scorecard.batting.dismissalType && (
                                                            <span className="capitalize">{scorecard.batting.dismissalType}</span>
                                                        )}
                                                        {scorecard.batting.dismissedBy && (
                                                            <span> by {scorecard.batting.dismissedBy}</span>
                                                        )}
                                                    </div>
                                                )}
                                                {!scorecard.batting.dismissed && (
                                                    <Badge className="bg-green-500/20 text-green-400 mt-2">
                                                        Not Out
                                                    </Badge>
                                                )}
                                            </div>
                                        </div>
                                    )}

                                    {/* Bowling */}
                                    {scorecard.bowling && (
                                        <div className="space-y-3">
                                            <div className="flex items-center gap-2 mb-3">
                                                <Circle className="h-5 w-5 text-purple-400" />
                                                <h3 className="font-semibold">Bowling</h3>
                                            </div>
                                            <div className="space-y-2">
                                                <div className="flex justify-between">
                                                    <span className="text-muted-foreground">Overs</span>
                                                    <span className="font-bold text-2xl">{scorecard.bowling.overs}</span>
                                                </div>
                                                <div className="flex justify-between">
                                                    <span className="text-muted-foreground">Wickets</span>
                                                    <span className="font-bold text-xl">{scorecard.bowling.wickets}</span>
                                                </div>
                                                <div className="flex justify-between">
                                                    <span className="text-muted-foreground">Runs</span>
                                                    <span className="font-medium">{scorecard.bowling.runs}</span>
                                                </div>
                                                <div className="flex justify-between">
                                                    <span className="text-muted-foreground">Economy</span>
                                                    <span className="font-medium">{scorecard.bowling.economy.toFixed(2)}</span>
                                                </div>
                                                {scorecard.bowling.maidens > 0 && (
                                                    <Badge variant="outline" className="mt-2">
                                                        {scorecard.bowling.maidens} Maidens
                                                    </Badge>
                                                )}
                                            </div>
                                        </div>
                                    )}

                                    {/* Fielding */}
                                    {scorecard.fielding && (
                                        <div className="space-y-3">
                                            <div className="flex items-center gap-2 mb-3">
                                                <Shield className="h-5 w-5 text-orange-400" />
                                                <h3 className="font-semibold">Fielding</h3>
                                            </div>
                                            <div className="space-y-2">
                                                {scorecard.fielding.catches > 0 && (
                                                    <div className="flex justify-between">
                                                        <span className="text-muted-foreground">Catches</span>
                                                        <span className="font-bold text-xl">{scorecard.fielding.catches}</span>
                                                    </div>
                                                )}
                                                {scorecard.fielding.stumpings > 0 && (
                                                    <div className="flex justify-between">
                                                        <span className="text-muted-foreground">Stumpings</span>
                                                        <span className="font-bold text-xl">{scorecard.fielding.stumpings}</span>
                                                    </div>
                                                )}
                                                {scorecard.fielding.runOuts > 0 && (
                                                    <div className="flex justify-between">
                                                        <span className="text-muted-foreground">Run Outs</span>
                                                        <span className="font-bold text-xl">{scorecard.fielding.runOuts}</span>
                                                    </div>
                                                )}
                                                {scorecard.fielding.catches === 0 && 
                                                 scorecard.fielding.stumpings === 0 && 
                                                 scorecard.fielding.runOuts === 0 && (
                                                    <p className="text-sm text-muted-foreground">No fielding contributions</p>
                                                )}
                                            </div>
                                        </div>
                                    )}
                                </div>
                            </CardContent>
                        </Card>
                    ))}
                </div>
            )}
        </div>
    )
}

