'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Modal } from '@/components/ui/modal'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { 
    Trophy, Plus, Calendar, Users, MapPin,
    TrendingUp, Award, BarChart3, Clock
} from 'lucide-react'
import { getAllTournaments, createTournament } from '@/lib/services/tournamentService'
import { Tournament } from '@/types/tournament'
import { useAppStore } from '@/lib/store'
import Link from 'next/link'

export default function TournamentPage() {
    const { user } = useAppStore()
    const [tournaments, setTournaments] = useState<Tournament[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [isCreateModalOpen, setIsCreateModalOpen] = useState(false)
    const [formData, setFormData] = useState({
        name: '',
        description: '',
        startDate: '',
        endDate: '',
        registrationDeadline: '',
        format: 'T20' as 'T20' | 'ODI' | 'Test' | 'Custom',
        maxTeams: 8,
        prizePool: '',
        location: ''
    })
    const [isSubmitting, setIsSubmitting] = useState(false)

    useEffect(() => {
        loadTournaments()
    }, [])

    const loadTournaments = async () => {
        setIsLoading(true)
        try {
            const data = await getAllTournaments()
            setTournaments(data)
        } catch (error) {
            console.error('Failed to load tournaments:', error)
        } finally {
            setIsLoading(false)
        }
    }

    const handleCreateTournament = async () => {
        if (!user) return
        
        setIsSubmitting(true)
        try {
            await createTournament({
                ...formData,
                organizerId: user.id,
                organizerName: user.name,
                status: 'upcoming',
                rules: []
            })
            setIsCreateModalOpen(false)
            setFormData({
                name: '',
                description: '',
                startDate: '',
                endDate: '',
                registrationDeadline: '',
                format: 'T20',
                maxTeams: 8,
                prizePool: '',
                location: ''
            })
            loadTournaments()
        } catch (error) {
            console.error('Failed to create tournament:', error)
        } finally {
            setIsSubmitting(false)
        }
    }

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'upcoming':
                return <Badge className="bg-blue-500/20 text-blue-400 border-blue-500/30">Upcoming</Badge>
            case 'registration':
                return <Badge className="bg-green-500/20 text-green-400 border-green-500/30">Registration Open</Badge>
            case 'ongoing':
                return <Badge className="bg-red-500/20 text-red-400 border-red-500/30 animate-pulse">Ongoing</Badge>
            case 'completed':
                return <Badge className="bg-gray-500/20 text-gray-400 border-gray-500/30">Completed</Badge>
            case 'cancelled':
                return <Badge className="bg-red-500/20 text-red-400 border-red-500/30">Cancelled</Badge>
            default:
                return <Badge variant="outline">{status}</Badge>
        }
    }

    if (isLoading) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <p className="text-muted-foreground">Loading tournaments...</p>
            </div>
        )
    }

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight text-foreground/90">
                        Tournaments
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        Create and manage cricket tournaments
                    </p>
                </div>
                <Button 
                    className="shadow-lg shadow-primary/20"
                    onClick={() => setIsCreateModalOpen(true)}
                >
                    <Plus className="mr-2 h-4 w-4" />
                    Create Tournament
                </Button>
            </div>

            {/* Tournaments Grid */}
            {tournaments.length === 0 ? (
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-8 text-center">
                        <Trophy className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                        <p className="text-muted-foreground mb-4">No tournaments found.</p>
                        <Button onClick={() => setIsCreateModalOpen(true)}>
                            <Plus className="mr-2 h-4 w-4" />
                            Create Your First Tournament
                        </Button>
                    </CardContent>
                </Card>
            ) : (
                <div className="grid gap-6 md:grid-cols-2">
                    {tournaments.map((tournament) => (
                        <Card
                            key={tournament.id}
                            className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl hover:shadow-2xl transition-all duration-300 group overflow-hidden"
                        >
                            <CardHeader>
                                <div className="flex items-start justify-between">
                                    <div className="flex-1">
                                        <CardTitle className="flex items-center gap-2 mb-2">
                                            <Trophy className="h-5 w-5 text-primary" />
                                            {tournament.name}
                                        </CardTitle>
                                        {getStatusBadge(tournament.status)}
                                    </div>
                                </div>
                                <p className="text-sm text-muted-foreground mt-2 line-clamp-2">
                                    {tournament.description}
                                </p>
                            </CardHeader>
                            <CardContent className="space-y-4">
                                {/* Tournament Info */}
                                <div className="grid gap-3 text-sm">
                                    <div className="flex items-center gap-2 text-muted-foreground">
                                        <Calendar className="h-4 w-4" />
                                        <span>
                                            {new Date(tournament.startDate).toLocaleDateString()} - {new Date(tournament.endDate).toLocaleDateString()}
                                        </span>
                                    </div>
                                    <div className="flex items-center gap-2 text-muted-foreground">
                                        <MapPin className="h-4 w-4" />
                                        <span>{tournament.location}</span>
                                    </div>
                                    <div className="flex items-center gap-2 text-muted-foreground">
                                        <Users className="h-4 w-4" />
                                        <span>
                                            {tournament.currentTeams}/{tournament.maxTeams} Teams
                                        </span>
                                    </div>
                                    {tournament.prizePool && (
                                        <div className="flex items-center gap-2 text-muted-foreground">
                                            <Award className="h-4 w-4" />
                                            <span>Prize: {tournament.prizePool}</span>
                                        </div>
                                    )}
                                </div>

                                {/* Format Badge */}
                                <div>
                                    <Badge variant="outline">{tournament.format}</Badge>
                                </div>

                                {/* Actions */}
                                <div className="flex gap-2 pt-2 border-t border-white/10">
                                    <Button variant="outline" size="sm" className="flex-1" asChild>
                                        <Link href={`/tournament/${tournament.id}`}>
                                            View Details
                                        </Link>
                                    </Button>
                                    <Button variant="outline" size="sm" className="flex-1" asChild>
                                        <Link href={`/tournament/${tournament.id}/fixtures`}>
                                            <BarChart3 className="mr-2 h-4 w-4" />
                                            Fixtures
                                        </Link>
                                    </Button>
                                </div>
                            </CardContent>
                        </Card>
                    ))}
                </div>
            )}

            {/* Create Tournament Modal */}
            <Modal
                isOpen={isCreateModalOpen}
                onClose={() => setIsCreateModalOpen(false)}
                title="Create New Tournament"
                description="Fill in the details to create a new tournament"
            >
                <div className="space-y-4">
                    <div className="space-y-2">
                        <Label>Tournament Name</Label>
                        <Input
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            placeholder="CricPlay Championship 2024"
                        />
                    </div>
                    <div className="space-y-2">
                        <Label>Description</Label>
                        <Input
                            value={formData.description}
                            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                            placeholder="Tournament description..."
                        />
                    </div>
                    <div className="grid gap-4 md:grid-cols-2">
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
                    <div className="space-y-2">
                        <Label>Registration Deadline</Label>
                        <Input
                            type="date"
                            value={formData.registrationDeadline}
                            onChange={(e) => setFormData({ ...formData, registrationDeadline: e.target.value })}
                        />
                    </div>
                    <div className="grid gap-4 md:grid-cols-2">
                        <div className="space-y-2">
                            <Label>Format</Label>
                            <select
                                value={formData.format}
                                onChange={(e) => setFormData({ ...formData, format: e.target.value as any })}
                                className="w-full px-3 py-2 rounded-md bg-background border border-white/20 focus:outline-none focus:ring-2 focus:ring-primary"
                            >
                                <option value="T20">T20</option>
                                <option value="ODI">ODI</option>
                                <option value="Test">Test</option>
                                <option value="Custom">Custom</option>
                            </select>
                        </div>
                        <div className="space-y-2">
                            <Label>Max Teams</Label>
                            <Input
                                type="number"
                                value={formData.maxTeams}
                                onChange={(e) => setFormData({ ...formData, maxTeams: parseInt(e.target.value) })}
                                min={2}
                            />
                        </div>
                    </div>
                    <div className="grid gap-4 md:grid-cols-2">
                        <div className="space-y-2">
                            <Label>Location</Label>
                            <Input
                                value={formData.location}
                                onChange={(e) => setFormData({ ...formData, location: e.target.value })}
                                placeholder="Mumbai"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Prize Pool (Optional)</Label>
                            <Input
                                value={formData.prizePool}
                                onChange={(e) => setFormData({ ...formData, prizePool: e.target.value })}
                                placeholder="₹1,00,000"
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
                            onClick={handleCreateTournament}
                            disabled={isSubmitting || !formData.name || !formData.startDate}
                            className="flex-1"
                        >
                            {isSubmitting ? 'Creating...' : 'Create Tournament'}
                        </Button>
                    </div>
                </div>
            </Modal>
        </div>
    )
}

