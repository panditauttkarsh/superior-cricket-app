import { Sidebar } from '@/components/layout/Sidebar'
import { Header } from '@/components/layout/Header'
import Image from 'next/image'

export default function DashboardLayout({
    children,
}: {
    children: React.ReactNode
}) {
    return (
        <div className="relative min-h-screen flex flex-col md:flex-row overflow-hidden">
            {/* Background Image */}
            <div className="fixed inset-0 z-0">
                <Image
                    src="/background.png"
                    alt="Cricket Stadium Background"
                    fill
                    className="object-cover"
                    priority
                />
                <div className="absolute inset-0 bg-background/80 backdrop-blur-sm" />
            </div>

            {/* Content */}
            <div className="relative z-10 hidden md:block w-64 flex-shrink-0">
                <Sidebar className="fixed left-0 top-0 bottom-0 w-64 h-full bg-sidebar/60 backdrop-blur-md border-r border-sidebar-border/50" />
            </div>
            <div className="relative z-10 flex-1 flex flex-col md:pl-64">
                <Header />
                <main className="flex-1 p-4 md:p-6 lg:p-8 w-full">
                    {children}
                </main>
            </div>
        </div>
    )
}
