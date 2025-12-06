'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Modal } from '@/components/ui/modal'
import { ShoppingBag, Star, Tag, Plus, Minus, X, Loader2, Check } from 'lucide-react'
import { useAppStore } from '@/lib/store'

const PRODUCTS = [
    {
        id: 1,
        name: 'Pro Grade English Willow Bat',
        price: '₹12,499',
        priceNum: 12499,
        rating: 4.8,
        category: 'Bats',
        color: 'bg-emerald-100'
    },
    {
        id: 2,
        name: 'CricPlay Helmet',
        price: '₹2,499',
        priceNum: 2499,
        rating: 4.5,
        category: 'Protection',
        color: 'bg-blue-100'
    },
    {
        id: 3,
        name: 'Match Leather Ball (Pack of 6)',
        price: '₹1,899',
        priceNum: 1899,
        rating: 4.9,
        category: 'Accessories',
        color: 'bg-red-100'
    },
    {
        id: 4,
        name: 'Team India Jersey (Custom)',
        price: '₹999',
        priceNum: 999,
        rating: 4.2,
        category: 'Apparel',
        color: 'bg-indigo-100'
    },
    {
        id: 5,
        name: 'Wicket Keeping Gloves',
        price: '₹3,299',
        priceNum: 3299,
        rating: 4.6,
        category: 'Gloves',
        color: 'bg-orange-100'
    },
    {
        id: 6,
        name: 'Used Batting Pads (Good Condition)',
        price: '₹899',
        priceNum: 899,
        rating: 4.0,
        category: 'Second Hand',
        color: 'bg-gray-200'
    }
]

