'use client'

import { Card, CardContent, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Map, Calendar, MapPin, Star, User } from 'lucide-react'
import Image from 'next/image'

const GROUNDS = [
    {
        id: 1,
        name: 'Wankhede Practice Grid',
        city: 'Mumbai',
        price: '₹2,000/hr',
        rating: 4.9,
        surface: 'Turf',
        image: '/grounds/wankhede.jpg',
        color: 'bg-blue-900'
    },
    {
        id: 2,
        name: 'Shivaji Park Nets',
        city: 'Mumbai',
        price: '₹500/hr',
        rating: 4.5,
        surface: 'Matting',
        image: '/grounds/shivaji.jpg',
        color: 'bg-green-700'
    },
    {
        id: 3,
        name: 'Azad Maidan Pitch 3',
        city: 'Mumbai',
        price: '₹1,200/hr',
        rating: 4.2,
        surface: 'Turf',
        image: '/grounds/azad.jpg',
        color: 'bg-amber-700'
    },
    {
        id: 4,
        name: 'Nehru Stadium Grounds',
        city: 'Pune',
        price: '₹1,500/hr',
        rating: 4.4,
        surface: 'Turf',
        image: '/grounds/nehru.jpg',
        color: 'bg-emerald-800'
    },
    {
        id: 5,
        name: 'Feroz Shah Kotla Annex',
        city: 'Delhi',
        price: '₹2,500/hr',
        rating: 4.7,
        surface: 'Turf',
        image: '/grounds/kotla.jpg',
        color: 'bg-indigo-900'
    },
]

export default function GroundsPage() {
    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold tracking-tight text-foreground/90">Book Grounds</h1>
                <Button variant="outline" className="shadow-lg backdrop-blur bg-background/50">
                    <Map className="mr-2 h-4 w-4" />
                    View on Map
                </Button>
            </div>

            <div className="flex items-center space-x-2 pb-4 overflow-x-auto">
                {['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Pune'].map(city => (
                    <Button key={city} variant="secondary" size="sm" className="rounded-full px-4 hover:bg-primary hover:text-white transition-colors">
                        {city}
                    </Button>
                ))}
                <Button variant="ghost" size="sm" className="rounded-full px-4 text-muted-foreground">More...</Button>
            </div>

            <div className="grid gap-6 md:grid-cols-2">
                {GROUNDS.map((ground) => (
                    <Card key={ground.id} className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl overflow-hidden group hover:shadow-2xl transition-all duration-300">
                        <div className="flex flex-col md:flex-row h-full">
                            <div className={`h-48 md:h-auto md:w-1/3 ${ground.color} flex items-center justify-center relative overflow-hidden`}>
                                <div className="text-4xl text-white/30 transform group-hover:scale-125 transition-transform duration-500 font-black tracking-widest uppercase">
                                    {ground.surface}
                                </div>
                                <div className="absolute top-2 left-2 bg-black/60 text-white px-2 py-1 rounded text-xs font-bold flex items-center">
                                    <Star className="h-3 w-3 fill-current text-yellow-500 mr-1" />
                                    {ground.rating}
                                </div>
                            </div>
                            <div className="flex-1 p-6 flex flex-col justify-between">
                                <div>
                                    <div className="flex justify-between items-start mb-2">
                                        <h3 className="text-xl font-bold">{ground.name}</h3>
                                        <div className="text-primary font-bold">{ground.price}</div>
                                    </div>
                                    <div className="flex items-center text-muted-foreground text-sm mb-4">
                                        <MapPin className="h-4 w-4 mr-1" />
                                        {ground.city} • {ground.surface} Pitch
                                    </div>
                                    <div className="flex items-center gap-2 mb-4">
                                        <div className="flex -space-x-2">
                                            {[1, 2, 3].map(i => (
                                                <div key={i} className="h-6 w-6 rounded-full bg-gray-300 border-2 border-white flex items-center justify-center text-[10px] overflow-hidden">
                                                    <User className="h-4 w-4 text-gray-500" />
                                                </div>
                                            ))}
                                        </div>
                                        <span className="text-xs text-muted-foreground">+12 booked this week</span>
                                    </div>
                                </div>
                                <div className="flex gap-2">
                                    <Button className="flex-1">Book Now</Button>
                                    <Button variant="outline" size="icon">
                                        <Calendar className="h-4 w-4" />
                                    </Button>
                                </div>
                            </div>
                        </div>
                    </Card>
                ))}
            </div>
        </div>
    )
}
