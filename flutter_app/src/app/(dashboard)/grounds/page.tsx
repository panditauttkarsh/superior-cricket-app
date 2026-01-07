'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Modal } from '@/components/ui/modal'
import { Map, Calendar, MapPin, Star, User, Loader2, Check, CreditCard } from 'lucide-react'

const INDIAN_STATES = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
    'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
    'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 'Delhi'
]

const GROUNDS = [
    {
        id: 1,
        name: 'Wankhede Practice Grid',
        city: 'Mumbai',
        state: 'Maharashtra',
        price: '₹2,000/hr',
        rating: 4.9,
        surface: 'Turf',
        color: 'bg-blue-900'
    },
    {
        id: 2,
        name: 'Shivaji Park Nets',
        city: 'Mumbai',
        state: 'Maharashtra',
        price: '₹500/hr',
        rating: 4.5,
        surface: 'Matting',
        color: 'bg-green-700'
    },
    {
        id: 3,
        name: 'Azad Maidan Pitch 3',
        city: 'Mumbai',
        state: 'Maharashtra',
        price: '₹1,200/hr',
        rating: 4.2,
        surface: 'Turf',
        color: 'bg-amber-700'
    },
    {
        id: 4,
        name: 'Nehru Stadium Grounds',
        city: 'Pune',
        state: 'Maharashtra',
        price: '₹1,500/hr',
        rating: 4.4,
        surface: 'Turf',
        color: 'bg-emerald-800'
    },
    {
        id: 5,
        name: 'Feroz Shah Kotla Annex',
        city: 'Delhi',
        state: 'Delhi',
        price: '₹2,500/hr',
        rating: 4.7,
        surface: 'Turf',
        color: 'bg-indigo-900'
    },
    {
        id: 6,
        name: 'M. Chinnaswamy Stadium',
        city: 'Bangalore',
        state: 'Karnataka',
        price: '₹2,200/hr',
        rating: 4.6,
        surface: 'Turf',
        color: 'bg-purple-900'
    },
]

