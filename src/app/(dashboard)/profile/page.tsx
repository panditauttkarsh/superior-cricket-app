'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { User, Mail, Phone, MapPin, Calendar, Trophy, Edit } from 'lucide-react'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'

export default function ProfilePage() {
    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold tracking-tight text-foreground/90">Profile</h1>
                <Button variant="outline">
                    <Edit className="mr-2 h-4 w-4" />
                    Edit Profile
                </Button>
            </div>

            <div className="grid gap-6 md:grid-cols-3">
                <div className="md:col-span-1">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardContent className="p-6 flex flex-col items-center">
                            <Avatar className="h-24 w-24 mb-4">
                                <AvatarImage src="/avatars/01.png" alt="User" />
                                <AvatarFallback className="bg-primary text-primary-foreground text-2xl font-bold">SC</AvatarFallback>
                            </Avatar>
                            <h2 className="text-xl font-bold mb-1">SCricPlayUser</h2>
                            <p className="text-sm text-muted-foreground mb-4">user@example.com</p>
                            <div className="w-full space-y-2">
                                <div className="flex items-center gap-2 text-sm">
                                    <Trophy className="h-4 w-4 text-primary" />
                                    <span className="text-muted-foreground">Member since</span>
                                    <span className="font-medium">2024</span>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </div>

                <div className="md:col-span-2 space-y-6">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardHeader>
                            <CardTitle>Personal Information</CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            <div className="grid gap-4 md:grid-cols-2">
                                <div className="space-y-2">
                                    <Label>Full Name</Label>
                                    <div className="flex items-center gap-2">
                                        <User className="h-4 w-4 text-muted-foreground" />
                                        <Input value="SCricPlayUser" disabled />
                                    </div>
                                </div>
                                <div className="space-y-2">
                                    <Label>Email</Label>
                                    <div className="flex items-center gap-2">
                                        <Mail className="h-4 w-4 text-muted-foreground" />
                                        <Input value="user@example.com" disabled />
                                    </div>
                                </div>
                                <div className="space-y-2">
                                    <Label>Phone</Label>
                                    <div className="flex items-center gap-2">
                                        <Phone className="h-4 w-4 text-muted-foreground" />
                                        <Input value="+91 98765 43210" disabled />
                                    </div>
                                </div>
                                <div className="space-y-2">
                                    <Label>Date of Birth</Label>
                                    <div className="flex items-center gap-2">
                                        <Calendar className="h-4 w-4 text-muted-foreground" />
                                        <Input type="date" value="1990-01-01" disabled />
                                    </div>
                                </div>
                                <div className="space-y-2 md:col-span-2">
                                    <Label>Location</Label>
                                    <div className="flex items-center gap-2">
                                        <MapPin className="h-4 w-4 text-muted-foreground" />
                                        <Input value="Mumbai, Maharashtra" disabled />
                                    </div>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardHeader>
                            <CardTitle>Cricket Profile</CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            <div className="grid gap-4 md:grid-cols-2">
                                <div className="space-y-2">
                                    <Label>Playing Role</Label>
                                    <Input value="All-rounder" disabled />
                                </div>
                                <div className="space-y-2">
                                    <Label>Batting Style</Label>
                                    <Input value="Right-handed" disabled />
                                </div>
                                <div className="space-y-2">
                                    <Label>Bowling Style</Label>
                                    <Input value="Right-arm medium" disabled />
                                </div>
                                <div className="space-y-2">
                                    <Label>Jersey Number</Label>
                                    <Input value="7" disabled />
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    )
}

