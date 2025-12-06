'use client'

import { Card, CardContent, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { ShoppingBag, Star, Tag } from 'lucide-react'
import Image from 'next/image'

const PRODUCTS = [
    {
        id: 1,
        name: 'Pro Grade English Willow Bat',
        price: '₹12,499',
        rating: 4.8,
        category: 'Bats',
        image: '/products/bat.png', // We'll just use a placeholder text if image missing
        color: 'bg-emerald-100'
    },
    {
        id: 2,
        name: 'Superior Cricket Helmet',
        price: '₹2,499',
        rating: 4.5,
        category: 'Protection',
        image: '/products/helmet.png',
        color: 'bg-blue-100'
    },
    {
        id: 3,
        name: 'Match Leather Ball (Pack of 6)',
        price: '₹1,899',
        rating: 4.9,
        category: 'Accessories',
        image: '/products/ball.png',
        color: 'bg-red-100'
    },
    {
        id: 4,
        name: 'Team India Jersey (Custom)',
        price: '₹999',
        rating: 4.2,
        category: 'Apparel',
        image: '/products/jersey.png',
        color: 'bg-indigo-100'
    },
    {
        id: 5,
        name: 'Wicket Keeping Gloves',
        price: '₹3,299',
        rating: 4.6,
        category: 'Gloves',
        image: '/products/gloves.png',
        color: 'bg-orange-100'
    },
    {
        id: 6,
        name: 'Used Batting Pads (Good Condition)',
        price: '₹899',
        rating: 4.0,
        category: 'Second Hand',
        image: '/products/pads.png',
        color: 'bg-gray-200'
    }
]

export default function ShopPage() {
    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold tracking-tight text-foreground/90">Store</h1>
                <Button className="shadow-lg shadow-primary/20">
                    <ShoppingBag className="mr-2 h-4 w-4" />
                    Cart (0)
                </Button>
            </div>

            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                {PRODUCTS.map((product) => (
                    <Card key={product.id} className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl overflow-hidden group hover:scale-[1.02] transition-transform duration-300">
                        <div className={`h-48 ${product.color} flex items-center justify-center relative overflow-hidden`}>
                            {/* Placeholder visual if real image fails */}
                            <div className="text-6xl opacity-20 transform group-hover:scale-110 transition-transform duration-500">
                                {product.category === 'Bats' && '🏏'}
                                {product.category === 'Protection' && '⛑️'}
                                {product.category === 'Accessories' && '⚾'}
                                {product.category === 'Apparel' && '👕'}
                                {product.category === 'Gloves' && '🥊'}
                                {product.category === 'Second Hand' && '♻️'}
                            </div>
                            <div className="absolute top-2 right-2 bg-white/90 px-2 py-1 rounded text-xs font-bold shadow-sm">
                                {product.category}
                            </div>
                        </div>
                        <CardHeader className="pb-2">
                            <div className="flex justify-between items-start">
                                <CardTitle className="text-lg leading-tight">{product.name}</CardTitle>
                                <div className="flex items-center text-amber-500 text-sm font-bold">
                                    <Star className="h-3 w-3 fill-current mr-1" />
                                    {product.rating}
                                </div>
                            </div>
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold text-primary">{product.price}</div>
                        </CardContent>
                        <CardFooter>
                            <Button className="w-full">Add to Cart</Button>
                        </CardFooter>
                    </Card>
                ))}
            </div>

            {/* Second Hand Section Banner */}
            <div className="mt-10 rounded-xl bg-gradient-to-r from-orange-500 to-red-600 p-8 text-white relative overflow-hidden">
                <div className="relative z-10">
                    <h2 className="text-2xl font-bold mb-2">Sell Your Old Gear</h2>
                    <p className="text-orange-100 mb-6 max-w-lg">
                        Have a bat you don't use? Or pads that don't fit? List them on our marketplace and help a junior cricketer play!
                    </p>
                    <Button variant="secondary" className="text-red-600 hover:bg-white hover:text-red-700">
                        Start Selling
                    </Button>
                </div>
                <div className="absolute right-0 top-0 h-full w-1/3 bg-white/10 skew-x-12 transform translate-x-10" />
            </div>
        </div>
    )
}
