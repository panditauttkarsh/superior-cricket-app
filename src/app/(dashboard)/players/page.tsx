import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

export default function PlayersPage() {
    return (
        <div className="space-y-6">
            <h1 className="text-3xl font-bold tracking-tight text-foreground/90">Players</h1>
            <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                <CardHeader>
                    <CardTitle>Player Directory</CardTitle>
                </CardHeader>
                <CardContent>
                    <p className="text-muted-foreground">Search for players to add to your team.</p>
                </CardContent>
            </Card>
        </div>
    )
}
