'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Home, Trophy, Users, User, Settings, Menu, ShoppingBag, Map } from 'lucide-react'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'

const sidebarItems = [
    { icon: Home, label: 'Home', href: '/' },
    { icon: Trophy, label: 'Matches', href: '/matches' },
    { icon: Users, label: 'Teams', href: '/teams' },
    { icon: User, label: 'Players', href: '/players' },
    { icon: ShoppingBag, label: 'Store', href: '/shop' },
    { icon: Map, label: 'Book Grounds', href: '/grounds' },
    { icon: Settings, label: 'Settings', href: '/settings' },
]

export function Sidebar({ className }: { className?: string }) {
    const pathname = usePathname()

    return (
        <div className={cn('pb-12 min-h-screen border-r bg-sidebar', className)}>
            <div className="space-y-4 py-4">
                <div className="px-3 py-2">
                    <div className="mb-2 px-4 text-lg font-semibold tracking-tight flex items-center gap-2 text-sidebar-primary">
                        <Trophy className="h-6 w-6" />
                        <span>Superior Cricket</span>
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
                </div>
            </div>
        </div>
    )
}
