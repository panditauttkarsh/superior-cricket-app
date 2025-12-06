'use client'

import { useParams } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { useAppStore } from '@/lib/store'
import { Calendar, MapPin, Trophy, User, TrendingUp, Brain, BarChart3, Zap, Target, Activity } from 'lucide-react'
import Image from 'next/image'
import { useState, useEffect } from 'react'
import { cn } from '@/lib/utils'
import { motion, AnimatePresence } from 'framer-motion'

interface Commentary {
    id: string
    ball: string
    commentary: string
    runs: number
    timestamp: Date
    type: 'four' | 'six' | 'wicket' | 'dot' | 'run'
}

interface AIInsight {
    id: string
    type: 'prediction' | 'analysis' | 'stat'
    title: string
    content: string
    confidence?: number
}

export default function MatchDetailsPage() {
    const params = useParams()
    const { matches } = useAppStore()
    const match = matches.find(m => m.id === params.id)
    const [activeTab, setActiveTab] = useState<'info' | 'squads' | 'scorecard' | 'commentary' | 'ai-stats'>('commentary')
    const [commentary, setCommentary] = useState<Commentary[]>([
        { id: '1', ball: '16.4', commentary: 'FOUR! Beautiful cover drive. Walks into the shot and caresses it through the covers.', runs: 4, timestamp: new Date(), type: 'four' },
        { id: '2', ball: '16.3', commentary: 'No run, good length delivery outside off, left alone.', runs: 0, timestamp: new Date(), type: 'dot' },
        { id: '3', ball: '16.2', commentary: 'SIX! That is huge! Short ball and he pulls it over deep mid-wicket.', runs: 6, timestamp: new Date(), type: 'six' },
        { id: '4', ball: '16.1', commentary: '1 run, pushed to long on for a single.', runs: 1, timestamp: new Date(), type: 'run' },
    ])
    const [aiInsights, setAIInsights] = useState<AIInsight[]>([
        { id: '1', type: 'prediction', title: 'Next Ball Prediction', content: 'High probability of a boundary. Batsman has scored 4 boundaries in the last 10 balls against this bowler.', confidence: 78 },
        { id: '2', type: 'analysis', title: 'Run Rate Analysis', content: 'Current RR: 8.5 | Required RR: 12.0. Need to accelerate. The batsman is weak against short balls - expect a bouncer next.', confidence: 85 },
        { id: '3', type: 'stat', title: 'Bowler Performance', content: 'Bowler has conceded 15 runs in the last over. Momentum shifting in favor of batting team.', confidence: 92 },
    ])

    // Simulate live commentary updates
    useEffect(() => {
        if (match?.status === 'live' && activeTab === 'commentary') {
            const interval = setInterval(() => {
                const newCommentary: Commentary[] = [
                    { id: Date.now().toString(), ball: '17.1', commentary: 'FOUR! Crashed through the covers with power and timing.', runs: 4, timestamp: new Date(), type: 'four' },
                    { id: (Date.now() + 1).toString(), ball: '17.2', commentary: 'SIX! Massive hit! Cleared the boundary with ease.', runs: 6, timestamp: new Date(), type: 'six' },
                    { id: (Date.now() + 2).toString(), ball: '17.3', commentary: 'Dot ball. Good defensive shot.', runs: 0, timestamp: new Date(), type: 'dot' },
                ]
                const randomComm = newCommentary[Math.floor(Math.random() * newCommentary.length)]
                setCommentary(prev => [randomComm, ...prev].slice(0, 20))
            }, 5000)

            return () => clearInterval(interval)
        }
    }, [match?.status, activeTab])

    if (!match) {
        return <div className="p-8 text-center text-muted-foreground">Match not found</div>
    }

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            {/* Match Header */}
            <div className="relative rounded-xl overflow-hidden bg-gradient-to-br from-gray-900 to-gray-800 text-white p-8">
                <div className="absolute inset-0 bg-[url('/stadium-pattern.png')] opacity-10" />
                <div className="relative z-10 flex flex-col md:flex-row items-center justify-between gap-8">
                    <div className="text-center md:text-left">
                        <div className="flex items-center gap-2 text-gray-400 mb-2">
                            <Calendar className="h-4 w-4" /> {match.date} • {match.type} Match
                        </div>
                        <h1 className="text-3xl font-bold flex items-center gap-4">
                            <span className="text-primary">Royal Strikers</span>
                            <span className="text-xl text-gray-500">vs</span>
                            <span>{match.opponent}</span>
                        </h1>
                        <div className="mt-2 flex items-center gap-2 text-gray-400">
                            <MapPin className="h-4 w-4" /> Wankhede Stadium, Mumbai
                        </div>
                    </div>

                    <div className="flex items-center gap-8">
                        {match.status === 'live' ? (
                            <div className="text-center">
                                <div className="text-4xl font-black text-red-500 animate-pulse flex items-center gap-2">
                                    <span className="relative flex h-3 w-3">
                                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
                                        <span className="relative inline-flex rounded-full h-3 w-3 bg-red-500"></span>
                                    </span>
                                    LIVE
                                </div>
                                <div className="text-sm font-semibold mt-1">142/3 (16.4)</div>
                            </div>
                        ) : (
                            <div className="px-6 py-2 rounded-full bg-white/10 backdrop-blur-sm border border-white/20 font-semibold uppercase tracking-widest text-sm">
                                {match.status}
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* Navigation Tabs */}
            <div className="flex border-b border-white/10 overflow-x-auto">
                {[
                    { id: 'info', label: 'Info', icon: Calendar },
                    { id: 'squads', label: 'Squads', icon: User },
                    { id: 'scorecard', label: 'Scorecard', icon: Trophy },
                    { id: 'commentary', label: 'Live Commentary', icon: Zap },
                    { id: 'ai-stats', label: 'AI Stats', icon: Brain },
                ].map((tab) => {
                    const Icon = tab.icon
                    return (
                        <button
                            key={tab.id}
                            onClick={() => setActiveTab(tab.id as any)}
                            className={cn(
                                "px-6 py-3 text-sm font-medium transition-colors relative whitespace-nowrap flex items-center gap-2",
                                activeTab === tab.id ? "text-primary" : "text-muted-foreground hover:text-white"
                            )}
                        >
                            <Icon className="h-4 w-4" />
                            {tab.label}
                            {activeTab === tab.id && (
                                <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-primary" />
                            )}
                        </button>
                    )
                })}
            </div>

            {/* Tab Content */}
            <div className="min-h-[300px]">
                <AnimatePresence mode="wait">
                    {activeTab === 'info' && (
                        <motion.div
                            key="info"
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -20 }}
                            className="grid gap-6 md:grid-cols-2"
                        >
                            <Card className="bg-card/60 backdrop-blur-sm border-white/20">
                                <CardHeader><CardTitle>Match Info</CardTitle></CardHeader>
                                <CardContent className="space-y-4">
                                    <div className="flex justify-between py-2 border-b border-white/5">
                                        <span className="text-muted-foreground">Series</span>
                                        <span className="font-medium">Premier League 2024</span>
                                    </div>
                                    <div className="flex justify-between py-2 border-b border-white/5">
                                        <span className="text-muted-foreground">Umpires</span>
                                        <span className="font-medium">J. Srinath, A. Kumble</span>
                                    </div>
                                    <div className="flex justify-between py-2 border-b border-white/5">
                                        <span className="text-muted-foreground">Toss</span>
                                        <span className="font-medium">Royal Strikers won, chose to bat</span>
                                    </div>
                                </CardContent>
                            </Card>
                            <Card className="bg-card/60 backdrop-blur-sm border-white/20">
                                <CardHeader><CardTitle>Venue Guide</CardTitle></CardHeader>
                                <CardContent>
                                    <div className="h-40 bg-muted rounded-lg flex items-center justify-center text-muted-foreground mb-4">
                                        <MapPin className="h-8 w-8 mb-2" />
                                        <span>Stadium Map Visualization</span>
                                    </div>
                                    <p className="text-sm text-muted-foreground">
                                        Batting friendly track with some assistance for spinners in the later half. Average 1st innings score: 180.
                                    </p>
                                </CardContent>
                            </Card>
                        </motion.div>
                    )}

                    {activeTab === 'squads' && (
                        <motion.div
                            key="squads"
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -20 }}
                            className="grid gap-6 md:grid-cols-2"
                        >
                            <Card className="bg-card/60 backdrop-blur-sm border-white/20">
                                <CardHeader className="bg-primary/10 border-b border-white/10">
                                    <CardTitle className="text-primary">Royal Strikers</CardTitle>
                                </CardHeader>
                                <CardContent className="p-0">
                                    {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map(i => (
                                        <div key={i} className="flex items-center gap-3 p-3 border-b border-white/5 last:border-0 hover:bg-white/5">
                                            <div className="h-8 w-8 rounded-full bg-white/10 flex items-center justify-center text-xs font-bold">
                                                {i}
                                            </div>
                                            <div>
                                                <div className="font-medium">Player Name {i}</div>
                                                <div className="text-xs text-muted-foreground">{i === 1 ? 'Batting All-rounder (C)' : 'Batsman'}</div>
                                            </div>
                                        </div>
                                    ))}
                                </CardContent>
                            </Card>
                            <Card className="bg-card/60 backdrop-blur-sm border-white/20">
                                <CardHeader className="bg-white/5 border-b border-white/10">
                                    <CardTitle>{match.opponent}</CardTitle>
                                </CardHeader>
                                <CardContent className="p-0">
                                    {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map(i => (
                                        <div key={i} className="flex items-center gap-3 p-3 border-b border-white/5 last:border-0 hover:bg-white/5">
                                            <div className="h-8 w-8 rounded-full bg-white/10 flex items-center justify-center text-xs font-bold">
                                                {i}
                                            </div>
                                            <div>
                                                <div className="font-medium">Opponent Player {i}</div>
                                                <div className="text-xs text-muted-foreground">{i === 1 ? 'Bowler (C)' : 'Bowler'}</div>
                                            </div>
                                        </div>
                                    ))}
                                </CardContent>
                            </Card>
                        </motion.div>
                    )}

                    {activeTab === 'scorecard' && (
                        <motion.div
                            key="scorecard"
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -20 }}
                        >
                            <Card className="bg-card/60 backdrop-blur-sm border-white/20">
                                <CardHeader>
                                    <CardTitle>Scorecard</CardTitle>
                                </CardHeader>
                                <CardContent>
                                    <div className="space-y-6">
                                        <div>
                                            <h3 className="font-semibold mb-3">Royal Strikers - 142/3 (16.4 Overs)</h3>
                                            <div className="space-y-2">
                                                {[
                                                    { name: 'R. Sharma', runs: 45, balls: 32, fours: 5, sixes: 2, sr: 140.6, status: 'not out' },
                                                    { name: 'V. Kohli', runs: 38, balls: 28, fours: 4, sixes: 1, sr: 135.7, status: 'not out' },
                                                    { name: 'K. Rahul', runs: 28, balls: 22, fours: 3, sixes: 0, sr: 127.3, status: 'c & b' },
                                                ].map((player, i) => (
                                                    <div key={i} className="flex items-center justify-between p-3 bg-white/5 rounded-lg">
                                                        <div>
                                                            <div className="font-medium">{player.name} {player.status !== 'not out' && `(${player.status})`}</div>
                                                            <div className="text-sm text-muted-foreground">{player.runs} ({player.balls}) - {player.fours}×4, {player.sixes}×6</div>
                                                        </div>
                                                        <div className="text-right">
                                                            <div className="font-bold">{player.sr}</div>
                                                            <div className="text-xs text-muted-foreground">SR</div>
                                                        </div>
                                                    </div>
                                                ))}
                                            </div>
                                        </div>
                                    </div>
                                </CardContent>
                            </Card>
                        </motion.div>
                    )}

                    {activeTab === 'commentary' && (
                        <motion.div
                            key="commentary"
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -20 }}
                            className="grid gap-6 md:grid-cols-3"
                        >
                            <div className="md:col-span-2 space-y-4">
                                <div className="flex items-center justify-between mb-4">
                                    <h3 className="text-lg font-semibold flex items-center gap-2">
                                        <Zap className="h-5 w-5 text-yellow-500" />
                                        Live Commentary
                                    </h3>
                                    {match.status === 'live' && (
                                        <span className="text-xs bg-red-500/20 text-red-400 px-2 py-1 rounded-full flex items-center gap-1">
                                            <span className="relative flex h-2 w-2">
                                                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
                                                <span className="relative inline-flex rounded-full h-2 w-2 bg-red-500"></span>
                                            </span>
                                            LIVE
                                        </span>
                                    )}
                                </div>
                                <div className="space-y-3 max-h-[600px] overflow-y-auto">
                                    <AnimatePresence>
                                        {commentary.map((c) => (
                                            <motion.div
                                                key={c.id}
                                                initial={{ opacity: 0, x: -20 }}
                                                animate={{ opacity: 1, x: 0 }}
                                                exit={{ opacity: 0, x: 20 }}
                                                className={cn(
                                                    "flex gap-4 p-4 rounded-lg border transition-all",
                                                    c.type === 'six' ? "bg-red-500/10 border-red-500/30" :
                                                    c.type === 'four' ? "bg-blue-500/10 border-blue-500/30" :
                                                    c.type === 'wicket' ? "bg-orange-500/10 border-orange-500/30" :
                                                    "bg-white/5 border-white/10"
                                                )}
                                            >
                                                <div className="flex-shrink-0">
                                                    <div className={cn(
                                                        "h-12 w-12 rounded-full flex items-center justify-center font-bold text-lg",
                                                        c.type === 'six' ? "bg-red-500/20 text-red-400" :
                                                        c.type === 'four' ? "bg-blue-500/20 text-blue-400" :
                                                        c.type === 'wicket' ? "bg-orange-500/20 text-orange-400" :
                                                        "bg-white/10 text-white"
                                                    )}>
                                                        {c.ball}
                                                    </div>
                                                </div>
                                                <div className="flex-1">
                                                    <div className="font-semibold mb-1 flex items-center gap-2 flex-wrap">
                                                        {c.type === 'four' && <span className="bg-blue-600 px-2 py-0.5 rounded text-xs text-white font-bold">FOUR</span>}
                                                        {c.type === 'six' && <span className="bg-red-600 px-2 py-0.5 rounded text-xs text-white font-bold">SIX</span>}
                                                        {c.type === 'wicket' && <span className="bg-orange-600 px-2 py-0.5 rounded text-xs text-white font-bold">WICKET</span>}
                                                        {c.runs > 0 && c.type !== 'four' && c.type !== 'six' && (
                                                            <span className="bg-green-600 px-2 py-0.5 rounded text-xs text-white font-bold">{c.runs} RUN{c.runs > 1 ? 'S' : ''}</span>
                                                        )}
                                                    </div>
                                                    <p className="text-muted-foreground leading-relaxed">{c.commentary}</p>
                                                    <p className="text-xs text-muted-foreground/70 mt-1">
                                                        {c.timestamp.toLocaleTimeString()}
                                                    </p>
                                                </div>
                                            </motion.div>
                                        ))}
                                    </AnimatePresence>
                                </div>
                            </div>
                            <div className="space-y-4">
                                <Card className="bg-gradient-to-br from-indigo-900/40 to-purple-900/40 border-indigo-500/30 backdrop-blur-sm">
                                    <CardHeader className="pb-2">
                                        <CardTitle className="text-sm font-medium text-indigo-300 flex items-center gap-2">
                                            <Brain className="h-4 w-4" />
                                            AI Insights (CricBot)
                                        </CardTitle>
                                    </CardHeader>
                                    <CardContent className="space-y-4">
                                        <AnimatePresence>
                                            {aiInsights.map((insight) => (
                                                <motion.div
                                                    key={insight.id}
                                                    initial={{ opacity: 0, y: 10 }}
                                                    animate={{ opacity: 1, y: 0 }}
                                                    exit={{ opacity: 0, y: -10 }}
                                                    className="flex items-start gap-3"
                                                >
                                                    <div className="h-8 w-8 rounded-full bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center text-xs flex-shrink-0">
                                                        🤖
                                                    </div>
                                                    <div className="flex-1">
                                                        <div className="bg-white/10 p-3 rounded-tr-xl rounded-br-xl rounded-bl-xl">
                                                            <div className="text-xs font-semibold text-indigo-300 mb-1">{insight.title}</div>
                                                            <div className="text-sm text-white/90">{insight.content}</div>
                                                            {insight.confidence && (
                                                                <div className="mt-2 flex items-center gap-2">
                                                                    <div className="flex-1 h-1.5 bg-white/10 rounded-full overflow-hidden">
                                                                        <div 
                                                                            className="h-full bg-gradient-to-r from-indigo-400 to-purple-400 rounded-full"
                                                                            style={{ width: `${insight.confidence}%` }}
                                                                        />
                                                                    </div>
                                                                    <span className="text-xs text-indigo-300">{insight.confidence}%</span>
                                                                </div>
                                                            )}
                                                        </div>
                                                    </div>
                                                </motion.div>
                                            ))}
                                        </AnimatePresence>
                                    </CardContent>
                                </Card>
                            </div>
                        </motion.div>
                    )}

                    {activeTab === 'ai-stats' && (
                        <motion.div
                            key="ai-stats"
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -20 }}
                            className="space-y-6"
                        >
                            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                                {/* Win Probability */}
                                <Card className="bg-gradient-to-br from-green-900/40 to-emerald-900/40 border-green-500/30 backdrop-blur-sm">
                                    <CardHeader>
                                        <CardTitle className="text-sm font-medium text-green-300 flex items-center gap-2">
                                            <Target className="h-4 w-4" />
                                            Win Probability
                                        </CardTitle>
                                    </CardHeader>
                                    <CardContent>
                                        <div className="space-y-4">
                                            <div>
                                                <div className="flex justify-between mb-2">
                                                    <span className="text-sm text-green-200">Royal Strikers</span>
                                                    <span className="text-lg font-bold text-green-300">68%</span>
                                                </div>
                                                <div className="h-3 bg-white/10 rounded-full overflow-hidden">
                                                    <motion.div
                                                        initial={{ width: 0 }}
                                                        animate={{ width: '68%' }}
                                                        transition={{ duration: 1 }}
                                                        className="h-full bg-gradient-to-r from-green-400 to-emerald-400 rounded-full"
                                                    />
                                                </div>
                                            </div>
                                            <div>
                                                <div className="flex justify-between mb-2">
                                                    <span className="text-sm text-gray-300">{match.opponent}</span>
                                                    <span className="text-lg font-bold text-gray-300">32%</span>
                                                </div>
                                                <div className="h-3 bg-white/10 rounded-full overflow-hidden">
                                                    <motion.div
                                                        initial={{ width: 0 }}
                                                        animate={{ width: '32%' }}
                                                        transition={{ duration: 1 }}
                                                        className="h-full bg-gradient-to-r from-gray-400 to-gray-500 rounded-full"
                                                    />
                                                </div>
                                            </div>
                                        </div>
                                    </CardContent>
                                </Card>

                                {/* Run Rate Prediction */}
                                <Card className="bg-gradient-to-br from-blue-900/40 to-cyan-900/40 border-blue-500/30 backdrop-blur-sm">
                                    <CardHeader>
                                        <CardTitle className="text-sm font-medium text-blue-300 flex items-center gap-2">
                                            <TrendingUp className="h-4 w-4" />
                                            Run Rate Analysis
                                        </CardTitle>
                                    </CardHeader>
                                    <CardContent className="space-y-3">
                                        <div className="flex justify-between">
                                            <span className="text-sm text-blue-200">Current RR</span>
                                            <span className="font-bold text-blue-300">8.5</span>
                                        </div>
                                        <div className="flex justify-between">
                                            <span className="text-sm text-blue-200">Required RR</span>
                                            <span className="font-bold text-orange-300">12.0</span>
                                        </div>
                                        <div className="flex justify-between">
                                            <span className="text-sm text-blue-200">Predicted Final Score</span>
                                            <span className="font-bold text-blue-300">175-185</span>
                                        </div>
                                    </CardContent>
                                </Card>

                                {/* Key Moments */}
                                <Card className="bg-gradient-to-br from-purple-900/40 to-pink-900/40 border-purple-500/30 backdrop-blur-sm">
                                    <CardHeader>
                                        <CardTitle className="text-sm font-medium text-purple-300 flex items-center gap-2">
                                            <Activity className="h-4 w-4" />
                                            Key Moments
                                        </CardTitle>
                                    </CardHeader>
                                    <CardContent className="space-y-2">
                                        <div className="text-sm">
                                            <div className="text-purple-200 font-medium">Powerplay: 45/1</div>
                                            <div className="text-xs text-purple-300/70">Strong start</div>
                                        </div>
                                        <div className="text-sm">
                                            <div className="text-purple-200 font-medium">Middle Overs: 67/1</div>
                                            <div className="text-xs text-purple-300/70">Steady progress</div>
                                        </div>
                                        <div className="text-sm">
                                            <div className="text-purple-200 font-medium">Death Overs: 30/1</div>
                                            <div className="text-xs text-purple-300/70">Accelerating</div>
                                        </div>
                                    </CardContent>
                                </Card>
                            </div>

                            {/* AI Predictions */}
                            <Card className="bg-gradient-to-br from-indigo-900/40 to-purple-900/40 border-indigo-500/30 backdrop-blur-sm">
                                <CardHeader>
                                    <CardTitle className="text-sm font-medium text-indigo-300 flex items-center gap-2">
                                        <Brain className="h-4 w-4" />
                                        AI Predictions & Insights
                                    </CardTitle>
                                </CardHeader>
                                <CardContent className="space-y-4">
                                    {[
                                        { title: 'Next 5 Overs Prediction', content: 'Expected runs: 42-48. High probability of 2-3 boundaries. Bowler fatigue detected.', confidence: 82 },
                                        { title: 'Player Performance Forecast', content: 'Current batsman likely to score 15-20 more runs. Strong against spin, weak against pace.', confidence: 75 },
                                        { title: 'Strategic Recommendation', content: 'Consider bringing in spinner. Current batsman has 40% lower strike rate against spin in last 10 matches.', confidence: 88 },
                                    ].map((pred, i) => (
                                        <div key={i} className="bg-white/10 p-4 rounded-lg border border-white/10">
                                            <div className="flex items-start justify-between mb-2">
                                                <div className="text-sm font-semibold text-indigo-200">{pred.title}</div>
                                                <span className="text-xs bg-indigo-500/30 text-indigo-200 px-2 py-1 rounded">{pred.confidence}%</span>
                                            </div>
                                            <p className="text-sm text-white/80">{pred.content}</p>
                                        </div>
                                    ))}
                                </CardContent>
                            </Card>

                            {/* Performance Metrics */}
                            <div className="grid gap-6 md:grid-cols-2">
                                <Card className="bg-card/60 backdrop-blur-sm border-white/20">
                                    <CardHeader>
                                        <CardTitle className="text-sm font-medium flex items-center gap-2">
                                            <BarChart3 className="h-4 w-4" />
                                            Batting Performance
                                        </CardTitle>
                                    </CardHeader>
                                    <CardContent className="space-y-3">
                                        <div className="flex justify-between items-center">
                                            <span className="text-sm text-muted-foreground">Boundary Rate</span>
                                            <span className="font-bold">18.2%</span>
                                        </div>
                                        <div className="flex justify-between items-center">
                                            <span className="text-sm text-muted-foreground">Dot Ball %</span>
                                            <span className="font-bold">28.5%</span>
                                        </div>
                                        <div className="flex justify-between items-center">
                                            <span className="text-sm text-muted-foreground">Partnership Runs</span>
                                            <span className="font-bold">83</span>
                                        </div>
                                    </CardContent>
                                </Card>

                                <Card className="bg-card/60 backdrop-blur-sm border-white/20">
                                    <CardHeader>
                                        <CardTitle className="text-sm font-medium flex items-center gap-2">
                                            <BarChart3 className="h-4 w-4" />
                                            Bowling Performance
                                        </CardTitle>
                                    </CardHeader>
                                    <CardContent className="space-y-3">
                                        <div className="flex justify-between items-center">
                                            <span className="text-sm text-muted-foreground">Economy Rate</span>
                                            <span className="font-bold">8.5</span>
                                        </div>
                                        <div className="flex justify-between items-center">
                                            <span className="text-sm text-muted-foreground">Wickets Taken</span>
                                            <span className="font-bold">3</span>
                                        </div>
                                        <div className="flex justify-between items-center">
                                            <span className="text-sm text-muted-foreground">Dot Balls</span>
                                            <span className="font-bold">24</span>
                                        </div>
                                    </CardContent>
                                </Card>
                            </div>
                        </motion.div>
                    )}
                </AnimatePresence>
            </div>
        </div>
    )
}
