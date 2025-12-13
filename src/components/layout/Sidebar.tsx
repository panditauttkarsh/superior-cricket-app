'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Home, Trophy, Users, User, Settings, Menu, ShoppingBag, Map, BarChart3, FileText, Award, Radio, Shield } from 'lucide-react'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import { useAppStore } from '@/lib/store'

const sidebarItems = [
    { icon: Home, label: 'Home', href: '/' },
    { icon: Radio, label: 'Match Center', href: '/match-center' },
    { icon: Trophy, label: 'Matches', href: '/matches' },
    { icon: Users, label: 'Teams', href: '/teams' },
    { icon: User, label: 'Players', href: '/players' },
    { icon: ShoppingBag, label: 'Store', href: '/shop' },
    { icon: Map, label: 'Book Grounds', href: '/grounds' },
    { icon: Settings, label: 'Settings', href: '/settings' },
]

const playerItems = [
    { icon: BarChart3, label: 'Player Dashboard', href: '/player' },
    { icon: FileText, label: 'Scorecards', href: '/player/scorecards' },
    { icon: Award, label: 'Leaderboards', href: '/player/leaderboards' },
]

const coachItems = [
    { icon: Users, label: 'Coach Dashboard', href: '/coach' },
    { icon: User, label: 'Player Monitoring', href: '/coach/players' },
]

const adminItems = [
    { icon: Shield, label: 'Admin Panel', href: '/admin' },
]

export function Sidebar({ className }: { className?: string }) {
    const pathname = usePathname()
    const { user } = useAppStore()

    return (
        <div className={cn('pb-12 min-h-screen border-r bg-sidebar', className)}>
            <div className="space-y-4 py-4">
                <div className="px-3 py-2">
                    <div className="mb-2 px-4 text-lg font-semibold tracking-tight flex items-center gap-2 text-sidebar-primary">
                        <Trophy className="h-6 w-6" />
                        <span>CricPlay</span>
                    </div>
                    <div className="space-y-1">
                        {sidebarItems.map((item) => (
                            <Button
                                key={item.href}
                                variant={pathname === item.href ? 'secondary' : 'ghost'}
                                className={cn(
                                    'w-full justify-start',
                                    pathname === item.href && 'bg-sidebar-accent text-sidebar-accent-foreground'
                                )}
                                asChild
                            >
                                <Link href={item.href}>
                                    <item.icon className="mr-2 h-4 w-4" />
                                    {item.label}
                                </Link>
                            </Button>
                        ))}
                    </div>
                    
                    {/* Player Section */}
                    {(pathname?.startsWith('/player') || pathname === '/') && (
                        <div className="mt-6 px-3">
                            <div className="mb-2 px-4 text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                                Player
                            </div>
                            <div className="space-y-1">
                                {playerItems.map((item) => (
                                    <Button
                                        key={item.href}
                                        variant={pathname === item.href ? 'secondary' : 'ghost'}
                                        className={cn(
                                            'w-full justify-start',
                                            pathname === item.href && 'bg-sidebar-accent text-sidebar-accent-foreground'
                                        )}
                                        asChild
                                    >
                                        <Link href={item.href}>
                                            <item.icon className="mr-2 h-4 w-4" />
                                            {item.label}
                                        </Link>
                                    </Button>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Coach Section */}
                    {(pathname?.startsWith('/coach') || (user?.role === 'coach' && pathname === '/')) && (
                        <div className="mt-6 px-3">
                            <div className="mb-2 px-4 text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                                Coach
                            </div>
                            <div className="space-y-1">
                                {coachItems.map((item) => (
                                    <Button
                                        key={item.href}
                                        variant={pathname === item.href ? 'secondary' : 'ghost'}
                                        className={cn(
                                            'w-full justify-start',
                                            pathname === item.href && 'bg-sidebar-accent text-sidebar-accent-foreground'
                                        )}
                                        asChild
                                    >
                                        <Link href={item.href}>
                                            <item.icon className="mr-2 h-4 w-4" />
                                            {item.label}
                                        </Link>
                                    </Button>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Admin Section */}
                    {user?.role === 'admin' && (
                        <div className="mt-6 px-3">
                            <div className="mb-2 px-4 text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                                Admin
                            </div>
                            <div className="space-y-1">
                                {adminItems.map((item) => (
                                    <Button
                                        key={item.href}
                                        variant={pathname === item.href ? 'secondary' : 'ghost'}
                                        className={cn(
                                            'w-full justify-start',
                                            pathname === item.href && 'bg-sidebar-accent text-sidebar-accent-foreground'
                                        )}
                                        asChild
                                    >
                                        <Link href={item.href}>
                                            <item.icon className="mr-2 h-4 w-4" />
                                            {item.label}
                                        </Link>
                                    </Button>
                                ))}
                            </div>
                        </div>
                    )}
                </div>
            </div>
        </div>
    )
}
