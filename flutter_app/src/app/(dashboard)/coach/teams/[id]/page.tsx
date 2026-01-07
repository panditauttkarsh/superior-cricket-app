'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Modal } from '@/components/ui/modal'
import { 
    Users, UserPlus, UserMinus, Edit, Save,
    AlertCircle, CheckCircle, XCircle
} from 'lucide-react'
import { getTeam, updatePlayerStatus, removePlayerFromTeam } from '@/lib/services/coachService'
import { Team, TeamPlayer } from '@/types/coach'

export default function TeamManagementPage() {
    const params = useParams()
    const router = useRouter()
    const teamId = params.id as string
    
    const [team, setTeam] = useState<Team | null>(null)
    const [isLoading, setIsLoading] = useState(true)
    const [isEditModalOpen, setIsEditModalOpen] = useState(false)
    const [editingPlayer, setEditingPlayer] = useState<TeamPlayer | null>(null)
    const [formData, setFormData] = useState({
        name: '',
        city: '',
        state: ''
    })

    useEffect(() => {
        loadTeam()
    }, [teamId])

    const loadTeam = async () => {
        setIsLoading(true)
        try {
            const data = await getTeam(teamId)
            if (data) {
                setTeam(data)
                setFormData({
                    name: data.name,
                    city: data.city,
                    state: data.state
                })
            }
        } catch (error) {
            console.error('Failed to load team:', error)
        } finally {
            setIsLoading(false)
        }
    }

    const handleStatusChange = async (playerId: string, status: 'active' | 'injured' | 'suspended') => {
        try {
            const updatedTeam = await updatePlayerStatus(teamId, playerId, status)
            setTeam(updatedTeam)
        } catch (error) {
            console.error('Failed to update player status:', error)
        }
    }

    const handleRemovePlayer = async (playerId: string) => {
        if (!confirm('Are you sure you want to remove this player from the team?')) {
            return
        }
        
        try {
            const updatedTeam = await removePlayerFromTeam(teamId, playerId)
            setTeam(updatedTeam)
        } catch (error) {
            console.error('Failed to remove player:', error)
        }
    }

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'active':
                return <Badge className="bg-green-500/20 text-green-400 border-green-500/30">Active</Badge>
            case 'injured':
                return <Badge className="bg-red-500/20 text-red-400 border-red-500/30">Injured</Badge>
            case 'suspended':
                return <Badge className="bg-yellow-500/20 text-yellow-400 border-yellow-500/30">Suspended</Badge>
            default:
                return <Badge variant="outline">{status}</Badge>
        }
    }

    if (isLoading) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <p className="text-muted-foreground">Loading team...</p>
            </div>
        )
    }

    if (!team) {
        return (
            <div className="space-y-6 max-w-6xl w-full mx-auto">
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardContent className="p-8 text-center">
                        <AlertCircle className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                        <p className="text-muted-foreground mb-4">Team not found.</p>
                        <Button onClick={() => router.back()}>Go Back</Button>
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
                    <Button variant="ghost" onClick={() => router.back()} className="mb-2">
                        ← Back
                    </Button>
                    <h1 className="text-3xl font-bold tracking-tight text-foreground/90">
                        {team.name}
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        {team.city}, {team.state}
                    </p>
                </div>
                <Button variant="outline">
                    <Edit className="mr-2 h-4 w-4" />
                    Edit Team
                </Button>
            </div>

            {/* Team Info Card */}
            <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <Users className="h-5 w-5" />
                        Team Information
                    </CardTitle>
                </CardHeader>
                <CardContent>
                    <div className="grid gap-4 md:grid-cols-3">
                        <div>
                            <Label className="text-muted-foreground">Team Name</Label>
                            <p className="font-semibold">{team.name}</p>
                        </div>
                        <div>
                            <Label className="text-muted-foreground">City</Label>
                            <p className="font-semibold">{team.city}</p>
                        </div>
                        <div>
                            <Label className="text-muted-foreground">State</Label>
                            <p className="font-semibold">{team.state}</p>
                        </div>
                    </div>
                </CardContent>
            </Card>

            {/* Players List */}
            <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                <CardHeader>
                    <div className="flex items-center justify-between">
                        <CardTitle className="flex items-center gap-2">
                            <Users className="h-5 w-5" />
                            Players ({team.players.length})
                        </CardTitle>
                        <Button>
                            <UserPlus className="mr-2 h-4 w-4" />
                            Add Player
                        </Button>
                    </div>
                </CardHeader>
                <CardContent>
                    {team.players.length === 0 ? (
                        <div className="text-center py-8">
                            <Users className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                            <p className="text-muted-foreground mb-4">No players in this team.</p>
                            <Button>
                                <UserPlus className="mr-2 h-4 w-4" />
                                Add First Player
                            </Button>
                        </div>
                    ) : (
                        <div className="space-y-3">
                            {team.players.map((player) => (
                                <div
                                    key={player.playerId}
                                    className="flex items-center justify-between p-4 rounded-lg border border-white/10 bg-card/40 hover:bg-card/60 transition-colors"
                                >
                                    <div className="flex items-center gap-4 flex-1">
                                        <div className="flex-shrink-0 w-12 h-12 rounded-full bg-primary/20 flex items-center justify-center">
                                            <span className="font-bold text-primary">#{player.jerseyNumber}</span>
                                        </div>
                                        <div className="flex-1">
                                            <div className="flex items-center gap-2 mb-1">
                                                <p className="font-semibold">{player.playerName}</p>
                                                {getStatusBadge(player.status)}
                                            </div>
                                            <div className="flex items-center gap-4 text-sm text-muted-foreground">
                                                <span className="capitalize">{player.role}</span>
                                                <span>Joined: {new Date(player.joinedAt).toLocaleDateString()}</span>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-2">
                                        <select
                                            value={player.status}
                                            onChange={(e) => handleStatusChange(player.playerId, e.target.value as any)}
                                            className="px-3 py-1.5 text-sm rounded-md bg-background border border-white/20 focus:outline-none focus:ring-2 focus:ring-primary"
                                        >
                                            <option value="active">Active</option>
                                            <option value="injured">Injured</option>
                                            <option value="suspended">Suspended</option>
                                        </select>
                                        <Button
                                            variant="ghost"
                                            size="sm"
                                            onClick={() => handleRemovePlayer(player.playerId)}
                                            className="text-red-400 hover:text-red-300"
                                        >
                                            <UserMinus className="h-4 w-4" />
                                        </Button>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </CardContent>
            </Card>
        </div>
    )
}

