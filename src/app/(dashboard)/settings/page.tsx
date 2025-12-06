import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

export default function SettingsPage() {
    return (
        <div className="space-y-6">
            <h1 className="text-3xl font-bold tracking-tight text-foreground/90">Settings</h1>
            <Card className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl">
                <CardHeader>
                    <CardTitle>App Preferences</CardTitle>
                </CardHeader>
                <CardContent>
                    <p className="text-muted-foreground">Manage your account and application settings here.</p>
                </CardContent>
            </Card>
        </div>
    )
}
