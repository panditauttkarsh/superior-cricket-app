'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Modal } from '@/components/ui/modal'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
    ArrowLeft, Plus, Activity, Heart, Scale,
    TrendingUp, BarChart3, Calendar
} from 'lucide-react'
import { getHealthMetrics, recordHealthMetric } from '@/lib/services/academyService'
import { HealthMetric } from '@/types/academy'

export default function HealthMetricsPage() {
    const params = useParams()
    const router = useRouter()
    const studentId = params.studentId as string
    
    const [metrics, setMetrics] = useState<HealthMetric[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [isRecordModalOpen, setIsRecordModalOpen] = useState(false)
    const [formData, setFormData] = useState({
        weight: '',
        height: '',
        restingHeartRate: '',
        systolic: '',
        diastolic: '',
        flexibility: '',
        benchPress: '',
        squat: '',
        runDistance: '',
        runTime: '',
        notes: ''
    })
    const [isSubmitting, setIsSubmitting] = useState(false)

    useEffect(() => {
        if (studentId) {
            loadMetrics()
        }
    }, [studentId])

    const loadMetrics = async () => {
        setIsLoading(true)
        try {
            const data = await getHealthMetrics(studentId)
            setMetrics(data)
        } catch (error) {
            console.error('Failed to load metrics:', error)
        } finally {
            setIsLoading(false)
        }
    }

    const handleRecordMetric = async () => {
        setIsSubmitting(true)
        try {
            const metric: Omit<HealthMetric, 'id' | 'createdAt'> = {
                studentId,
                studentName: 'Student Name', // In production, get from context
                date: new Date().toISOString().split('T')[0],
                weight: formData.weight ? parseFloat(formData.weight) : undefined,
                height: formData.height ? parseFloat(formData.height) : undefined,
                restingHeartRate: formData.restingHeartRate ? parseInt(formData.restingHeartRate) : undefined,
                bloodPressure: formData.systolic && formData.diastolic ? {
                    systolic: parseInt(formData.systolic),
                    diastolic: parseInt(formData.diastolic)
                } : undefined,
                flexibility: formData.flexibility ? parseFloat(formData.flexibility) : undefined,
                strength: formData.benchPress || formData.squat ? {
                    benchPress: formData.benchPress ? parseFloat(formData.benchPress) : undefined,
                    squat: formData.squat ? parseFloat(formData.squat) : undefined
                } : undefined,
                endurance: formData.runDistance || formData.runTime ? {
                    runDistance: formData.runDistance ? parseFloat(formData.runDistance) : undefined,
                    runTime: formData.runTime ? parseInt(formData.runTime) : undefined
                } : undefined,
                notes: formData.notes || undefined,
                recordedBy: 'Current User' // In production, get from auth
            }
            
            await recordHealthMetric(metric)
            setIsRecordModalOpen(false)
            setFormData({
                weight: '',
                height: '',
                restingHeartRate: '',
                systolic: '',
                diastolic: '',
                flexibility: '',
                benchPress: '',
                squat: '',
                runDistance: '',
                runTime: '',
                notes: ''
            })
            loadMetrics()
        } catch (error) {
            console.error('Failed to record metric:', error)
        } finally {
            setIsSubmitting(false)
        }
    }

    const calculateBMI = (weight: number, height: number) => {
        if (!weight || !height) return null
        const heightInMeters = height / 100
        return (weight / (heightInMeters * heightInMeters)).toFixed(1)
    }

    if (isLoading) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <p className="text-muted-foreground">Loading health metrics...</p>
            </div>
        )
    }

    const latestMetric = metrics[0]

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
                        Health Metrics
                    </h1>
                </div>
                <Button onClick={() => setIsRecordModalOpen(true)}>
                    <Plus className="mr-2 h-4 w-4" />
                    Record Metric
                </Button>
            </div>

            {/* Latest Metrics Overview */}
            {latestMetric && (
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                    {latestMetric.weight && latestMetric.height && (
                        <Card className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                            <CardContent className="p-6">
                                <div className="flex items-center justify-between">
                                    <div>
                                        <p className="text-sm text-muted-foreground mb-1">BMI</p>
                                        <p className="text-3xl font-bold">
                                            {calculateBMI(latestMetric.weight, latestMetric.height) || 'N/A'}
                                        </p>
                                    </div>
                                    <Scale className="h-8 w-8 text-blue-400" />
                                </div>
                            </CardContent>
                        </Card>
                    )}
                    {latestMetric.restingHeartRate && (
                        <Card className="bg-gradient-to-br from-red-500/20 to-red-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                            <CardContent className="p-6">
                                <div className="flex items-center justify-between">
                                    <div>
                                        <p className="text-sm text-muted-foreground mb-1">Heart Rate</p>
                                        <p className="text-3xl font-bold">{latestMetric.restingHeartRate} bpm</p>
                                    </div>
                                    <Heart className="h-8 w-8 text-red-400" />
                                </div>
                            </CardContent>
                        </Card>
                    )}
                    {latestMetric.bloodPressure && (
                        <Card className="bg-gradient-to-br from-purple-500/20 to-purple-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                            <CardContent className="p-6">
                                <div className="flex items-center justify-between">
                                    <div>
                                        <p className="text-sm text-muted-foreground mb-1">Blood Pressure</p>
                                        <p className="text-3xl font-bold">
                                            {latestMetric.bloodPressure.systolic}/{latestMetric.bloodPressure.diastolic}
                                        </p>
                                    </div>
                                    <Activity className="h-8 w-8 text-purple-400" />
                                </div>
                            </CardContent>
                        </Card>
                    )}
                    {latestMetric.flexibility && (
                        <Card className="bg-gradient-to-br from-green-500/20 to-green-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                            <CardContent className="p-6">
                                <div className="flex items-center justify-between">
                                    <div>
                                        <p className="text-sm text-muted-foreground mb-1">Flexibility</p>
                                        <p className="text-3xl font-bold">{latestMetric.flexibility} cm</p>
                                    </div>
                                    <TrendingUp className="h-8 w-8 text-green-400" />
                                </div>
                            </CardContent>
                        </Card>
                    )}
                </div>
            )}

            {/* Metrics History */}
            <Tabs defaultValue="overview" className="space-y-6">
                <TabsList>
                    <TabsTrigger value="overview">Overview</TabsTrigger>
                    <TabsTrigger value="strength">Strength</TabsTrigger>
                    <TabsTrigger value="endurance">Endurance</TabsTrigger>
                </TabsList>

                <TabsContent value="overview" className="space-y-4">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardHeader>
                            <CardTitle>Metrics History</CardTitle>
                        </CardHeader>
                        <CardContent>
                            {metrics.length === 0 ? (
                                <p className="text-muted-foreground text-center py-8">No metrics recorded yet.</p>
                            ) : (
                                <div className="space-y-4">
                                    {metrics.map((metric) => (
                                        <div
                                            key={metric.id}
                                            className="p-4 rounded-lg border border-white/10 bg-card/40"
                                        >
                                            <div className="flex items-center justify-between mb-3">
                                                <div className="flex items-center gap-2">
                                                    <Calendar className="h-4 w-4 text-muted-foreground" />
                                                    <span className="font-semibold">
                                                        {new Date(metric.date).toLocaleDateString()}
                                                    </span>
                                                </div>
                                                <Badge variant="outline">
                                                    Recorded by {metric.recordedBy}
                                                </Badge>
                                            </div>
                                            <div className="grid gap-3 md:grid-cols-3 text-sm">
                                                {metric.weight && (
                                                    <div>
                                                        <span className="text-muted-foreground">Weight: </span>
                                                        <span className="font-medium">{metric.weight} kg</span>
                                                    </div>
                                                )}
                                                {metric.height && (
                                                    <div>
                                                        <span className="text-muted-foreground">Height: </span>
                                                        <span className="font-medium">{metric.height} cm</span>
                                                    </div>
                                                )}
                                                {metric.bmi && (
                                                    <div>
                                                        <span className="text-muted-foreground">BMI: </span>
                                                        <span className="font-medium">{metric.bmi}</span>
                                                    </div>
                                                )}
                                                {metric.restingHeartRate && (
                                                    <div>
                                                        <span className="text-muted-foreground">Heart Rate: </span>
                                                        <span className="font-medium">{metric.restingHeartRate} bpm</span>
                                                    </div>
                                                )}
                                                {metric.bloodPressure && (
                                                    <div>
                                                        <span className="text-muted-foreground">BP: </span>
                                                        <span className="font-medium">
                                                            {metric.bloodPressure.systolic}/{metric.bloodPressure.diastolic}
                                                        </span>
                                                    </div>
                                                )}
                                                {metric.flexibility && (
                                                    <div>
                                                        <span className="text-muted-foreground">Flexibility: </span>
                                                        <span className="font-medium">{metric.flexibility} cm</span>
                                                    </div>
                                                )}
                                            </div>
                                            {metric.notes && (
                                                <div className="mt-3 pt-3 border-t border-white/10">
                                                    <p className="text-sm text-muted-foreground">{metric.notes}</p>
                                                </div>
                                            )}
                                        </div>
                                    ))}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>

                <TabsContent value="strength" className="space-y-4">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardHeader>
                            <CardTitle>Strength Metrics</CardTitle>
                        </CardHeader>
                        <CardContent>
                            {metrics.filter(m => m.strength).length === 0 ? (
                                <p className="text-muted-foreground text-center py-8">No strength metrics recorded.</p>
                            ) : (
                                <div className="space-y-4">
                                    {metrics.filter(m => m.strength).map((metric) => (
                                        <div key={metric.id} className="p-4 rounded-lg border border-white/10 bg-card/40">
                                            <div className="flex items-center justify-between mb-3">
                                                <span className="font-semibold">
                                                    {new Date(metric.date).toLocaleDateString()}
                                                </span>
                                            </div>
                                            <div className="grid gap-3 md:grid-cols-2 text-sm">
                                                {metric.strength?.benchPress && (
                                                    <div>
                                                        <span className="text-muted-foreground">Bench Press: </span>
                                                        <span className="font-medium">{metric.strength.benchPress} kg</span>
                                                    </div>
                                                )}
                                                {metric.strength?.squat && (
                                                    <div>
                                                        <span className="text-muted-foreground">Squat: </span>
                                                        <span className="font-medium">{metric.strength.squat} kg</span>
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>

                <TabsContent value="endurance" className="space-y-4">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardHeader>
                            <CardTitle>Endurance Metrics</CardTitle>
                        </CardHeader>
                        <CardContent>
                            {metrics.filter(m => m.endurance).length === 0 ? (
                                <p className="text-muted-foreground text-center py-8">No endurance metrics recorded.</p>
                            ) : (
                                <div className="space-y-4">
                                    {metrics.filter(m => m.endurance).map((metric) => (
                                        <div key={metric.id} className="p-4 rounded-lg border border-white/10 bg-card/40">
                                            <div className="flex items-center justify-between mb-3">
                                                <span className="font-semibold">
                                                    {new Date(metric.date).toLocaleDateString()}
                                                </span>
                                            </div>
                                            <div className="grid gap-3 md:grid-cols-2 text-sm">
                                                {metric.endurance?.runDistance && (
                                                    <div>
                                                        <span className="text-muted-foreground">Distance: </span>
                                                        <span className="font-medium">{metric.endurance.runDistance} m</span>
                                                    </div>
                                                )}
                                                {metric.endurance?.runTime && (
                                                    <div>
                                                        <span className="text-muted-foreground">Time: </span>
                                                        <span className="font-medium">
                                                            {Math.floor(metric.endurance.runTime / 60)}:{(metric.endurance.runTime % 60).toString().padStart(2, '0')}
                                                        </span>
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>
            </Tabs>

            {/* Record Metric Modal */}
            <Modal
                isOpen={isRecordModalOpen}
                onClose={() => setIsRecordModalOpen(false)}
                title="Record Health Metric"
                description="Record a new health metric for this student"
            >
                <div className="space-y-4">
                    <div className="grid gap-4 md:grid-cols-2">
                        <div className="space-y-2">
                            <Label>Weight (kg)</Label>
                            <Input
                                type="number"
                                value={formData.weight}
                                onChange={(e) => setFormData({ ...formData, weight: e.target.value })}
                                placeholder="65"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Height (cm)</Label>
                            <Input
                                type="number"
                                value={formData.height}
                                onChange={(e) => setFormData({ ...formData, height: e.target.value })}
                                placeholder="175"
                            />
                        </div>
                    </div>
                    <div className="grid gap-4 md:grid-cols-2">
                        <div className="space-y-2">
                            <Label>Resting Heart Rate (bpm)</Label>
                            <Input
                                type="number"
                                value={formData.restingHeartRate}
                                onChange={(e) => setFormData({ ...formData, restingHeartRate: e.target.value })}
                                placeholder="72"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Blood Pressure</Label>
                            <div className="flex gap-2">
                                <Input
                                    type="number"
                                    value={formData.systolic}
                                    onChange={(e) => setFormData({ ...formData, systolic: e.target.value })}
                                    placeholder="Systolic"
                                />
                                <Input
                                    type="number"
                                    value={formData.diastolic}
                                    onChange={(e) => setFormData({ ...formData, diastolic: e.target.value })}
                                    placeholder="Diastolic"
                                />
                            </div>
                        </div>
                    </div>
                    <div className="space-y-2">
                        <Label>Flexibility (cm)</Label>
                        <Input
                            type="number"
                            value={formData.flexibility}
                            onChange={(e) => setFormData({ ...formData, flexibility: e.target.value })}
                            placeholder="15"
                        />
                    </div>
                    <div className="grid gap-4 md:grid-cols-2">
                        <div className="space-y-2">
                            <Label>Bench Press (kg)</Label>
                            <Input
                                type="number"
                                value={formData.benchPress}
                                onChange={(e) => setFormData({ ...formData, benchPress: e.target.value })}
                                placeholder="50"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Squat (kg)</Label>
                            <Input
                                type="number"
                                value={formData.squat}
                                onChange={(e) => setFormData({ ...formData, squat: e.target.value })}
                                placeholder="80"
                            />
                        </div>
                    </div>
                    <div className="grid gap-4 md:grid-cols-2">
                        <div className="space-y-2">
                            <Label>Run Distance (meters)</Label>
                            <Input
                                type="number"
                                value={formData.runDistance}
                                onChange={(e) => setFormData({ ...formData, runDistance: e.target.value })}
                                placeholder="1600"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Run Time (seconds)</Label>
                            <Input
                                type="number"
                                value={formData.runTime}
                                onChange={(e) => setFormData({ ...formData, runTime: e.target.value })}
                                placeholder="420"
                            />
                        </div>
                    </div>
                    <div className="space-y-2">
                        <Label>Notes</Label>
                        <Input
                            value={formData.notes}
                            onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                            placeholder="Additional notes..."
                        />
                    </div>
                    <div className="flex gap-2 pt-4">
                        <Button
                            variant="outline"
                            onClick={() => setIsRecordModalOpen(false)}
                            className="flex-1"
                        >
                            Cancel
                        </Button>
                        <Button
                            onClick={handleRecordMetric}
                            disabled={isSubmitting}
                            className="flex-1"
                        >
                            {isSubmitting ? 'Recording...' : 'Record Metric'}
                        </Button>
                    </div>
                </div>
            </Modal>
        </div>
    )
}