export default function ShopPage() {
    const { cart, addToCart, removeFromCart, updateCartQuantity, clearCart, addSellItem } = useAppStore()
    const [isCartOpen, setIsCartOpen] = useState(false)
    const [isSellModalOpen, setIsSellModalOpen] = useState(false)
    const [isPurchasing, setIsPurchasing] = useState(false)
    const [purchaseSuccess, setPurchaseSuccess] = useState(false)
    
    const [sellForm, setSellForm] = useState({
        name: '',
        description: '',
        price: '',
        condition: 'Good',
        quantity: 1,
        category: 'Bats'
    })

    const cartTotal = cart.reduce((sum, item) => {
        const product = PRODUCTS.find(p => p.id === item.id)
        return sum + (product ? product.priceNum * item.quantity : 0)
    }, 0)

    const handlePurchase = async () => {
        setIsPurchasing(true)
        await new Promise(resolve => setTimeout(resolve, 2000))
        clearCart()
        setIsPurchasing(false)
        setPurchaseSuccess(true)
        setTimeout(() => {
            setPurchaseSuccess(false)
            setIsCartOpen(false)
        }, 2000)
    }

    const handleSellItem = () => {
        if (!sellForm.name || !sellForm.price) return
        addSellItem({
            name: sellForm.name,
            description: sellForm.description,
            price: sellForm.price,
            condition: sellForm.condition,
            quantity: sellForm.quantity,
            category: sellForm.category
        })
        setIsSellModalOpen(false)
        setSellForm({
            name: '',
            description: '',
            price: '',
            condition: 'Good',
            quantity: 1,
            category: 'Bats'
        })
    }

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold tracking-tight text-foreground/90">Store</h1>
                <Button 
                    onClick={() => setIsCartOpen(true)}
                    className="shadow-lg shadow-primary/20 relative"
                >
                    <ShoppingBag className="mr-2 h-4 w-4" />
                    Cart ({cart.length})
                    {cart.length > 0 && (
                        <span className="absolute -top-2 -right-2 h-5 w-5 bg-red-500 rounded-full flex items-center justify-center text-xs text-white">
                            {cart.reduce((sum, item) => sum + item.quantity, 0)}
                        </span>
                    )}
                </Button>
            </div>

            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                {PRODUCTS.map((product) => (
                    <Card key={product.id} className="bg-card/60 backdrop-blur-sm border-white/20 shadow-xl overflow-hidden group hover:scale-[1.02] transition-transform duration-300">
                        <div className={`h-48 ${product.color} flex items-center justify-center relative overflow-hidden`}>
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
                            <Button 
                                className="w-full"
                                onClick={() => addToCart({
                                    id: product.id,
                                    name: product.name,
                                    price: product.price,
                                    category: product.category
                                })}
                            >
                                Add to Cart
                            </Button>
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
                    <Button 
                        variant="secondary" 
                        className="text-red-600 hover:bg-white hover:text-red-700"
                        onClick={() => setIsSellModalOpen(true)}
                    >
                        Start Selling
                    </Button>
                </div>
                <div className="absolute right-0 top-0 h-full w-1/3 bg-white/10 skew-x-12 transform translate-x-10" />
            </div>

            {/* Cart Modal */}
            <Modal
                isOpen={isCartOpen}
                onClose={() => setIsCartOpen(false)}
                title="Shopping Cart"
                description="Review your items before checkout"
            >
                <div className="space-y-4">
                    {cart.length === 0 ? (
                        <div className="text-center py-8 text-muted-foreground">
                            <ShoppingBag className="h-12 w-12 mx-auto mb-4 opacity-50" />
                            <p>Your cart is empty</p>
                        </div>
                    ) : (
                        <>
                            <div className="space-y-3 max-h-96 overflow-y-auto">
                                {cart.map((item) => {
                                    const product = PRODUCTS.find(p => p.id === item.id)
                                    return (
                                        <div key={item.id} className="flex items-center gap-4 p-3 bg-white/5 rounded-lg">
                                            <div className="flex-1">
                                                <div className="font-medium">{item.name}</div>
                                                <div className="text-sm text-muted-foreground">{item.price}</div>
                                            </div>
                                            <div className="flex items-center gap-2">
                                                <Button
                                                    variant="outline"
                                                    size="icon"
                                                    className="h-8 w-8"
                                                    onClick={() => updateCartQuantity(item.id, item.quantity - 1)}
                                                >
                                                    <Minus className="h-4 w-4" />
                                                </Button>
                                                <span className="w-8 text-center">{item.quantity}</span>
                                                <Button
                                                    variant="outline"
                                                    size="icon"
                                                    className="h-8 w-8"
                                                    onClick={() => updateCartQuantity(item.id, item.quantity + 1)}
                                                >
                                                    <Plus className="h-4 w-4" />
                                                </Button>
                                            </div>
                                            <Button
                                                variant="ghost"
                                                size="icon"
                                                className="h-8 w-8"
                                                onClick={() => removeFromCart(item.id)}
                                            >
                                                <X className="h-4 w-4" />
                                            </Button>
                                        </div>
                                    )
                                })}
                            </div>
                            <div className="border-t pt-4 space-y-3">
                                <div className="flex justify-between text-lg font-bold">
                                    <span>Total</span>
                                    <span>₹{cartTotal.toLocaleString('en-IN')}</span>
                                </div>
                                {purchaseSuccess ? (
                                    <div className="flex items-center justify-center gap-2 text-green-500 py-4">
                                        <Check className="h-5 w-5" />
                                        <span>Purchase Successful!</span>
                                    </div>
                                ) : (
                                    <Button 
                                        className="w-full"
                                        onClick={handlePurchase}
                                        disabled={isPurchasing}
                                    >
                                        {isPurchasing ? (
                                            <>
                                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                                Processing...
                                            </>
                                        ) : (
                                            'Proceed to Checkout'
                                        )}
                                    </Button>
                                )}
                            </div>
                        </>
                    )}
                </div>
            </Modal>

            {/* Sell Item Modal */}
            <Modal
                isOpen={isSellModalOpen}
                onClose={() => setIsSellModalOpen(false)}
                title="List Item for Sale"
                description="Fill in the details to list your item"
            >
                <div className="space-y-4">
                    <div className="space-y-2">
                        <Label>Item Name</Label>
                        <Input
                            placeholder="e.g., English Willow Bat"
                            value={sellForm.name}
                            onChange={(e) => setSellForm({ ...sellForm, name: e.target.value })}
                        />
                    </div>
                    <div className="space-y-2">
                        <Label>Description</Label>
                        <Input
                            placeholder="Describe the item condition and features"
                            value={sellForm.description}
                            onChange={(e) => setSellForm({ ...sellForm, description: e.target.value })}
                        />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <Label>Price (₹)</Label>
                            <Input
                                type="number"
                                placeholder="500"
                                value={sellForm.price}
                                onChange={(e) => setSellForm({ ...sellForm, price: e.target.value })}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Condition</Label>
                            <select
                                value={sellForm.condition}
                                onChange={(e) => setSellForm({ ...sellForm, condition: e.target.value })}
                                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                            >
                                <option value="Excellent">Excellent</option>
                                <option value="Good">Good</option>
                                <option value="Fair">Fair</option>
                                <option value="Poor">Poor</option>
                            </select>
                        </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <Label>Quantity</Label>
                            <Input
                                type="number"
                                min="1"
                                value={sellForm.quantity}
                                onChange={(e) => setSellForm({ ...sellForm, quantity: parseInt(e.target.value) || 1 })}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Category</Label>
                            <select
                                value={sellForm.category}
                                onChange={(e) => setSellForm({ ...sellForm, category: e.target.value })}
                                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                            >
                                <option value="Bats">Bats</option>
                                <option value="Protection">Protection</option>
                                <option value="Accessories">Accessories</option>
                                <option value="Apparel">Apparel</option>
                                <option value="Gloves">Gloves</option>
                                <option value="Second Hand">Second Hand</option>
                            </select>
                        </div>
                    </div>
                    <div className="flex gap-3 pt-4">
                        <Button
                            variant="outline"
                            onClick={() => setIsSellModalOpen(false)}
                            className="flex-1"
                        >
                            Cancel
                        </Button>
                        <Button
                            onClick={handleSellItem}
                            className="flex-1"
                            disabled={!sellForm.name || !sellForm.price}
                        >
                            List Item
                        </Button>
                    </div>
                </div>
            </Modal>
        </div>
    )
}
