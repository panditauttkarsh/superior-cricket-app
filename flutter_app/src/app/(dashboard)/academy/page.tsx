'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
    GraduationCap, Plus, Users, UserCheck, 
    Calendar, TrendingUp, Award, BarChart3
} from 'lucide-react'
import { getAcademiesByOwner, getAcademyStats } from '@/lib/services/academyService'
import { Academy, AcademyStats } from '@/types/academy'
import { useAppStore } from '@/lib/store'
import Link from 'next/link'

export default function AcademyPage() {
    const { user } = useAppStore()
    const [academies, setAcademies] = useState<Academy[]>([])
    const [academyStats, setAcademyStats] = useState<Record<string, AcademyStats>>({})
    const [isLoading, setIsLoading] = useState(true)

    useEffect(() => {
        if (user) {
            loadAcademies()
        }
    }, [user])

    const loadAcademies = async () => {
        if (!user) return
        
        setIsLoading(true)
        try {
            const ownerId = user.id
            const data = await getAcademiesByOwner(ownerId)
            setAcademies(data)
            
            // Load stats for each academy
            const stats: Record<string, AcademyStats> = {}
            for (const academy of data) {
                const stat = await getAcademyStats(academy.id)
                if (stat) {
                    stats[academy.id] = stat
                }
            }
            setAcademyStats(stats)
        } catch (error) {
            console.error('Failed to load academies:', error)
        } finally {
            setIsLoading(false)
        }
    }

    if (isLoading) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <p className="text-muted-foreground">Loading academies...</p>
            </div>
        )
    }

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight text-foreground/90">
                        Academy Management
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        Manage your cricket academy and training programs
                    </p>
                </div>
                <Button className="shadow-lg shadow-primary/20">
                    <Plus className="mr-2 h-4 w-4" />
                    New Academy
                </Button>
            </div>

            {/* Quick Stats */}
            {academies.length > 0 && (
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                    <Card className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardContent className="p-6">
                            <div className="flex items-center justify-between">
                                <div>
                                    <p className="text-sm text-muted-foreground mb-1">Total Students</p>
                                    <p className="text-3xl font-bold">
                                        {Object.values(academyStats).reduce((sum, stat) => sum + stat.totalStudents, 0)}
                                    </p>
                                </div>
                                <Users className="h-8 w-8 text-blue-400" />
                            </div>
                        </CardContent>
                    </Card>

                    <Card className="bg-gradient-to-br from-green-500/20 to-green-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardContent className="p-6">
                            <div className="flex items-center justify-between">
                                <div>
                                    <p className="text-sm text-muted-foreground mb-1">Active Programs</p>
                                    <p className="text-3xl font-bold">
                                        {Object.values(academyStats).reduce((sum, stat) => sum + stat.activePrograms, 0)}
                                    </p>
                                </div>
                                <Calendar className="h-8 w-8 text-green-400" />
                            </div>
                        </CardContent>
                    </Card>

                    <Card className="bg-gradient-to-br from-purple-500/20 to-purple-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardContent className="p-6">
                            <div className="flex items-center justify-between">
                                <div>
                                    <p className="text-sm text-muted-foreground mb-1">Avg Attendance</p>
                                    <p className="text-3xl font-bold">
                                        {Object.values(academyStats).length > 0
                                            ? Math.round(
                                                  Object.values(academyStats).reduce(
                                                      (sum, stat) => sum + stat.averageAttendance,
                                                      0
                                                  ) / Object.values(academyStats).length
                                              )
                                            : 0}
                                        %
                                    </p>
                                </div>
                                <UserCheck className="h-8 w-8 text-purple-400" />
                            </div>
                        </CardContent>
                    </Card>

                    <Card className="bg-gradient-to-br from-orange-500/20 to-orange-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardContent className="p-6">
                            <div className="flex items-center justify-between">
                                <div>
                                    <p className="text-sm text-muted-foreground mb-1">Upcoming Sessions</p>
                                    <p className="text-3xl font-bold">
                                        {Object.values(academyStats).reduce((sum, stat) => sum + stat.upcomingSessions, 0)}
                                    </p>
                                </div>
                                <TrendingUp className="h-8 w-8 text-orange-400" />
                            </div>
                        </CardContent>
                    </Card>
                </div>
            )}

            {/* Academies List */}
            {academies.length === 0 ? (
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-8 text-center">
                        <GraduationCap className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                        <p className="text-muted-foreground mb-4">No academies found.</p>
                        <Button>
                            <Plus className="mr-2 h-4 w-4" />
                            Create Your First Academy
                        </Button>
                    </CardContent>
                </Card>
            ) : (
                <div className="grid gap-6 md:grid-cols-2">
                    {academies.map((academy) => {
                        const stats = academyStats[academy.id]
                        const activeStudents = academy.students.filter(s => s.status === 'active').length

                        return (
                            <Card
                                key={academy.id}
                                className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl hover:shadow-2xl transition-all duration-300"
                            >
                                <CardHeader>
                                    <div className="flex items-center justify-between">
                                        <CardTitle className="flex items-center gap-2">
                                            <GraduationCap className="h-5 w-5 text-primary" />
                                            {academy.name}
                                        </CardTitle>
                                        <Button variant="outline" size="sm" asChild>
                                            <Link href={`/academy/${academy.id}`}>
                                                Manage
                                            </Link>
                                        </Button>
                                    </div>
                                    <p className="text-sm text-muted-foreground">
                                        {academy.location}, {academy.city}
                                    </p>
                                </CardHeader>
                                <CardContent className="space-y-4">
                                    {/* Academy Stats */}
                                    {stats && (
                                        <div className="grid grid-cols-3 gap-4">
                                            <div className="text-center">
                                                <p className="text-2xl font-bold">{stats.totalStudents}</p>
                                                <p className="text-xs text-muted-foreground">Students</p>
                                            </div>
                                            <div className="text-center">
                                                <p className="text-2xl font-bold">{stats.activePrograms}</p>
                                                <p className="text-xs text-muted-foreground">Programs</p>
                                            </div>
                                            <div className="text-center">
                                                <p className="text-2xl font-bold">{stats.totalCoaches}</p>
                                                <p className="text-xs text-muted-foreground">Coaches</p>
                                            </div>
                                        </div>
                                    )}

                                    {/* Students Info */}
                                    <div className="space-y-2">
                                        <div className="flex items-center justify-between text-sm">
                                            <span className="text-muted-foreground">Total Students</span>
                                            <span className="font-semibold">{academy.students.length}</span>
                                        </div>
                                        <div className="flex items-center justify-between text-sm">
                                            <span className="text-muted-foreground">Active</span>
                                            <Badge variant="outline" className="bg-green-500/20 text-green-400 border-green-500/30">
                                                {activeStudents}
                                            </Badge>
                                        </div>
                                    </div>

                                    {/* Quick Actions */}
                                    <div className="flex gap-2 pt-2 border-t border-white/10">
                                        <Button variant="outline" size="sm" className="flex-1" asChild>
                                            <Link href={`/academy/${academy.id}/programs`}>
                                                <Calendar className="mr-2 h-4 w-4" />
                                                Programs
                                            </Link>
                                        </Button>
                                        <Button variant="outline" size="sm" className="flex-1" asChild>
                                            <Link href={`/academy/${academy.id}/students`}>
                                                <Users className="mr-2 h-4 w-4" />
                                                Students
                                            </Link>
                                        </Button>
                                    </div>
                                </CardContent>
                            </Card>
                        )
                    })}
                </div>
            )}
        </div>
    )
}

