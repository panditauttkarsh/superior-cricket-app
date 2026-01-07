/**
 * Academy-specific types and interfaces
 */

export interface Academy {
    id: string
    name: string
    description: string
    ownerId: string
    ownerName: string
    location: string
    city: string
    state: string
    contactEmail: string
    contactPhone: string
    students: AcademyStudent[]
    coaches: AcademyCoach[]
    createdAt: string
    updatedAt: string
}

export interface AcademyStudent {
    studentId: string
    studentName: string
    email: string
    phone: string
    dateOfBirth: string
    joinedDate: string
    level: 'beginner' | 'intermediate' | 'advanced' | 'elite'
    status: 'active' | 'inactive' | 'graduated'
    avatar?: string
}

export interface AcademyCoach {
    coachId: string
    coachName: string
    specialization: string[]
    experience: number // years
    status: 'active' | 'inactive'
}

export interface TrainingProgram {
    id: string
    academyId: string
    name: string
    description: string
    coachId: string
    coachName: string
    level: 'beginner' | 'intermediate' | 'advanced' | 'elite'
    schedule: TrainingSchedule
    duration: number // weeks
    maxStudents: number
    currentStudents: number
    students: string[] // Student IDs
    status: 'upcoming' | 'ongoing' | 'completed' | 'cancelled'
    startDate: string
    endDate: string
    createdAt: string
    updatedAt: string
}

export interface TrainingSchedule {
    days: ('monday' | 'tuesday' | 'wednesday' | 'thursday' | 'friday' | 'saturday' | 'sunday')[]
    time: string // e.g., "14:00"
    duration: number // minutes
    venue: string
}

export interface TrainingSession {
    id: string
    programId: string
    programName: string
    date: string
    time: string
    venue: string
    coachId: string
    coachName: string
    topic: string
    description: string
    status: 'scheduled' | 'ongoing' | 'completed' | 'cancelled'
    attendance: AttendanceRecord[]
    createdAt: string
    updatedAt: string
}

export interface AttendanceRecord {
    studentId: string
    studentName: string
    status: 'present' | 'absent' | 'late' | 'excused'
    checkInTime?: string
    notes?: string
}

export interface HealthMetric {
    id: string
    studentId: string
    studentName: string
    date: string
    weight?: number // kg
    height?: number // cm
    bmi?: number
    restingHeartRate?: number // bpm
    bloodPressure?: {
        systolic: number
        diastolic: number
    }
    flexibility?: number // cm
    strength?: {
        benchPress?: number // kg
        squat?: number // kg
    }
    endurance?: {
        runDistance?: number // meters
        runTime?: number // seconds
    }
    notes?: string
    recordedBy: string
    createdAt: string
}

export interface VideoAnalysis {
    id: string
    studentId: string
    studentName: string
    sessionId?: string
    videoUrl: string
    thumbnailUrl?: string
    title: string
    description: string
    analysis: {
        batting?: BattingAnalysis
        bowling?: BowlingAnalysis
        fielding?: FieldingAnalysis
    }
    aiInsights?: string[]
    tags: string[]
    recordedAt: string
    analyzedAt?: string
    createdAt: string
}

export interface BattingAnalysis {
    stance: string
    backlift: string
    followThrough: string
    footwork: string
    timing: string
    power: string
    recommendations: string[]
}

export interface BowlingAnalysis {
    runUp: string
    action: string
    release: string
    followThrough: string
    accuracy: string
    pace: string
    recommendations: string[]
}

export interface FieldingAnalysis {
    positioning: string
    catching: string
    throwing: string
    agility: string
    recommendations: string[]
}

export interface AcademyStats {
    academyId: string
    totalStudents: number
    activeStudents: number
    totalCoaches: number
    activePrograms: number
    totalSessions: number
    averageAttendance: number // percentage
    upcomingSessions: number
}