export default function GroundsPage() {
    const [selectedState, setSelectedState] = useState<string>('All')
    const [isRegisterModalOpen, setIsRegisterModalOpen] = useState(false)
    const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false)
    const [isProcessing, setIsProcessing] = useState(false)
    const [paymentSuccess, setPaymentSuccess] = useState(false)
    
    const [turfForm, setTurfForm] = useState({
        name: '',
        city: '',
        state: '',
        address: '',
        surface: 'Turf',
        price: '',
        contact: ''
    })

    const filteredGrounds = selectedState === 'All' 
        ? GROUNDS 
        : GROUNDS.filter(ground => ground.state === selectedState)

    const handleRegisterTurf = () => {
        if (!turfForm.name || !turfForm.city || !turfForm.state || !turfForm.price) return
        setIsRegisterModalOpen(false)
        setIsPaymentModalOpen(true)
    }

    const handlePayment = async () => {
        setIsProcessing(true)
        await new Promise(resolve => setTimeout(resolve, 2000))
        setIsProcessing(false)
        setPaymentSuccess(true)
        setTimeout(() => {
            setPaymentSuccess(false)
            setIsPaymentModalOpen(false)
            setTurfForm({
                name: '',
                city: '',
                state: '',
                address: '',
                surface: 'Turf',
                price: '',
                contact: ''
            })
        }, 2000)
    }

    return (
        <div className="space-y-6 max-w-6xl w-full mx-auto">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold tracking-tight text-foreground/90">Book Grounds</h1>
                <div className="flex gap-2">
                    <Button variant="outline" className="shadow-lg backdrop-blur bg-background/50">
                        <Map className="mr-2 h-4 w-4" />
                        View on Map
                    </Button>
                    <Button 
                        onClick={() => setIsRegisterModalOpen(true)}
                        className="shadow-lg shadow-primary/20"
                    >
                        Register Your Turf
                    </Button>
                </div>
            </div>

            <div className="flex items-center space-x-2 pb-4 overflow-x-auto">
                <Button 
                    variant={selectedState === 'All' ? 'default' : 'secondary'}
                    size="sm" 
                    className="rounded-full px-4"
                    onClick={() => setSelectedState('All')}
                >
                    All States
                </Button>
                {['Maharashtra', 'Delhi', 'Karnataka', 'Tamil Nadu', 'Gujarat', 'Punjab'].map(state => (
                    <Button 
                        key={state}
                        variant={selectedState === state ? 'default' : 'secondary'}
                        size="sm" 
                        className="rounded-full px-4"
                        onClick={() => setSelectedState(state)}
                    >
                        {state}
                    </Button>
                ))}
                <Button variant="ghost" size="sm" className="rounded-full px-4 text-muted-foreground">More...</Button>
            </div>

            <div className="grid gap-6 md:grid-cols-2">
                {filteredGrounds.map((ground) => (
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
                                        {ground.city}, {ground.state} • {ground.surface} Pitch
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

            {/* Register Turf Modal */}
            <Modal
                isOpen={isRegisterModalOpen}
                onClose={() => setIsRegisterModalOpen(false)}
                title="Register Your Turf"
                description="List your cricket ground on our platform"
            >
                <div className="space-y-4">
                    <div className="space-y-2">
                        <Label>Turf Name *</Label>
                        <Input
                            placeholder="e.g., City Cricket Ground"
                            value={turfForm.name}
                            onChange={(e) => setTurfForm({ ...turfForm, name: e.target.value })}
                        />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <Label>City *</Label>
                            <Input
                                placeholder="Mumbai"
                                value={turfForm.city}
                                onChange={(e) => setTurfForm({ ...turfForm, city: e.target.value })}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>State *</Label>
                            <select
                                value={turfForm.state}
                                onChange={(e) => setTurfForm({ ...turfForm, state: e.target.value })}
                                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                            >
                                <option value="">Select State</option>
                                {INDIAN_STATES.map(state => (
                                    <option key={state} value={state}>{state}</option>
                                ))}
                            </select>
                        </div>
                    </div>
                    <div className="space-y-2">
                        <Label>Address</Label>
                        <Input
                            placeholder="Full address of the turf"
                            value={turfForm.address}
                            onChange={(e) => setTurfForm({ ...turfForm, address: e.target.value })}
                        />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <Label>Surface Type *</Label>
                            <select
                                value={turfForm.surface}
                                onChange={(e) => setTurfForm({ ...turfForm, surface: e.target.value })}
                                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                            >
                                <option value="Turf">Turf</option>
                                <option value="Matting">Matting</option>
                                <option value="Concrete">Concrete</option>
                            </select>
                        </div>
                        <div className="space-y-2">
                            <Label>Price per Hour (₹) *</Label>
                            <Input
                                type="number"
                                placeholder="1000"
                                value={turfForm.price}
                                onChange={(e) => setTurfForm({ ...turfForm, price: e.target.value })}
                            />
                        </div>
                    </div>
                    <div className="space-y-2">
                        <Label>Contact Number</Label>
                        <Input
                            placeholder="+91 98765 43210"
                            value={turfForm.contact}
                            onChange={(e) => setTurfForm({ ...turfForm, contact: e.target.value })}
                        />
                    </div>
                    <div className="bg-yellow-500/10 border border-yellow-500/30 rounded-lg p-4">
                        <div className="flex items-start gap-2">
                            <div className="text-yellow-500 font-bold">₹500</div>
                            <div className="text-sm text-muted-foreground">
                                Registration fee required to list your turf on our platform
                            </div>
                        </div>
                    </div>
                    <div className="flex gap-3 pt-4">
                        <Button
                            variant="outline"
                            onClick={() => setIsRegisterModalOpen(false)}
                            className="flex-1"
                        >
                            Cancel
                        </Button>
                        <Button
                            onClick={handleRegisterTurf}
                            className="flex-1"
                            disabled={!turfForm.name || !turfForm.city || !turfForm.state || !turfForm.price}
                        >
                            Continue to Payment
                        </Button>
                    </div>
                </div>
            </Modal>

            {/* Payment Modal */}
            <Modal
                isOpen={isPaymentModalOpen}
                onClose={() => setIsPaymentModalOpen(false)}
                title="Payment for Turf Registration"
                description="Complete your ₹500 registration payment"
            >
                <div className="space-y-4">
                    <div className="bg-primary/10 border border-primary/30 rounded-lg p-4">
                        <div className="flex justify-between items-center mb-2">
                            <span className="text-muted-foreground">Registration Fee</span>
                            <span className="text-2xl font-bold">₹500</span>
                        </div>
                        <div className="text-sm text-muted-foreground">
                            Turf: {turfForm.name}, {turfForm.city}
                        </div>
                    </div>
                    <div className="space-y-2">
                        <Label>Payment Method</Label>
                        <div className="space-y-2">
                            <div className="flex items-center gap-3 p-3 border rounded-lg cursor-pointer hover:bg-white/5">
                                <CreditCard className="h-5 w-5" />
                                <span>Credit/Debit Card</span>
                            </div>
                            <div className="flex items-center gap-3 p-3 border rounded-lg cursor-pointer hover:bg-white/5">
                                <div className="h-5 w-5 bg-green-500 rounded"></div>
                                <span>UPI</span>
                            </div>
                            <div className="flex items-center gap-3 p-3 border rounded-lg cursor-pointer hover:bg-white/5">
                                <div className="h-5 w-5 bg-blue-500 rounded"></div>
                                <span>Net Banking</span>
                            </div>
                        </div>
                    </div>
                    {paymentSuccess ? (
                        <div className="flex items-center justify-center gap-2 text-green-500 py-4">
                            <Check className="h-5 w-5" />
                            <span>Payment Successful! Your turf has been registered.</span>
                        </div>
                    ) : (
                        <Button 
                            className="w-full"
                            onClick={handlePayment}
                            disabled={isProcessing}
                        >
                            {isProcessing ? (
                                <>
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    Processing Payment...
                                </>
                            ) : (
                                <>
                                    <CreditCard className="mr-2 h-4 w-4" />
                                    Pay ₹500
                                </>
                            )}
                        </Button>
                    )}
                </div>
            </Modal>
        </div>
    )
}
