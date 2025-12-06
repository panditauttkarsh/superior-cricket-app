'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Plus, Calendar, Users, Copy, Check, MapPin, Trophy } from 'lucide-react'
import { Modal } from '@/components/ui/modal'
import { cn } from '@/lib/utils'

import { useAppStore } from '@/lib/store'

export function QuickActions() {
    const [activeModal, setActiveModal] = useState<'team' | 'match' | 'invite' | null>(null)
    const [isLoading, setIsLoading] = useState(false)
    const [copied, setCopied] = useState(false)

    // Store Actions
    const addTeam = useAppStore((state) => state.addTeam)
    const addMatch = useAppStore((state) => state.addMatch)

    // Form States
    const [teamName, setTeamName] = useState('')
    const [teamCity, setTeamCity] = useState('')

    const [matchOpponent, setMatchOpponent] = useState('')
    const [matchDate, setMatchDate] = useState('')
    const [matchType, setMatchType] = useState<'T20' | 'ODI' | 'Test'>('T20')

    const resetForms = () => {
        setTeamName('')
        setTeamCity('')
        setMatchOpponent('')
        setMatchDate('')
        setMatchType('T20')
        setIsLoading(false)
    }

    const handleCopy = () => {
        navigator.clipboard.writeText('https://superior-cricket.app/join/team-123')
        setCopied(true)
        setTimeout(() => setCopied(false), 2000)
    }

    const handleCreateTeam = async () => {
        setIsLoading(true)
        // Simulate Network
        await new Promise(resolve => setTimeout(resolve, 800))

        addTeam({
            name: teamName,
            city: teamCity
        })

        setIsLoading(false)
        setActiveModal(null)
        resetForms()
    }

    const handleScheduleMatch = async () => {
        setIsLoading(true)
        // Simulate Network
        await new Promise(resolve => setTimeout(resolve, 800))

        addMatch({
            opponent: matchOpponent,
            date: matchDate,
            type: matchType
        })

        setIsLoading(false)
        setActiveModal(null)
        resetForms()
    }

    return (
        <>
            <Card className="col-span-3 bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                <CardHeader>
                    <CardTitle>Quick Actions</CardTitle>
                </CardHeader>
                <CardContent className="space-y-2">
                    <Button
                        variant="outline"
                        onClick={() => setActiveModal('team')}
                        className="w-full justify-start bg-white/5 hover:bg-white/10 border-white/10 hover:text-primary hover:border-primary/50 transition-all group"
                    >
                        <Users className="mr-2 h-4 w-4 group-hover:scale-110 transition-transform" />
                        Create Team
                    </Button>
                    <Button
                        variant="outline"
                        onClick={() => setActiveModal('match')}
                        className="w-full justify-start bg-white/5 hover:bg-white/10 border-white/10 hover:text-primary hover:border-primary/50 transition-all group"
                    >
                        <Calendar className="mr-2 h-4 w-4 group-hover:scale-110 transition-transform" />
                        Schedule Match
                    </Button>
                    <Button
                        variant="outline"
                        onClick={() => setActiveModal('invite')}
                        className="w-full justify-start bg-white/5 hover:bg-white/10 border-white/10 hover:text-primary hover:border-primary/50 transition-all group"
                    >
                        <Plus className="mr-2 h-4 w-4 group-hover:scale-110 transition-transform" />
                        Invite Players
                    </Button>
                </CardContent>
            </Card>

            {/* CREATE TEAM MODAL */}
            <Modal
                isOpen={activeModal === 'team'}
                onClose={() => setActiveModal(null)}
                title="Create New Team"
                description="Start your journey by creating a team."
            >
                <div className="space-y-4">
                    <div className="space-y-2">
                        <Label>Team Name</Label>
                        <div className="relative">
                            <Trophy className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                            <Input
                                placeholder="e.g. Royal Strikers"
                                className="pl-9"
                                value={teamName}
                                onChange={(e) => setTeamName(e.target.value)}
                            />
                        </div>
                    </div>
                    <div className="space-y-2">
                        <Label>Home City</Label>
                        <div className="relative">
                            <MapPin className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                            <Input
                                placeholder="e.g. Mumbai"
                                className="pl-9"
                                value={teamCity}
                                onChange={(e) => setTeamCity(e.target.value)}
                            />
                        </div>
                    </div>
                    <div className="pt-4 flex justify-end gap-2">
                        <Button variant="ghost" onClick={() => setActiveModal(null)}>Cancel</Button>
                        <Button onClick={handleCreateTeam} disabled={!teamName || isLoading}>
                            {isLoading ? 'Creating...' : 'Create Team'}
                        </Button>
                    </div>
                </div>
            </Modal>

            {/* SCHEDULE MATCH MODAL */}
            <Modal
                isOpen={activeModal === 'match'}
                onClose={() => setActiveModal(null)}
                title="Schedule Match"
                description="Set up an upcoming fixture."
            >
                <div className="space-y-4">
                    <div className="space-y-2">
                        <Label>Opponent Team</Label>
                        <Input
                            placeholder="Enter opponent name"
                            value={matchOpponent}
                            onChange={(e) => setMatchOpponent(e.target.value)}
                        />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <Label>Date</Label>
                            <Input
                                type="date"
                                value={matchDate}
                                onChange={(e) => setMatchDate(e.target.value)}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Match Type</Label>
                            <select
                                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                                value={matchType}
                                onChange={(e: any) => setMatchType(e.target.value)}
                            >
                                <option>T20</option>
                                <option>ODI</option>
                                <option>Test</option>
                                <option>The Hundred</option>
                            </select>
                        </div>
                    </div>
                    <div className="pt-4 flex justify-end gap-2">
                        <Button variant="ghost" onClick={() => setActiveModal(null)}>Cancel</Button>
                        <Button onClick={handleScheduleMatch} disabled={!matchOpponent || !matchDate || isLoading}>
                            {isLoading ? 'Scheduling...' : 'Schedule Match'}
                        </Button>
                    </div>
                </div>
            </Modal>

            {/* INVITE MODAL */}
            <Modal
                isOpen={activeModal === 'invite'}
                onClose={() => setActiveModal(null)}
                title="Invite Players"
                description="Share this link to add players to your roster."
            >
                <div className="space-y-4">
                    <div className="flex items-center space-x-2">
                        <div className="grid flex-1 gap-2">
                            <Label htmlFor="link" className="sr-only">
                                Link
                            </Label>
                            <Input
                                id="link"
                                defaultValue="https://superior-cricket.app/join/team-123"
                                readOnly
                                className="bg-muted"
                            />
                        </div>
                        <Button size="sm" className="px-3" onClick={handleCopy}>
                            {copied ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                            <span className="sr-only">Copy</span>
                        </Button>
                    </div>
                    <div className="text-center">
                        <p className="text-sm text-muted-foreground">or share via</p>
                        <div className="flex justify-center gap-4 mt-2">
                            <Button variant="outline" size="icon" className="rounded-full text-green-600 hover:text-green-700 hover:bg-green-50">
                                {/* Whatsapp Icon Mock */}
                                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><path d="M16.5 16s-1.5-2-4-2-4 2-4 2" /><path d="M9 10h.01" /><path d="M15 10h.01" /></svg>
                            </Button>
                            <Button variant="outline" size="icon" className="rounded-full text-blue-500 hover:text-blue-600 hover:bg-blue-50">
                                {/* Message Icon Mock */}
                                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /></svg>
                            </Button>
                        </div>
                    </div>
                </div>
            </Modal>
        </>
    )
}
