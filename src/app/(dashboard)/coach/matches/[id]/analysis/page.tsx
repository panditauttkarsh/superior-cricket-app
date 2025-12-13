'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
    BarChart3, TrendingUp, TrendingDown, Target,
    AlertCircle, CheckCircle, Activity, Trophy
} from 'lucide-react'
import { getMatchAnalysis } from '@/lib/services/coachService'
import { MatchAnalysis } from '@/types/coach'
import { useAppStore } from '@/lib/store'

export default function MatchAnalysisPage() {
    const params = useParams()
    const router = useRouter()
    const { matches } = useAppStore()
    const matchId = params.id as string
    const teamId = '1' // In production, get from context or params
    
    const [analysis, setAnalysis] = useState<MatchAnalysis | null>(null)
    const [isLoading, setIsLoading] = useState(true)

    const match = matches.find(m => m.id === matchId)

    useEffect(() => {
        if (matchId && teamId) {
            loadAnalysis()
        }
    }, [matchId, teamId])

    const loadAnalysis = async () => {
        setIsLoading(true)
        try {
            const data = await getMatchAnalysis(matchId, teamId)
            setAnalysis(data)
        } catch (error) {
            console.error('Failed to load analysis:', error)
        } finally {
            setIsLoading(false)
        }
    }

    if (isLoading) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <p className="text-muted-foreground">Loading match analysis...</p>
            </div>
        )
    }

    if (!analysis) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-8 text-center">
                        <AlertCircle className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                        <p className="text-muted-foreground mb-4">Analysis not available.</p>
                        <Button onClick={() => router.back()}>Go Back</Button>
                    </CardContent>
                </Card>
            </div>
        )
    }

    const { batting, bowling, fielding, keyMoments } = analysis.analysis

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <Button variant="ghost" onClick={() => router.back()} className="mb-2">
                        ← Back
                    </Button>
                    <h1 className="text-3xl font-bold tracking-tight text-foreground/90">
                        Match Analysis
                    </h1>
                    {match && (
                        <p className="text-muted-foreground mt-1">
                            {match.opponent} • {match.date}
                        </p>
                    )}
                </div>
            </div>

            {/* Batting Analysis */}
            <Card className="bg-gradient-to-br from-green-900/40 to-emerald-900/40 border-green-500/30 backdrop-blur-sm">
                <CardHeader>
                    <CardTitle className="flex items-center gap-2 text-green-300">
                        <Trophy className="h-5 w-5" />
                        Batting Performance
                    </CardTitle>
                </CardHeader>
                <CardContent>
                    <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
                        <div className="space-y-2">
                            <p className="text-sm text-green-200">Total Runs</p>
                            <p className="text-3xl font-bold text-green-300">{batting.totalRuns}</p>
                        </div>
                        <div className="space-y-2">
                            <p className="text-sm text-green-200">Wickets</p>
                            <p className="text-3xl font-bold text-green-300">{batting.wickets}</p>
                        </div>
                        <div className="space-y-2">
                            <p className="text-sm text-green-200">Run Rate</p>
                            <p className="text-3xl font-bold text-green-300">{batting.runRate}</p>
                        </div>
                        <div className="space-y-2">
                            <p className="text-sm text-green-200">Overs</p>
                            <p className="text-3xl font-bold text-green-300">{batting.overs}</p>
                        </div>
                    </div>

                    {/* Phase-wise Performance */}
                    <div className="mt-6 grid gap-4 md:grid-cols-3">
                        <div className="p-4 bg-white/5 rounded-lg border border-white/10">
                            <p className="text-sm text-green-200 mb-2">Powerplay</p>
                            <p className="text-xl font-bold text-green-300">
                                {batting.powerplay.runs}/{batting.powerplay.wickets}
                            </p>
                        </div>
                        <div className="p-4 bg-white/5 rounded-lg border border-white/10">
                            <p className="text-sm text-green-200 mb-2">Middle Overs</p>
                            <p className="text-xl font-bold text-green-300">
                                {batting.middleOvers.runs}/{batting.middleOvers.wickets}
                            </p>
                        </div>
                        <div className="p-4 bg-white/5 rounded-lg border border-white/10">
                            <p className="text-sm text-green-200 mb-2">Death Overs</p>
                            <p className="text-xl font-bold text-green-300">
                                {batting.deathOvers.runs}/{batting.deathOvers.wickets}
                            </p>
                        </div>
                    </div>

                    {/* Partnerships */}
                    {batting.partnerships.length > 0 && (
                        <div className="mt-6">
                            <h4 className="text-sm font-semibold text-green-200 mb-3">Key Partnerships</h4>
                            <div className="space-y-2">
                                {batting.partnerships.map((partnership, i) => (
                                    <div key={i} className="flex items-center justify-between p-3 bg-white/5 rounded-lg border border-white/10">
                                        <div>
                                            <p className="text-sm text-green-300 font-medium">
                                                {partnership.players.join(' & ')}
                                            </p>
                                            <p className="text-xs text-green-200/70">
                                                {partnership.balls} balls
                                            </p>
                                        </div>
                                        <p className="text-lg font-bold text-green-300">
                                            {partnership.runs} runs
                                        </p>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}
                </CardContent>
            </Card>

            {/* Bowling Analysis */}
            <Card className="bg-gradient-to-br from-purple-900/40 to-pink-900/40 border-purple-500/30 backdrop-blur-sm">
                <CardHeader>
                    <CardTitle className="flex items-center gap-2 text-purple-300">
                        <Activity className="h-5 w-5" />
                        Bowling Performance
                    </CardTitle>
                </CardHeader>
                <CardContent>
                    <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
                        <div className="space-y-2">
                            <p className="text-sm text-purple-200">Runs Conceded</p>
                            <p className="text-3xl font-bold text-purple-300">{bowling.totalRuns}</p>
                        </div>
                        <div className="space-y-2">
                            <p className="text-sm text-purple-200">Wickets</p>
                            <p className="text-3xl font-bold text-purple-300">{bowling.wickets}</p>
                        </div>
                        <div className="space-y-2">
                            <p className="text-sm text-purple-200">Economy</p>
                            <p className="text-3xl font-bold text-purple-300">{bowling.economy}</p>
                        </div>
                        <div className="space-y-2">
                            <p className="text-sm text-purple-200">Dot Balls</p>
                            <p className="text-3xl font-bold text-purple-300">{bowling.dotBalls}</p>
                        </div>
                    </div>

                    <div className="mt-6 grid gap-4 md:grid-cols-3">
                        <div className="p-4 bg-white/5 rounded-lg border border-white/10">
                            <p className="text-sm text-purple-200 mb-2">Boundaries</p>
                            <p className="text-xl font-bold text-purple-300">{bowling.boundaries}</p>
                        </div>
                        <div className="p-4 bg-white/5 rounded-lg border border-white/10">
                            <p className="text-sm text-purple-200 mb-2">Extras</p>
                            <p className="text-xl font-bold text-purple-300">{bowling.extras}</p>
                        </div>
                        <div className="p-4 bg-white/5 rounded-lg border border-white/10">
                            <p className="text-sm text-purple-200 mb-2">Overs</p>
                            <p className="text-xl font-bold text-purple-300">{bowling.overs}</p>
                        </div>
                    </div>
                </CardContent>
            </Card>

            {/* Fielding Analysis */}
            <Card className="bg-gradient-to-br from-orange-900/40 to-red-900/40 border-orange-500/30 backdrop-blur-sm">
                <CardHeader>
                    <CardTitle className="flex items-center gap-2 text-orange-300">
                        <Target className="h-5 w-5" />
                        Fielding Performance
                    </CardTitle>
                </CardHeader>
                <CardContent>
                    <div className="grid gap-6 md:grid-cols-4">
                        <div className="space-y-2">
                            <p className="text-sm text-orange-200">Catches</p>
                            <p className="text-3xl font-bold text-orange-300">{fielding.catches}</p>
                        </div>
                        <div className="space-y-2">
                            <p className="text-sm text-orange-200">Stumpings</p>
                            <p className="text-3xl font-bold text-orange-300">{fielding.stumpings}</p>
                        </div>
                        <div className="space-y-2">
                            <p className="text-sm text-orange-200">Run Outs</p>
                            <p className="text-3xl font-bold text-orange-300">{fielding.runOuts}</p>
                        </div>
                        <div className="space-y-2">
                            <p className="text-sm text-orange-200">Dropped</p>
                            <p className="text-3xl font-bold text-red-400">{fielding.droppedCatches}</p>
                        </div>
                    </div>
                </CardContent>
            </Card>

            {/* Key Moments */}
            {keyMoments.length > 0 && (
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <Activity className="h-5 w-5" />
                            Key Moments
                        </CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="space-y-3">
                            {keyMoments.map((moment, i) => (
                                <div
                                    key={i}
                                    className={`flex items-start gap-3 p-4 rounded-lg border ${
                                        moment.impact === 'positive'
                                            ? 'bg-green-500/10 border-green-500/30'
                                            : moment.impact === 'negative'
                                            ? 'bg-red-500/10 border-red-500/30'
                                            : 'bg-card/40 border-white/10'
                                    }`}
                                >
                                    {moment.impact === 'positive' ? (
                                        <CheckCircle className="h-5 w-5 text-green-400 mt-0.5" />
                                    ) : moment.impact === 'negative' ? (
                                        <AlertCircle className="h-5 w-5 text-red-400 mt-0.5" />
                                    ) : (
                                        <Activity className="h-5 w-5 text-muted-foreground mt-0.5" />
                                    )}
                                    <div className="flex-1">
                                        <p className="text-sm font-medium">{moment.description}</p>
                                        <p className="text-xs text-muted-foreground mt-1">
                                            {new Date(moment.timestamp).toLocaleString()}
                                        </p>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </CardContent>
                </Card>
            )}

            {/* Recommendations */}
            {analysis.recommendations.length > 0 && (
                <Card className="bg-gradient-to-br from-blue-900/40 to-cyan-900/40 border-blue-500/30 backdrop-blur-sm">
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2 text-blue-300">
                            <BarChart3 className="h-5 w-5" />
                            Recommendations
                        </CardTitle>
                    </CardHeader>
                    <CardContent>
                        <ul className="space-y-2">
                            {analysis.recommendations.map((rec, i) => (
                                <li key={i} className="flex items-start gap-2 text-blue-200">
                                    <span className="text-blue-400 mt-1">•</span>
                                    <span>{rec}</span>
                                </li>
                            ))}
                        </ul>
                    </CardContent>
                </Card>
            )}
        </div>
    )
}

