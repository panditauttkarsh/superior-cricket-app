'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { User, Mail, Phone, MapPin, Calendar, Trophy, Edit, Save, X } from 'lucide-react'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { useAppStore } from '@/lib/store'
import { updateUserProfile } from '@/lib/services/userService'
import { getStoredToken } from '@/lib/auth/jwt'

export default function ProfilePage() {
    const { user, setAuth } = useAppStore()
    const [isEditing, setIsEditing] = useState(false)
    const [isLoading, setIsLoading] = useState(false)
    const [formData, setFormData] = useState({
        name: user?.name || '',
        email: user?.email || '',
        phone: user?.phone || '',
        avatar: user?.avatar || '',
    })

    useEffect(() => {
        if (user) {
            setFormData({
                name: user.name,
                email: user.email,
                phone: user.phone || '',
                avatar: user.avatar || '',
            })
        }
    }, [user])

    const handleSave = async () => {
        if (!user) return

        setIsLoading(true)
        try {
            const updatedUser = await updateUserProfile(user.id, formData)
            setAuth({
                token: getStoredToken() || '',
                refreshToken: '',
                user: updatedUser,
                expiresAt: Date.now() + (7 * 24 * 60 * 60 * 1000)
            })
            setIsEditing(false)
        } catch (error) {
            console.error('Failed to update profile:', error)
        } finally {
            setIsLoading(false)
        }
    }

    const handleCancel = () => {
        if (user) {
            setFormData({
                name: user.name,
                email: user.email,
                phone: user.phone || '',
                avatar: user.avatar || '',
            })
        }
        setIsEditing(false)
    }

    if (!user) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <p className="text-muted-foreground">Loading profile...</p>
            </div>
        )
    }

    const initials = user.name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold tracking-tight text-foreground/90">Profile</h1>
                {!isEditing ? (
                    <Button variant="outline" onClick={() => setIsEditing(true)}>
                        <Edit className="mr-2 h-4 w-4" />
                        Edit Profile
                    </Button>
                ) : (
                    <div className="flex gap-2">
                        <Button variant="outline" onClick={handleCancel} disabled={isLoading}>
                            <X className="mr-2 h-4 w-4" />
                            Cancel
                        </Button>
                        <Button onClick={handleSave} disabled={isLoading}>
                            <Save className="mr-2 h-4 w-4" />
                            {isLoading ? 'Saving...' : 'Save Changes'}
                        </Button>
                    </div>
                )}
            </div>

            <div className="grid gap-6 md:grid-cols-3">
                <div className="md:col-span-1">
                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardContent className="p-6 flex flex-col items-center">
                            <Avatar className="h-24 w-24 mb-4">
                                <AvatarImage src={formData.avatar || "/avatars/01.png"} alt={user.name} />
                                <AvatarFallback className="bg-primary text-primary-foreground text-2xl font-bold">{initials}</AvatarFallback>
                            </Avatar>
                            {isEditing ? (
                                <div className="w-full space-y-2">
                                    <Label>Avatar URL</Label>
                                    <Input
                                        value={formData.avatar}
                                        onChange={(e) => setFormData({ ...formData, avatar: e.target.value })}
                                        placeholder="https://..."
                                    />
                                </div>
                            ) : (
                                <>
                                    <h2 className="text-xl font-bold mb-1">{user.name}</h2>
                                    <p className="text-sm text-muted-foreground mb-4">{user.email}</p>
                                    <div className="w-full space-y-2">
                                        <div className="flex items-center gap-2 text-sm">
                                            <Trophy className="h-4 w-4 text-primary" />
                                            <span className="text-muted-foreground">Role:</span>
                                            <span className="font-medium capitalize">{user.role}</span>
                                        </div>
                                        <div className="flex items-center gap-2 text-sm">
                                            <Calendar className="h-4 w-4 text-primary" />
                                            <span className="text-muted-foreground">Member since</span>
                                            <span className="font-medium">
                                                {new Date(user.createdAt).getFullYear()}
                                            </span>
                                        </div>
                                    </div>
                                </>
                            )}
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
                                        <Input
                                            value={formData.name}
                                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                            disabled={!isEditing}
                                        />
                                    </div>
                                </div>
                                <div className="space-y-2">
                                    <Label>Email</Label>
                                    <div className="flex items-center gap-2">
                                        <Mail className="h-4 w-4 text-muted-foreground" />
                                        <Input
                                            type="email"
                                            value={formData.email}
                                            onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                            disabled={!isEditing}
                                        />
                                    </div>
                                </div>
                                <div className="space-y-2 md:col-span-2">
                                    <Label>Phone</Label>
                                    <div className="flex items-center gap-2">
                                        <Phone className="h-4 w-4 text-muted-foreground" />
                                        <Input
                                            type="tel"
                                            value={formData.phone}
                                            onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                                            disabled={!isEditing}
                                            placeholder="+91 98765 43210"
                                        />
                                    </div>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                        <CardHeader>
                            <CardTitle>Account Information</CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            <div className="grid gap-4 md:grid-cols-2">
                                <div className="space-y-2">
                                    <Label>User ID</Label>
                                    <Input value={user.id} disabled />
                                </div>
                                <div className="space-y-2">
                                    <Label>Role</Label>
                                    <Input value={user.role} disabled className="capitalize" />
                                </div>
                                <div className="space-y-2">
                                    <Label>Created At</Label>
                                    <Input
                                        value={new Date(user.createdAt).toLocaleDateString()}
                                        disabled
                                    />
                                </div>
                                <div className="space-y-2">
                                    <Label>Last Updated</Label>
                                    <Input
                                        value={new Date(user.updatedAt).toLocaleDateString()}
                                        disabled
                                    />
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    )
}
