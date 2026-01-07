'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Modal } from '@/components/ui/modal'
import { 
    Calendar, ArrowLeft, CheckCircle, XCircle, Clock,
    UserCheck, Users, MapPin
} from 'lucide-react'
import { getTrainingSessions, markAttendance } from '@/lib/services/academyService'
import { TrainingSession, AttendanceRecord } from '@/types/academy'

export default function TrainingSessionsPage() {
    const params = useParams()
    const router = useRouter()
    const programId = params.programId as string
    
    const [sessions, setSessions] = useState<TrainingSession[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [selectedSession, setSelectedSession] = useState<TrainingSession | null>(null)
    const [isAttendanceModalOpen, setIsAttendanceModalOpen] = useState(false)
    const [attendance, setAttendance] = useState<AttendanceRecord[]>([])

    useEffect(() => {
        if (programId) {
            loadSessions()
        }
    }, [programId])

    const loadSessions = async () => {
        setIsLoading(true)
        try {
            const data = await getTrainingSessions(programId)
            setSessions(data)
        } catch (error) {
            console.error('Failed to load sessions:', error)
        } finally {
            setIsLoading(false)
        }
    }

    const handleMarkAttendance = async (session: TrainingSession) => {
        setSelectedSession(session)
        setAttendance(session.attendance || [])
        setIsAttendanceModalOpen(true)
    }

    const handleSaveAttendance = async () => {
        if (!selectedSession) return
        
        try {
            await markAttendance(selectedSession.id, attendance)
            setIsAttendanceModalOpen(false)
            loadSessions()
        } catch (error) {
            console.error('Failed to save attendance:', error)
        }
    }

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'scheduled':
                return <Badge className="bg-blue-500/20 text-blue-400 border-blue-500/30">Scheduled</Badge>
            case 'ongoing':
                return <Badge className="bg-green-500/20 text-green-400 border-green-500/30 animate-pulse">Ongoing</Badge>
            case 'completed':
                return <Badge className="bg-gray-500/20 text-gray-400 border-gray-500/30">Completed</Badge>
            case 'cancelled':
                return <Badge className="bg-red-500/20 text-red-400 border-red-500/30">Cancelled</Badge>
            default:
                return <Badge variant="outline">{status}</Badge>
        }
    }

    const getAttendanceStatusBadge = (status: string) => {
        switch (status) {
            case 'present':
                return <Badge className="bg-green-500/20 text-green-400 border-green-500/30">Present</Badge>
            case 'absent':
                return <Badge className="bg-red-500/20 text-red-400 border-red-500/30">Absent</Badge>
            case 'late':
                return <Badge className="bg-yellow-500/20 text-yellow-400 border-yellow-500/30">Late</Badge>
            case 'excused':
                return <Badge className="bg-blue-500/20 text-blue-400 border-blue-500/30">Excused</Badge>
            default:
                return <Badge variant="outline">{status}</Badge>
        }
    }

    if (isLoading) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <p className="text-muted-foreground">Loading sessions...</p>
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
                        Training Sessions
                    </h1>
                </div>
            </div>

            {/* Sessions List */}
            {sessions.length === 0 ? (
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-8 text-center">
                        <Calendar className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                        <p className="text-muted-foreground">No sessions found.</p>
                    </CardContent>
                </Card>
            ) : (
                <div className="space-y-4">
                    {sessions.map((session) => {
                        const presentCount = session.attendance?.filter(a => a.status === 'present').length || 0
                        const totalCount = session.attendance?.length || 0

                        return (
                            <Card
                                key={session.id}
                                className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl hover:shadow-2xl transition-all duration-300"
                            >
                                <CardHeader>
                                    <div className="flex items-center justify-between">
                                        <div>
                                            <CardTitle>{session.topic}</CardTitle>
                                            <div className="flex items-center gap-2 mt-2">
                                                {getStatusBadge(session.status)}
                                            </div>
                                        </div>
                                    </div>
                                    <p className="text-sm text-muted-foreground mt-2">
                                        {session.description}
                                    </p>
                                </CardHeader>
                                <CardContent className="space-y-4">
                                    {/* Session Info */}
                                    <div className="grid gap-3 text-sm md:grid-cols-3">
                                        <div className="flex items-center gap-2 text-muted-foreground">
                                            <Calendar className="h-4 w-4" />
                                            <span>{new Date(session.date).toLocaleDateString()}</span>
                                        </div>
                                        <div className="flex items-center gap-2 text-muted-foreground">
                                            <Clock className="h-4 w-4" />
                                            <span>{session.time}</span>
                                        </div>
                                        <div className="flex items-center gap-2 text-muted-foreground">
                                            <MapPin className="h-4 w-4" />
                                            <span>{session.venue}</span>
                                        </div>
                                    </div>

                                    {/* Attendance Summary */}
                                    {session.attendance && session.attendance.length > 0 && (
                                        <div className="p-4 bg-card/40 rounded-lg border border-white/10">
                                            <div className="flex items-center justify-between mb-3">
                                                <div className="flex items-center gap-2">
                                                    <UserCheck className="h-4 w-4 text-primary" />
                                                    <span className="font-semibold">Attendance</span>
                                                </div>
                                                <span className="text-sm text-muted-foreground">
                                                    {presentCount}/{totalCount} Present
                                                </span>
                                            </div>
                                            <div className="space-y-2">
                                                {session.attendance.map((record) => (
                                                    <div
                                                        key={record.studentId}
                                                        className="flex items-center justify-between text-sm"
                                                    >
                                                        <span>{record.studentName}</span>
                                                        {getAttendanceStatusBadge(record.status)}
                                                    </div>
                                                ))}
                                            </div>
                                        </div>
                                    )}

                                    {/* Actions */}
                                    <div className="flex gap-2 pt-2 border-t border-white/10">
                                        <Button
                                            variant="outline"
                                            size="sm"
                                            className="flex-1"
                                            onClick={() => handleMarkAttendance(session)}
                                        >
                                            <UserCheck className="mr-2 h-4 w-4" />
                                            Mark Attendance
                                        </Button>
                                    </div>
                                </CardContent>
                            </Card>
                        )
                    })}
                </div>
            )}

            {/* Attendance Modal */}
            <Modal
                isOpen={isAttendanceModalOpen}
                onClose={() => setIsAttendanceModalOpen(false)}
                title="Mark Attendance"
                description={`Session: ${selectedSession?.topic}`}
            >
                <div className="space-y-4">
                    {attendance.map((record) => (
                        <div key={record.studentId} className="flex items-center justify-between p-3 bg-card/40 rounded-lg">
                            <span className="font-medium">{record.studentName}</span>
                            <select
                                value={record.status}
                                onChange={(e) => {
                                    setAttendance(attendance.map(a =>
                                        a.studentId === record.studentId
                                            ? { ...a, status: e.target.value as any }
                                            : a
                                    ))
                                }}
                                className="px-3 py-1.5 text-sm rounded-md bg-background border border-white/20"
                            >
                                <option value="present">Present</option>
                                <option value="absent">Absent</option>
                                <option value="late">Late</option>
                                <option value="excused">Excused</option>
                            </select>
                        </div>
                    ))}
                    <div className="flex gap-2 pt-4">
                        <Button
                            variant="outline"
                            onClick={() => setIsAttendanceModalOpen(false)}
                            className="flex-1"
                        >
                            Cancel
                        </Button>
                        <Button
                            onClick={handleSaveAttendance}
                            className="flex-1"
                        >
                            Save Attendance
                        </Button>
                    </div>
                </div>
            </Modal>
        </div>
    )
}

