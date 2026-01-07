'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
    ArrowLeft, Play, Video, Brain, CheckCircle,
    AlertCircle, Target, Calendar
} from 'lucide-react'
import { getVideoAnalyses } from '@/lib/services/academyService'
import { VideoAnalysis } from '@/types/academy'

export default function VideoAnalyticsPage() {
    const params = useParams()
    const router = useRouter()
    const studentId = params.studentId as string
    
    const [analyses, setAnalyses] = useState<VideoAnalysis[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [selectedAnalysis, setSelectedAnalysis] = useState<VideoAnalysis | null>(null)

    useEffect(() => {
        if (studentId) {
            loadAnalyses()
        }
    }, [studentId])

    const loadAnalyses = async () => {
        setIsLoading(true)
        try {
            const data = await getVideoAnalyses(studentId)
            setAnalyses(data)
        } catch (error) {
            console.error('Failed to load video analyses:', error)
        } finally {
            setIsLoading(false)
        }
    }

    if (isLoading) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <p className="text-muted-foreground">Loading video analyses...</p>
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
                        Video Analytics
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        AI-powered video analysis and insights
                    </p>
                </div>
                <Button>
                    <Video className="mr-2 h-4 w-4" />
                    Upload Video
                </Button>
            </div>

            {/* Video Analyses List */}
            {analyses.length === 0 ? (
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-8 text-center">
                        <Video className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                        <p className="text-muted-foreground mb-4">No video analyses found.</p>
                        <Button>
                            <Video className="mr-2 h-4 w-4" />
                            Upload First Video
                        </Button>
                    </CardContent>
                </Card>
            ) : (
                <div className="space-y-4">
                    {analyses.map((analysis) => (
                        <Card
                            key={analysis.id}
                            className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl hover:shadow-2xl transition-all duration-300"
                        >
                            <CardHeader>
                                <div className="flex items-start justify-between">
                                    <div className="flex-1">
                                        <CardTitle className="flex items-center gap-2 mb-2">
                                            <Video className="h-5 w-5" />
                                            {analysis.title}
                                        </CardTitle>
                                        <p className="text-sm text-muted-foreground">
                                            {analysis.description}
                                        </p>
                                    </div>
                                </div>
                                <div className="flex items-center gap-2 mt-3">
                                    <Badge variant="outline">
                                        <Calendar className="h-3 w-3 mr-1" />
                                        {new Date(analysis.recordedAt).toLocaleDateString()}
                                    </Badge>
                                    {analysis.analyzedAt && (
                                        <Badge className="bg-green-500/20 text-green-400 border-green-500/30">
                                            <Brain className="h-3 w-3 mr-1" />
                                            Analyzed
                                        </Badge>
                                    )}
                                </div>
                            </CardHeader>
                            <CardContent className="space-y-4">
                                {/* Video Player Placeholder */}
                                <div className="relative aspect-video bg-black rounded-lg overflow-hidden">
                                    {analysis.thumbnailUrl ? (
                                        <img
                                            src={analysis.thumbnailUrl}
                                            alt={analysis.title}
                                            className="w-full h-full object-cover"
                                        />
                                    ) : (
                                        <div className="w-full h-full flex items-center justify-center">
                                            <Play className="h-16 w-16 text-white/50" />
                                        </div>
                                    )}
                                    <div className="absolute inset-0 flex items-center justify-center">
                                        <Button
                                            size="lg"
                                            className="rounded-full w-16 h-16"
                                            onClick={() => setSelectedAnalysis(analysis)}
                                        >
                                            <Play className="h-8 w-8" />
                                        </Button>
                                    </div>
                                </div>

                                {/* Analysis Tabs */}
                                {analysis.analysis && (
                                    <Tabs defaultValue="batting" className="space-y-4">
                                        <TabsList>
                                            {analysis.analysis.batting && (
                                                <TabsTrigger value="batting">Batting</TabsTrigger>
                                            )}
                                            {analysis.analysis.bowling && (
                                                <TabsTrigger value="bowling">Bowling</TabsTrigger>
                                            )}
                                            {analysis.analysis.fielding && (
                                                <TabsTrigger value="fielding">Fielding</TabsTrigger>
                                            )}
                                        </TabsList>

                                        {analysis.analysis.batting && (
                                            <TabsContent value="batting">
                                                <Card className="bg-card/40 border-white/10">
                                                    <CardContent className="p-4 space-y-3">
                                                        <div className="grid gap-2 text-sm">
                                                            <div className="flex justify-between">
                                                                <span className="text-muted-foreground">Stance:</span>
                                                                <span className="font-medium">{analysis.analysis.batting.stance}</span>
                                                            </div>
                                                            <div className="flex justify-between">
                                                                <span className="text-muted-foreground">Backlift:</span>
                                                                <span className="font-medium">{analysis.analysis.batting.backlift}</span>
                                                            </div>
                                                            <div className="flex justify-between">
                                                                <span className="text-muted-foreground">Follow Through:</span>
                                                                <span className="font-medium">{analysis.analysis.batting.followThrough}</span>
                                                            </div>
                                                            <div className="flex justify-between">
                                                                <span className="text-muted-foreground">Footwork:</span>
                                                                <span className="font-medium">{analysis.analysis.batting.footwork}</span>
                                                            </div>
                                                            <div className="flex justify-between">
                                                                <span className="text-muted-foreground">Timing:</span>
                                                                <span className="font-medium">{analysis.analysis.batting.timing}</span>
                                                            </div>
                                                            <div className="flex justify-between">
                                                                <span className="text-muted-foreground">Power:</span>
                                                                <span className="font-medium">{analysis.analysis.batting.power}</span>
                                                            </div>
                                                        </div>
                                                        {analysis.analysis.batting.recommendations.length > 0 && (
                                                            <div className="pt-3 border-t border-white/10">
                                                                <h4 className="text-sm font-semibold mb-2 flex items-center gap-2">
                                                                    <Target className="h-4 w-4" />
                                                                    Recommendations
                                                                </h4>
                                                                <ul className="space-y-1">
                                                                    {analysis.analysis.batting.recommendations.map((rec, i) => (
                                                                        <li key={i} className="text-sm text-muted-foreground flex items-start gap-2">
                                                                            <CheckCircle className="h-4 w-4 text-primary mt-0.5" />
                                                                            <span>{rec}</span>
                                                                        </li>
                                                                    ))}
                                                                </ul>
                                                            </div>
                                                        )}
                                                    </CardContent>
                                                </Card>
                                            </TabsContent>
                                        )}

                                        {analysis.analysis.bowling && (
                                            <TabsContent value="bowling">
                                                <Card className="bg-card/40 border-white/10">
                                                    <CardContent className="p-4 space-y-3">
                                                        <div className="grid gap-2 text-sm">
                                                            <div className="flex justify-between">
                                                                <span className="text-muted-foreground">Run Up:</span>
                                                                <span className="font-medium">{analysis.analysis.bowling.runUp}</span>
                                                            </div>
                                                            <div className="flex justify-between">
                                                                <span className="text-muted-foreground">Action:</span>
                                                                <span className="font-medium">{analysis.analysis.bowling.action}</span>
                                                            </div>
                                                            <div className="flex justify-between">
                                                                <span className="text-muted-foreground">Release:</span>
                                                                <span className="font-medium">{analysis.analysis.bowling.release}</span>
                                                            </div>
                                                            <div className="flex justify-between">
                                                                <span className="text-muted-foreground">Follow Through:</span>
                                                                <span className="font-medium">{analysis.analysis.bowling.followThrough}</span>
                                                            </div>
                                                            <div className="flex justify-between">
                                                                <span className="text-muted-foreground">Accuracy:</span>
                                                                <span className="font-medium">{analysis.analysis.bowling.accuracy}</span>
                                                            </div>
                                                            <div className="flex justify-between">
                                                                <span className="text-muted-foreground">Pace:</span>
                                                                <span className="font-medium">{analysis.analysis.bowling.pace}</span>
                                                            </div>
                                                        </div>
                                                        {analysis.analysis.bowling.recommendations.length > 0 && (
                                                            <div className="pt-3 border-t border-white/10">
                                                                <h4 className="text-sm font-semibold mb-2 flex items-center gap-2">
                                                                    <Target className="h-4 w-4" />
                                                                    Recommendations
                                                                </h4>
                                                                <ul className="space-y-1">
                                                                    {analysis.analysis.bowling.recommendations.map((rec, i) => (
                                                                        <li key={i} className="text-sm text-muted-foreground flex items-start gap-2">
                                                                            <CheckCircle className="h-4 w-4 text-primary mt-0.5" />
                                                                            <span>{rec}</span>
                                                                        </li>
                                                                    ))}
                                                                </ul>
                                                            </div>
                                                        )}
                                                    </CardContent>
                                                </Card>
                                            </TabsContent>
                                        )}

                                        {analysis.analysis.fielding && (
                                            <TabsContent value="fielding">
                                                <Card className="bg-card/40 border-white/10">
                                                    <CardContent className="p-4 space-y-3">
                                                        <div className="grid gap-2 text-sm">
                                                            <div className="flex justify-between">
                                                                <span className="text-muted-foreground">Positioning:</span>
                                                                <span className="font-medium">{analysis.analysis.fielding.positioning}</span>
                                                            </div>
                                                            <div className="flex justify-between">
                                                                <span className="text-muted-foreground">Catching:</span>
                                                                <span className="font-medium">{analysis.analysis.fielding.catching}</span>
                                                            </div>
                                                            <div className="flex justify-between">
                                                                <span className="text-muted-foreground">Throwing:</span>
                                                                <span className="font-medium">{analysis.analysis.fielding.throwing}</span>
                                                            </div>
                                                            <div className="flex justify-between">
                                                                <span className="text-muted-foreground">Agility:</span>
                                                                <span className="font-medium">{analysis.analysis.fielding.agility}</span>
                                                            </div>
                                                        </div>
                                                        {analysis.analysis.fielding.recommendations.length > 0 && (
                                                            <div className="pt-3 border-t border-white/10">
                                                                <h4 className="text-sm font-semibold mb-2 flex items-center gap-2">
                                                                    <Target className="h-4 w-4" />
                                                                    Recommendations
                                                                </h4>
                                                                <ul className="space-y-1">
                                                                    {analysis.analysis.fielding.recommendations.map((rec, i) => (
                                                                        <li key={i} className="text-sm text-muted-foreground flex items-start gap-2">
                                                                            <CheckCircle className="h-4 w-4 text-primary mt-0.5" />
                                                                            <span>{rec}</span>
                                                                        </li>
                                                                    ))}
                                                                </ul>
                                                            </div>
                                                        )}
                                                    </CardContent>
                                                </Card>
                                            </TabsContent>
                                        )}
                                    </Tabs>
                                )}

                                {/* AI Insights */}
                                {analysis.aiInsights && analysis.aiInsights.length > 0 && (
                                    <Card className="bg-gradient-to-br from-purple-900/40 to-pink-900/40 border-purple-500/30 backdrop-blur-sm">
                                        <CardHeader>
                                            <CardTitle className="text-sm font-medium text-purple-300 flex items-center gap-2">
                                                <Brain className="h-4 w-4" />
                                                AI Insights
                                            </CardTitle>
                                        </CardHeader>
                                        <CardContent>
                                            <ul className="space-y-2">
                                                {analysis.aiInsights.map((insight, i) => (
                                                    <li key={i} className="text-sm text-purple-200 flex items-start gap-2">
                                                        <span className="text-purple-400 mt-1">•</span>
                                                        <span>{insight}</span>
                                                    </li>
                                                ))}
                                            </ul>
                                        </CardContent>
                                    </Card>
                                )}

                                {/* Tags */}
                                {analysis.tags.length > 0 && (
                                    <div className="flex flex-wrap gap-2">
                                        {analysis.tags.map((tag, i) => (
                                            <Badge key={i} variant="outline">
                                                {tag}
                                            </Badge>
                                        ))}
                                    </div>
                                )}
                            </CardContent>
                        </Card>
                    ))}
                </div>
            )}
        </div>
    )
}

