'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
    Radio, Play, Clock, TrendingUp, Users,
    Zap, Trophy, Activity
} from 'lucide-react'
import { useAppStore } from '@/lib/store'
import { getLiveScore, subscribeToMatchUpdates } from '@/lib/services/matchCenterService'
import { MatchEvent, LiveScore } from '@/types/matchCenter'
import Link from 'next/link'

export default function MatchCenterPage() {
    const { matches } = useAppStore()
    const [liveMatches, setLiveMatches] = useState<Array<{ match: any; score: LiveScore | null }>>([])
    const [recentEvents, setRecentEvents] = useState<MatchEvent[]>([])

    useEffect(() => {
        loadLiveMatches()
    }, [matches])

    useEffect(() => {
        // Subscribe to updates for all live matches
        const unsubscribers = liveMatches.map(({ match }) => {
            if (match.status === 'live') {
                return subscribeToMatchUpdates(match.id, (event) => {
                    setRecentEvents(prev => [event, ...prev].slice(0, 10))
                    loadLiveMatches() // Refresh scores
                })
            }
            return null
        }).filter(Boolean) as Array<() => void>

        return () => {
            unsubscribers.forEach(unsub => unsub())
        }
    }, [liveMatches])

    const loadLiveMatches = async () => {
        const live = matches.filter(m => m.status === 'live')
        const scores = await Promise.all(
            live.map(async (match) => ({
                match,
                score: await getLiveScore(match.id)
            }))
        )
        setLiveMatches(scores)
    }

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight text-foreground/90">
                        Match Center
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        Live matches and real-time updates
                    </p>
                </div>
            </div>

            {/* Live Matches */}
            {liveMatches.length === 0 ? (
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-8 text-center">
                        <Radio className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                        <p className="text-muted-foreground mb-4">No live matches at the moment.</p>
                        <Button asChild>
                            <Link href="/matches">View All Matches</Link>
                        </Button>
                    </CardContent>
                </Card>
            ) : (
                <div className="space-y-4">
                    {liveMatches.map(({ match, score }) => (
                        <Card
                            key={match.id}
                            className="bg-gradient-to-br from-red-900/40 to-orange-900/40 border-red-500/30 backdrop-blur-sm"
                        >
                            <CardHeader>
                                <div className="flex items-center justify-between">
                                    <CardTitle className="flex items-center gap-2 text-red-300">
                                        <Radio className="h-5 w-5 animate-pulse" />
                                        LIVE MATCH
                                    </CardTitle>
                                    <Badge className="bg-red-500/20 text-red-400 border-red-500/30 animate-pulse">
                                        LIVE
                                    </Badge>
                                </div>
                            </CardHeader>
                            <CardContent>
                                {score && (
                                    <div className="space-y-4">
                                        {/* Score Display */}
                                        <div className="grid gap-4 md:grid-cols-2">
                                            <div className={`p-4 rounded-lg border-2 ${
                                                score.currentBatting === 'team1'
                                                    ? 'border-primary bg-primary/10'
                                                    : 'border-white/20 bg-card/40'
                                            }`}>
                                                <div className="flex items-center justify-between mb-2">
                                                    <span className="font-semibold">{score.team1.name}</span>
                                                    {score.currentBatting === 'team1' && (
                                                        <Badge className="bg-green-500/20 text-green-400">Batting</Badge>
                                                    )}
                                                </div>
                                                <div className="text-3xl font-bold">
                                                    {score.team1.runs}/{score.team1.wickets}
                                                </div>
                                                <div className="text-sm text-muted-foreground">
                                                    ({score.team1.overs}.{score.team1.balls} ov) • RR: {score.team1.runRate.toFixed(2)}
                                                </div>
                                            </div>
                                            <div className={`p-4 rounded-lg border-2 ${
                                                score.currentBatting === 'team2'
                                                    ? 'border-primary bg-primary/10'
                                                    : 'border-white/20 bg-card/40'
                                            }`}>
                                                <div className="flex items-center justify-between mb-2">
                                                    <span className="font-semibold">{score.team2.name}</span>
                                                    {score.currentBatting === 'team2' && (
                                                        <Badge className="bg-green-500/20 text-green-400">Batting</Badge>
                                                    )}
                                                </div>
                                                {score.target ? (
                                                    <>
                                                        <div className="text-3xl font-bold">
                                                            Target: {score.target}
                                                        </div>
                                                        <div className="text-sm text-muted-foreground">
                                                            {score.team2.runs}/{score.team2.wickets} ({score.team2.overs}.{score.team2.balls})
                                                        </div>
                                                        {score.requiredRunRate && (
                                                            <div className="text-sm text-muted-foreground">
                                                                Required RR: {score.requiredRunRate.toFixed(2)}
                                                            </div>
                                                        )}
                                                    </>
                                                ) : (
                                                    <>
                                                        <div className="text-3xl font-bold">
                                                            {score.team2.runs}/{score.team2.wickets}
                                                        </div>
                                                        <div className="text-sm text-muted-foreground">
                                                            ({score.team2.overs}.{score.team2.balls} ov) • RR: {score.team2.runRate.toFixed(2)}
                                                        </div>
                                                    </>
                                                )}
                                            </div>
                                        </div>

                                        {/* Current Over */}
                                        <div className="p-3 bg-card/40 rounded-lg border border-white/10">
                                            <div className="flex items-center justify-between">
                                                <span className="text-sm text-muted-foreground">Current Over</span>
                                                <span className="font-bold">
                                                    {score.currentOver}.{score.currentBall}
                                                </span>
                                            </div>
                                        </div>

                                        {/* Actions */}
                                        <Button className="w-full" asChild>
                                            <Link href={`/matches/${match.id}`}>
                                                View Full Details
                                            </Link>
                                        </Button>
                                    </div>
                                )}
                            </CardContent>
                        </Card>
                    ))}
                </div>
            )}

            {/* Recent Events */}
            {recentEvents.length > 0 && (
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <Activity className="h-5 w-5" />
                            Recent Events
                        </CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="space-y-2">
                            {recentEvents.map((event) => (
                                <div
                                    key={event.id}
                                    className={`p-3 rounded-lg border ${
                                        event.isHighlight
                                            ? 'bg-primary/10 border-primary/30'
                                            : 'bg-card/40 border-white/10'
                                    }`}
                                >
                                    <div className="flex items-center justify-between">
                                        <div>
                                            <p className="text-sm font-medium">{event.description}</p>
                                            <p className="text-xs text-muted-foreground">
                                                {event.over}.{event.ball} • {new Date(event.timestamp).toLocaleTimeString()}
                                            </p>
                                        </div>
                                        {event.runs > 0 && (
                                            <Badge className="bg-green-500/20 text-green-400">
                                                +{event.runs}
                                            </Badge>
                                        )}
                                    </div>
                                </div>
                            ))}
                        </div>
                    </CardContent>
                </Card>
            )}
        </div>
    )
}

