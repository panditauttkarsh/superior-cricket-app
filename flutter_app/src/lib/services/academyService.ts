/**
 * Academy Service
 * Handles academy management, training programs, attendance, and health metrics
 */

import { 
    Academy, AcademyStudent, TrainingProgram, TrainingSession, 
    AttendanceRecord, HealthMetric, VideoAnalysis, AcademyStats 
} from '@/types/academy'

// Mock academy data
const MOCK_ACADEMIES: Academy[] = [
    {
        id: '1',
        name: 'Elite Cricket Academy',
        description: 'Premier cricket training academy',
        ownerId: '1',
        ownerName: 'Academy Owner',
        location: 'Mumbai Cricket Ground',
        city: 'Mumbai',
        state: 'Maharashtra',
        contactEmail: 'academy@example.com',
        contactPhone: '+91 98765 43210',
        students: [
            {
                studentId: '1',
                studentName: 'Student 1',
                email: 'student1@example.com',
                phone: '+91 98765 43211',
                dateOfBirth: '2010-05-15',
                joinedDate: new Date('2024-01-15').toISOString(),
                level: 'intermediate',
                status: 'active'
            }
        ],
        coaches: [
            {
                coachId: '1',
                coachName: 'Coach Name',
                specialization: ['Batting', 'Fielding'],
                experience: 10,
                status: 'active'
            }
        ],
        createdAt: new Date('2024-01-01').toISOString(),
        updatedAt: new Date().toISOString()
    }
]

/**
 * Get academy by ID
 */
export async function getAcademy(academyId: string): Promise<Academy | null> {
    await new Promise(resolve => setTimeout(resolve, 300))
    return MOCK_ACADEMIES.find(a => a.id === academyId) || null
}

/**
 * Get academies by owner
 */
export async function getAcademiesByOwner(ownerId: string): Promise<Academy[]> {
    await new Promise(resolve => setTimeout(resolve, 300))
    return MOCK_ACADEMIES.filter(a => a.ownerId === ownerId)
}

/**
 * Create academy
 */
export async function createAcademy(academy: Omit<Academy, 'id' | 'createdAt' | 'updatedAt' | 'students' | 'coaches'>): Promise<Academy> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const newAcademy: Academy = {
        ...academy,
        id: Math.random().toString(36).substr(2, 9),
        students: [],
        coaches: [],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    }
    
    MOCK_ACADEMIES.push(newAcademy)
    return newAcademy
}

/**
 * Get training programs for academy
 */
export async function getTrainingPrograms(academyId: string): Promise<TrainingProgram[]> {
    await new Promise(resolve => setTimeout(resolve, 400))
    
    // Mock programs
    return [
        {
            id: '1',
            academyId,
            name: 'Advanced Batting Techniques',
            description: 'Focus on power hitting and timing',
            coachId: '1',
            coachName: 'Coach Name',
            level: 'advanced',
            schedule: {
                days: ['monday', 'wednesday', 'friday'],
                time: '16:00',
                duration: 120,
                venue: 'Net Practice Area'
            },
            duration: 8,
            maxStudents: 15,
            currentStudents: 12,
            students: ['1', '2'],
            status: 'ongoing',
            startDate: '2024-03-01',
            endDate: '2024-04-26',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        }
    ]
}

/**
 * Create training program
 */
export async function createTrainingProgram(program: Omit<TrainingProgram, 'id' | 'createdAt' | 'updatedAt' | 'currentStudents' | 'students'>): Promise<TrainingProgram> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    return {
        ...program,
        id: Math.random().toString(36).substr(2, 9),
        currentStudents: 0,
        students: [],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    }
}

/**
 * Get training sessions for program
 */
export async function getTrainingSessions(programId: string): Promise<TrainingSession[]> {
    await new Promise(resolve => setTimeout(resolve, 400))
    
    return [
        {
            id: '1',
            programId,
            programName: 'Advanced Batting Techniques',
            date: '2024-03-05',
            time: '16:00',
            venue: 'Net Practice Area',
            coachId: '1',
            coachName: 'Coach Name',
            topic: 'Power Hitting Fundamentals',
            description: 'Focus on generating power through proper technique',
            status: 'completed',
            attendance: [
                {
                    studentId: '1',
                    studentName: 'Student 1',
                    status: 'present',
                    checkInTime: new Date('2024-03-05T16:00:00').toISOString()
                }
            ],
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        }
    ]
}

/**
 * Mark attendance for session
 */
export async function markAttendance(
    sessionId: string,
    attendance: AttendanceRecord[]
): Promise<TrainingSession> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    // In production, update the session in database
    return {
        id: sessionId,
        programId: '1',
        programName: 'Program',
        date: new Date().toISOString(),
        time: '16:00',
        venue: 'Venue',
        coachId: '1',
        coachName: 'Coach',
        topic: 'Topic',
        description: 'Description',
        status: 'completed',
        attendance,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    }
}

/**
 * Get health metrics for student
 */
export async function getHealthMetrics(studentId: string): Promise<HealthMetric[]> {
    await new Promise(resolve => setTimeout(resolve, 400))
    
    return [
        {
            id: '1',
            studentId,
            studentName: 'Student 1',
            date: '2024-03-01',
            weight: 65,
            height: 175,
            bmi: 21.2,
            restingHeartRate: 72,
            bloodPressure: {
                systolic: 120,
                diastolic: 80
            },
            flexibility: 15,
            strength: {
                benchPress: 50,
                squat: 80
            },
            endurance: {
                runDistance: 1600,
                runTime: 420
            },
            recordedBy: 'Coach Name',
            createdAt: new Date().toISOString()
        }
    ]
}

/**
 * Record health metric
 */
export async function recordHealthMetric(metric: Omit<HealthMetric, 'id' | 'createdAt'>): Promise<HealthMetric> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    return {
        ...metric,
        id: Math.random().toString(36).substr(2, 9),
        createdAt: new Date().toISOString()
    }
}

/**
 * Get video analyses for student
 */
export async function getVideoAnalyses(studentId: string): Promise<VideoAnalysis[]> {
    await new Promise(resolve => setTimeout(resolve, 400))
    
    return [
        {
            id: '1',
            studentId,
            studentName: 'Student 1',
            videoUrl: '/videos/batting-analysis-1.mp4',
            thumbnailUrl: '/thumbnails/batting-1.jpg',
            title: 'Batting Technique Analysis',
            description: 'Analysis of forward defense and cover drive',
            analysis: {
                batting: {
                    stance: 'Good',
                    backlift: 'Excellent',
                    followThrough: 'Needs improvement',
                    footwork: 'Good',
                    timing: 'Excellent',
                    power: 'Good',
                    recommendations: [
                        'Work on follow-through extension',
                        'Maintain balance during shot execution'
                    ]
                }
            },
            aiInsights: [
                'Stance is well-balanced',
                'Backlift position is optimal',
                'Follow-through could be more complete'
            ],
            tags: ['batting', 'technique', 'analysis'],
            recordedAt: new Date('2024-03-05').toISOString(),
            analyzedAt: new Date('2024-03-05').toISOString(),
            createdAt: new Date().toISOString()
        }
    ]
}

/**
 * Get academy statistics
 */
export async function getAcademyStats(academyId: string): Promise<AcademyStats | null> {
    await new Promise(resolve => setTimeout(resolve, 400))
    
    return {
        academyId,
        totalStudents: 45,
        activeStudents: 38,
        totalCoaches: 5,
        activePrograms: 8,
        totalSessions: 120,
        averageAttendance: 85,
        upcomingSessions: 12
    }
}

