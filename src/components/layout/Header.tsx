'use client'

import { Bell, Search, Menu, User, Settings, LogOut } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { useRouter } from 'next/navigation'

export function Header() {
    const router = useRouter()

    const handleLogout = () => {
        // Clear user data from localStorage
        localStorage.removeItem('superior_user')
        // Redirect to login page
        router.push('/login')
    }
    return (
        <header className="sticky top-0 z-50 w-full border-b bg-background/60 backdrop-blur-md supports-[backdrop-filter]:bg-background/60">
            <div className="flex h-16 items-center pl-0 pr-4 md:pr-6 lg:pr-8">
                <div className="mr-4 hidden md:flex">
                    {/* Breadcrumbs or Title could go here */}
                </div>
                <div className="flex flex-1 items-center justify-between space-x-2 md:justify-end">
                    <div className="w-full flex-1 md:w-auto md:flex-none">
                        <div className="relative">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                placeholder="Search matches, teams..."
                                className="pl-9 md:w-[300px] lg:w-[400px] bg-background/50 border-white/20 focus:bg-background/80 transition-all"
                            />
                        </div>
                    </div>
                    <Button variant="ghost" size="icon" className="hover:bg-white/10">
                        <Bell className="h-5 w-5" />
                        <span className="sr-only">Notifications</span>
                    </Button>

                    <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                            <Button variant="ghost" className="relative h-9 w-9 rounded-full ring-2 ring-white/20 hover:ring-white/40 transition-all">
                                <Avatar className="h-9 w-9">
                                    <AvatarImage src="/avatars/01.png" alt="@user" />
                                    <AvatarFallback className="bg-primary text-primary-foreground font-bold">SC</AvatarFallback>
                                </Avatar>
                            </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent className="w-56" align="end" forceMount>
                            <DropdownMenuLabel className="font-normal">
                                <div className="flex flex-col space-y-1">
                                    <p className="text-sm font-medium leading-none">SCricPlayUser</p>
                                    <p className="text-xs leading-none text-muted-foreground">
                                        user@example.com
                                    </p>
                                </div>
                            </DropdownMenuLabel>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem className="cursor-pointer" onClick={() => router.push('/profile')}>
                                <User className="mr-2 h-4 w-4" />
                                <span>Profile</span>
                            </DropdownMenuItem>
                            <DropdownMenuItem className="cursor-pointer" onClick={() => router.push('/settings')}>
                                <Settings className="mr-2 h-4 w-4" />
                                <span>Settings</span>
                            </DropdownMenuItem>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem className="text-red-500 cursor-pointer" onClick={handleLogout}>
                                <LogOut className="mr-2 h-4 w-4" />
                                <span>Log out</span>
                            </DropdownMenuItem>
                        </DropdownMenuContent>
                    </DropdownMenu>
                </div>
            </div>
        </header>
    )
}
