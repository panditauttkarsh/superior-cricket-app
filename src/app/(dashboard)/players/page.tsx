'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Search, User, MapPin, Trophy, Plus } from 'lucide-react'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'

const PLAYERS = [
    { id: 1, name: 'Rohit Sharma', city: 'Mumbai', role: 'Batsman', rating: 4.8, matches: 45, runs: 1250 },
    { id: 2, name: 'Virat Kohli', city: 'Delhi', role: 'Batsman', rating: 4.9, matches: 52, runs: 1800 },
    { id: 3, name: 'Jasprit Bumrah', city: 'Mumbai', role: 'Bowler', rating: 4.7, matches: 38, wickets: 65 },
    { id: 4, name: 'Ravindra Jadeja', city: 'Gujarat', role: 'All-rounder', rating: 4.6, matches: 42, runs: 890, wickets: 45 },
    { id: 5, name: 'MS Dhoni', city: 'Ranchi', role: 'Wicket-keeper', rating: 4.9, matches: 60, runs: 2100 },
    { id: 6, name: 'KL Rahul', city: 'Bangalore', role: 'Batsman', rating: 4.5, matches: 35, runs: 950 },
]

export default function PlayersPage() {
    const [searchQuery, setSearchQuery] = useState('')

    const filteredPlayers = PLAYERS.filter(player =>
        player.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        player.city.toLowerCase().includes(searchQuery.toLowerCase()) ||
        player.role.toLowerCase().includes(searchQuery.toLowerCase())
    )

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold tracking-tight text-foreground/90">Players Directory</h1>
                <Button>
                    <Plus className="mr-2 h-4 w-4" />
                    Invite Player
                </Button>
            </div>

            <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                <CardContent className="p-4">
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                        <Input
                            placeholder="Search players by name, city, or role..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="pl-10"
                        />
                    </div>
                </CardContent>
            </Card>

            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {filteredPlayers.length === 0 ? (
                    <div className="col-span-full text-center py-12">
                        <p className="text-muted-foreground">No players found matching your search.</p>
                    </div>
                ) : (
                    filteredPlayers.map((player) => (
                        <Card key={player.id} className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl hover:shadow-2xl transition-all duration-300">
                            <CardContent className="p-6">
                                <div className="flex items-start gap-4 mb-4">
                                    <Avatar className="h-16 w-16">
                                        <AvatarImage src={`/avatars/${player.id}.png`} alt={player.name} />
                                        <AvatarFallback className="bg-primary text-primary-foreground text-lg font-bold">
                                            {player.name.split(' ').map(n => n[0]).join('')}
                                        </AvatarFallback>
                                    </Avatar>
                                    <div className="flex-1">
                                        <h3 className="font-bold text-lg">{player.name}</h3>
                                        <div className="flex items-center gap-2 text-sm text-muted-foreground mt-1">
                                            <MapPin className="h-3 w-3" />
                                            {player.city}
                                        </div>
                                    </div>
                                </div>
                                <div className="space-y-2 mb-4">
                                    <div className="flex items-center justify-between">
                                        <span className="text-sm text-muted-foreground">Role</span>
                                        <span className="font-medium">{player.role}</span>
                                    </div>
                                    <div className="flex items-center justify-between">
                                        <span className="text-sm text-muted-foreground">Rating</span>
                                        <div className="flex items-center gap-1">
                                            <Trophy className="h-3 w-3 text-yellow-500" />
                                            <span className="font-medium">{player.rating}</span>
                                        </div>
                                    </div>
                                    <div className="flex items-center justify-between">
                                        <span className="text-sm text-muted-foreground">Matches</span>
                                        <span className="font-medium">{player.matches}</span>
                                    </div>
                                    {player.runs && (
                                        <div className="flex items-center justify-between">
                                            <span className="text-sm text-muted-foreground">Runs</span>
                                            <span className="font-medium">{player.runs}</span>
                                        </div>
                                    )}
                                    {player.wickets && (
                                        <div className="flex items-center justify-between">
                                            <span className="text-sm text-muted-foreground">Wickets</span>
                                            <span className="font-medium">{player.wickets}</span>
                                        </div>
                                    )}
                                </div>
                                <Button variant="outline" className="w-full">
                                    <User className="mr-2 h-4 w-4" />
                                    View Profile
                                </Button>
                            </CardContent>
                        </Card>
                    ))
                )}
            </div>
        </div>
    )
}
