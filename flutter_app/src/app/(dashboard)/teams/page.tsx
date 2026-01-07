'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Plus, Users, MapPin } from 'lucide-react'
import Image from 'next/image'
import { useAppStore } from '@/lib/store'
import Link from 'next/link'

export default function TeamsPage() {
    const teams = useAppStore((state) => state.teams)

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold tracking-tight text-foreground/90">Teams</h1>
                <Link href="/">
                    <Button className="shadow-lg shadow-primary/20">
                        <Plus className="mr-2 h-4 w-4" />
                        Create Team
                    </Button>
                </Link>
            </div>

            {teams.length === 0 ? (
                <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                    <CardHeader>
                        <CardTitle>Your Teams</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <p className="text-muted-foreground">You haven't joined any teams yet. Go back to Dashboard to create one.</p>
                    </CardContent>
                </Card>
            ) : (
                <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                    {teams.map((team) => (
                        <Card key={team.id} className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl hover:shadow-2xl transition-all duration-300 group overflow-hidden">
                            <div className="relative h-32 bg-gradient-to-r from-primary/20 to-secondary/20">
                                <div className="absolute -bottom-10 left-6 h-20 w-20 rounded-full border-4 border-background bg-white overflow-hidden shadow-lg">
                                    <Image src={team.logo} alt={team.name} fill className="object-cover p-2" />
                                </div>
                            </div>
                            <CardHeader className="pt-12 pb-2">
                                <CardTitle className="text-xl">{team.name}</CardTitle>
                            </CardHeader>
                            <CardContent>
                                <div className="space-y-2 text-sm text-muted-foreground">
                                    <div className="flex items-center">
                                        <MapPin className="mr-2 h-4 w-4 text-primary" />
                                        {team.city}
                                    </div>
                                    <div className="flex items-center">
                                        <Users className="mr-2 h-4 w-4 text-primary" />
                                        {team.players} Players
                                    </div>
                                </div>
                                <Link href={`/teams/${team.id}`}>
                                    <Button variant="outline" className="w-full mt-4 border-primary/20 hover:bg-primary/5 hover:text-primary">
                                        Manage Team
                                    </Button>
                                </Link>
                            </CardContent>
                        </Card>
                    ))}
                </div>
            )}
        </div>
    )
}
