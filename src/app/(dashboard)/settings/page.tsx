'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Bell, Shield, Moon, Globe, Save } from 'lucide-react'

export default function SettingsPage() {
    const [notifications, setNotifications] = useState({
        email: true,
        push: true,
        matchUpdates: true,
        teamInvites: true,
    })
    const [theme, setTheme] = useState('light')
    const [language, setLanguage] = useState('en')

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            <h1 className="text-3xl font-bold tracking-tight text-foreground/90">Settings</h1>

            <div className="grid gap-6 md:grid-cols-2">
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <Bell className="h-5 w-5" />
                            Notifications
                        </CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="flex items-center justify-between">
                            <div>
                                <Label>Email Notifications</Label>
                                <p className="text-sm text-muted-foreground">Receive updates via email</p>
                            </div>
                            <input
                                type="checkbox"
                                checked={notifications.email}
                                onChange={(e) => setNotifications({ ...notifications, email: e.target.checked })}
                                className="h-4 w-4 rounded"
                            />
                        </div>
                        <div className="flex items-center justify-between">
                            <div>
                                <Label>Push Notifications</Label>
                                <p className="text-sm text-muted-foreground">Browser push notifications</p>
                            </div>
                            <input
                                type="checkbox"
                                checked={notifications.push}
                                onChange={(e) => setNotifications({ ...notifications, push: e.target.checked })}
                                className="h-4 w-4 rounded"
                            />
                        </div>
                        <div className="flex items-center justify-between">
                            <div>
                                <Label>Match Updates</Label>
                                <p className="text-sm text-muted-foreground">Live match score updates</p>
                            </div>
                            <input
                                type="checkbox"
                                checked={notifications.matchUpdates}
                                onChange={(e) => setNotifications({ ...notifications, matchUpdates: e.target.checked })}
                                className="h-4 w-4 rounded"
                            />
                        </div>
                        <div className="flex items-center justify-between">
                            <div>
                                <Label>Team Invites</Label>
                                <p className="text-sm text-muted-foreground">Team invitation notifications</p>
                            </div>
                            <input
                                type="checkbox"
                                checked={notifications.teamInvites}
                                onChange={(e) => setNotifications({ ...notifications, teamInvites: e.target.checked })}
                                className="h-4 w-4 rounded"
                            />
                        </div>
                    </CardContent>
                </Card>

                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <Moon className="h-5 w-5" />
                            Appearance
                        </CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="space-y-2">
                            <Label>Theme</Label>
                            <select
                                value={theme}
                                onChange={(e) => setTheme(e.target.value)}
                                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                            >
                                <option value="light">Light</option>
                                <option value="dark">Dark</option>
                                <option value="system">System</option>
                            </select>
                        </div>
                        <div className="space-y-2">
                            <Label>Language</Label>
                            <select
                                value={language}
                                onChange={(e) => setLanguage(e.target.value)}
                                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                            >
                                <option value="en">English</option>
                                <option value="hi">Hindi</option>
                                <option value="mr">Marathi</option>
                            </select>
                        </div>
                    </CardContent>
                </Card>

                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <Shield className="h-5 w-5" />
                            Privacy & Security
                        </CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="space-y-2">
                            <Label>Change Password</Label>
                            <Input type="password" placeholder="Enter new password" />
                        </div>
                        <div className="space-y-2">
                            <Label>Confirm Password</Label>
                            <Input type="password" placeholder="Confirm new password" />
                        </div>
                        <Button variant="outline" className="w-full">Update Password</Button>
                    </CardContent>
                </Card>

                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <Globe className="h-5 w-5" />
                            Account
                        </CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="space-y-2">
                            <Label>Delete Account</Label>
                            <p className="text-sm text-muted-foreground">Permanently delete your account and all data</p>
                            <Button variant="destructive" className="w-full">Delete Account</Button>
                        </div>
                    </CardContent>
                </Card>
            </div>

            <div className="flex justify-end">
                <Button className="shadow-lg shadow-primary/20">
                    <Save className="mr-2 h-4 w-4" />
                    Save Changes
                </Button>
            </div>
        </div>
    )
}
