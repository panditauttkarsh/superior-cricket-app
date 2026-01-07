'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Badge } from '@/components/ui/badge'
import { 
    Shield, Users, Trophy, GraduationCap,
    BarChart3, Settings, TrendingUp, Activity
} from 'lucide-react'
import { useAppStore } from '@/lib/store'
import { hasRole } from '@/lib/auth/rbac'

export default function AdminPage() {
    const { user } = useAppStore()
    const [stats, setStats] = useState({
        totalUsers: 1250,
        activeUsers: 980,
        totalMatches: 450,
        totalTournaments: 25,
        totalAcademies: 15
    })

    // Check admin access
    if (!user || !hasRole(user, 'admin')) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-8 text-center">
                        <Shield className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                        <p className="text-muted-foreground">Access denied. Admin privileges required.</p>
                    </CardContent>
                </Card>
            </div>
        )
    }

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight text-foreground/90">
                        Admin Panel
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        System administration and analytics
                    </p>
                </div>
            </div>

            {/* Stats Overview */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-5">
                <Card className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-sm text-muted-foreground mb-1">Total Users</p>
                                <p className="text-3xl font-bold">{stats.totalUsers}</p>
                            </div>
                            <Users className="h-8 w-8 text-blue-400" />
                        </div>
                    </CardContent>
                </Card>
                <Card className="bg-gradient-to-br from-green-500/20 to-green-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-sm text-muted-foreground mb-1">Active Users</p>
                                <p className="text-3xl font-bold">{stats.activeUsers}</p>
                            </div>
                            <Activity className="h-8 w-8 text-green-400" />
                        </div>
                    </CardContent>
                </Card>
                <Card className="bg-gradient-to-br from-purple-500/20 to-purple-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-sm text-muted-foreground mb-1">Matches</p>
                                <p className="text-3xl font-bold">{stats.totalMatches}</p>
                            </div>
                            <Trophy className="h-8 w-8 text-purple-400" />
                        </div>
                    </CardContent>
                </Card>
                <Card className="bg-gradient-to-br from-orange-500/20 to-orange-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-sm text-muted-foreground mb-1">Tournaments</p>
                                <p className="text-3xl font-bold">{stats.totalTournaments}</p>
                            </div>
                            <Trophy className="h-8 w-8 text-orange-400" />
                        </div>
                    </CardContent>
                </Card>
                <Card className="bg-gradient-to-br from-pink-500/20 to-pink-600/20 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-sm text-muted-foreground mb-1">Academies</p>
                                <p className="text-3xl font-bold">{stats.totalAcademies}</p>
                            </div>
                            <GraduationCap className="h-8 w-8 text-pink-400" />
                        </div>
                    </CardContent>
                </Card>
            </div>

            {/* Admin Sections */}
            <Tabs defaultValue="users" className="space-y-6">
                <TabsList>
                    <TabsTrigger value="users">Users</TabsTrigger>
                    <TabsTrigger value="matches">Matches</TabsTrigger>
                    <TabsTrigger value="tournaments">Tournaments</TabsTrigger>
                    <TabsTrigger value="academies">Academies</TabsTrigger>
                    <TabsTrigger value="analytics">Analytics</TabsTrigger>
                </TabsList>

                <TabsContent value="users">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardHeader>
                            <CardTitle>User Management</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-muted-foreground">User management interface coming soon...</p>
                        </CardContent>
                    </Card>
                </TabsContent>

                <TabsContent value="matches">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardHeader>
                            <CardTitle>Match Scheduling</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-muted-foreground">Match scheduling interface coming soon...</p>
                        </CardContent>
                    </Card>
                </TabsContent>

                <TabsContent value="tournaments">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardHeader>
                            <CardTitle>Tournament Administration</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-muted-foreground">Tournament administration interface coming soon...</p>
                        </CardContent>
                    </Card>
                </TabsContent>

                <TabsContent value="academies">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardHeader>
                            <CardTitle>Academy Management</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-muted-foreground">Academy management interface coming soon...</p>
                        </CardContent>
                    </Card>
                </TabsContent>

                <TabsContent value="analytics">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2">
                                <BarChart3 className="h-5 w-5" />
                                Analytics Dashboard
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-muted-foreground">Analytics dashboard coming soon...</p>
                        </CardContent>
                    </Card>
                </TabsContent>
            </Tabs>
        </div>
    )
}

