'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Modal } from '@/components/ui/modal'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { 
    Calendar, ArrowLeft, Plus, Users, Clock,
    MapPin, User, CheckCircle, XCircle
} from 'lucide-react'
import { getTrainingPrograms, createTrainingProgram } from '@/lib/services/academyService'
import { TrainingProgram } from '@/types/academy'
import Link from 'next/link'

export default function TrainingProgramsPage() {
    const params = useParams()
    const router = useRouter()
    const academyId = params.id as string
    
    const [programs, setPrograms] = useState<TrainingProgram[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [isCreateModalOpen, setIsCreateModalOpen] = useState(false)
    const [formData, setFormData] = useState({
        name: '',
        description: '',
        coachId: '1',
        coachName: '',
        level: 'beginner' as 'beginner' | 'intermediate' | 'advanced' | 'elite',
        days: [] as string[],
        time: '',
        duration: 120,
        venue: '',
        maxStudents: 15,
        durationWeeks: 8,
        startDate: '',
        endDate: ''
    })
    const [isSubmitting, setIsSubmitting] = useState(false)

    useEffect(() => {
        if (academyId) {
            loadPrograms()
        }
    }, [academyId])

    const loadPrograms = async () => {
        setIsLoading(true)
        try {
            const data = await getTrainingPrograms(academyId)
            setPrograms(data)
        } catch (error) {
            console.error('Failed to load programs:', error)
        } finally {
            setIsLoading(false)
        }
    }

    const handleCreateProgram = async () => {
        setIsSubmitting(true)
        try {
            await createTrainingProgram({
                academyId,
                name: formData.name,
                description: formData.description,
                coachId: formData.coachId,
                coachName: formData.coachName,
                level: formData.level,
                schedule: {
                    days: formData.days as any,
                    time: formData.time,
                    duration: formData.duration,
                    venue: formData.venue
                },
                duration: formData.durationWeeks,
                maxStudents: formData.maxStudents,
                status: 'upcoming',
                startDate: formData.startDate,
                endDate: formData.endDate
            })
            setIsCreateModalOpen(false)
            setFormData({
                name: '',
                description: '',
                coachId: '1',
                coachName: '',
                level: 'beginner',
                days: [],
                time: '',
                duration: 120,
                venue: '',
                maxStudents: 15,
                durationWeeks: 8,
                startDate: '',
                endDate: ''
            })
            loadPrograms()
        } catch (error) {
            console.error('Failed to create program:', error)
        } finally {
            setIsSubmitting(false)
        }
    }

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'upcoming':
                return <Badge className="bg-blue-500/20 text-blue-400 border-blue-500/30">Upcoming</Badge>
            case 'ongoing':
                return <Badge className="bg-green-500/20 text-green-400 border-green-500/30">Ongoing</Badge>
            case 'completed':
                return <Badge className="bg-gray-500/20 text-gray-400 border-gray-500/30">Completed</Badge>
            case 'cancelled':
                return <Badge className="bg-red-500/20 text-red-400 border-red-500/30">Cancelled</Badge>
            default:
                return <Badge variant="outline">{status}</Badge>
        }
    }

    const getLevelBadge = (level: string) => {
        const colors = {
            beginner: 'bg-green-500/20 text-green-400 border-green-500/30',
            intermediate: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
            advanced: 'bg-purple-500/20 text-purple-400 border-purple-500/30',
            elite: 'bg-orange-500/20 text-orange-400 border-orange-500/30'
        }
        return <Badge className={colors[level as keyof typeof colors] || ''}>{level}</Badge>
    }

    if (isLoading) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <p className="text-muted-foreground">Loading programs...</p>
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
                        Training Programs
                    </h1>
                </div>
                <Button onClick={() => setIsCreateModalOpen(true)}>
                    <Plus className="mr-2 h-4 w-4" />
                    New Program
                </Button>
            </div>

            {/* Programs List */}
            {programs.length === 0 ? (
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-8 text-center">
                        <Calendar className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                        <p className="text-muted-foreground mb-4">No training programs found.</p>
                        <Button onClick={() => setIsCreateModalOpen(true)}>
                            <Plus className="mr-2 h-4 w-4" />
                            Create First Program
                        </Button>
                    </CardContent>
                </Card>
            ) : (
                <div className="grid gap-6 md:grid-cols-2">
                    {programs.map((program) => (
                        <Card
                            key={program.id}
                            className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl hover:shadow-2xl transition-all duration-300"
                        >
                            <CardHeader>
                                <div className="flex items-start justify-between">
                                    <div className="flex-1">
                                        <CardTitle className="mb-2">{program.name}</CardTitle>
                                        <div className="flex items-center gap-2">
                                            {getStatusBadge(program.status)}
                                            {getLevelBadge(program.level)}
                                        </div>
                                    </div>
                                </div>
                                <p className="text-sm text-muted-foreground mt-2 line-clamp-2">
                                    {program.description}
                                </p>
                            </CardHeader>
                            <CardContent className="space-y-4">
                                {/* Program Info */}
                                <div className="space-y-2 text-sm">
                                    <div className="flex items-center gap-2 text-muted-foreground">
                                        <User className="h-4 w-4" />
                                        <span>Coach: {program.coachName}</span>
                                    </div>
                                    <div className="flex items-center gap-2 text-muted-foreground">
                                        <Calendar className="h-4 w-4" />
                                        <span>
                                            {program.schedule.days.join(', ')} at {program.schedule.time}
                                        </span>
                                    </div>
                                    <div className="flex items-center gap-2 text-muted-foreground">
                                        <Clock className="h-4 w-4" />
                                        <span>{program.schedule.duration} minutes</span>
                                    </div>
                                    <div className="flex items-center gap-2 text-muted-foreground">
                                        <MapPin className="h-4 w-4" />
                                        <span>{program.schedule.venue}</span>
                                    </div>
                                    <div className="flex items-center gap-2 text-muted-foreground">
                                        <Users className="h-4 w-4" />
                                        <span>
                                            {program.currentStudents}/{program.maxStudents} Students
                                        </span>
                                    </div>
                                </div>

                                {/* Actions */}
                                <div className="flex gap-2 pt-2 border-t border-white/10">
                                    <Button variant="outline" size="sm" className="flex-1" asChild>
                                        <Link href={`/academy/${academyId}/programs/${program.id}`}>
                                            View Details
                                        </Link>
                                    </Button>
                                    <Button variant="outline" size="sm" className="flex-1" asChild>
                                        <Link href={`/academy/${academyId}/programs/${program.id}/sessions`}>
                                            Sessions
                                        </Link>
                                    </Button>
                                </div>
                            </CardContent>
                        </Card>
                    ))}
                </div>
            )}

            {/* Create Program Modal */}
            <Modal
                isOpen={isCreateModalOpen}
                onClose={() => setIsCreateModalOpen(false)}
                title="Create Training Program"
                description="Set up a new training program for your academy"
            >
                <div className="space-y-4">
                    <div className="space-y-2">
                        <Label>Program Name</Label>
                        <Input
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            placeholder="Advanced Batting Techniques"
                        />
                    </div>
                    <div className="space-y-2">
                        <Label>Description</Label>
                        <Input
                            value={formData.description}
                            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                            placeholder="Program description..."
                        />
                    </div>
                    <div className="grid gap-4 md:grid-cols-2">
                        <div className="space-y-2">
                            <Label>Level</Label>
                            <select
                                value={formData.level}
                                onChange={(e) => setFormData({ ...formData, level: e.target.value as any })}
                                className="w-full px-3 py-2 rounded-md bg-background border border-white/20"
                            >
                                <option value="beginner">Beginner</option>
                                <option value="intermediate">Intermediate</option>
                                <option value="advanced">Advanced</option>
                                <option value="elite">Elite</option>
                            </select>
                        </div>
                        <div className="space-y-2">
                            <Label>Max Students</Label>
                            <Input
                                type="number"
                                value={formData.maxStudents}
                                onChange={(e) => setFormData({ ...formData, maxStudents: parseInt(e.target.value) })}
                            />
                        </div>
                    </div>
                    <div className="space-y-2">
                        <Label>Training Days</Label>
                        <div className="grid grid-cols-4 gap-2">
                            {['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'].map((day) => (
                                <label key={day} className="flex items-center gap-2">
                                    <input
                                        type="checkbox"
                                        checked={formData.days.includes(day)}
                                        onChange={(e) => {
                                            if (e.target.checked) {
                                                setFormData({ ...formData, days: [...formData.days, day] })
                                            } else {
                                                setFormData({ ...formData, days: formData.days.filter(d => d !== day) })
                                            }
                                        }}
                                    />
                                    <span className="text-sm capitalize">{day.slice(0, 3)}</span>
                                </label>
                            ))}
                        </div>
                    </div>
                    <div className="grid gap-4 md:grid-cols-2">
                        <div className="space-y-2">
                            <Label>Time</Label>
                            <Input
                                type="time"
                                value={formData.time}
                                onChange={(e) => setFormData({ ...formData, time: e.target.value })}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Duration (minutes)</Label>
                            <Input
                                type="number"
                                value={formData.duration}
                                onChange={(e) => setFormData({ ...formData, duration: parseInt(e.target.value) })}
                            />
                        </div>
                    </div>
                    <div className="space-y-2">
                        <Label>Venue</Label>
                        <Input
                            value={formData.venue}
                            onChange={(e) => setFormData({ ...formData, venue: e.target.value })}
                            placeholder="Net Practice Area"
                        />
                    </div>
                    <div className="grid gap-4 md:grid-cols-3">
                        <div className="space-y-2">
                            <Label>Duration (weeks)</Label>
                            <Input
                                type="number"
                                value={formData.durationWeeks}
                                onChange={(e) => setFormData({ ...formData, durationWeeks: parseInt(e.target.value) })}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Start Date</Label>
                            <Input
                                type="date"
                                value={formData.startDate}
                                onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>End Date</Label>
                            <Input
                                type="date"
                                value={formData.endDate}
                                onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
                            />
                        </div>
                    </div>
                    <div className="flex gap-2 pt-4">
                        <Button
                            variant="outline"
                            onClick={() => setIsCreateModalOpen(false)}
                            className="flex-1"
                        >
                            Cancel
                        </Button>
                        <Button
                            onClick={handleCreateProgram}
                            disabled={isSubmitting || !formData.name}
                            className="flex-1"
                        >
                            {isSubmitting ? 'Creating...' : 'Create Program'}
                        </Button>
                    </div>
                </div>
            </Modal>
        </div>
    )
}

