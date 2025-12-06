'use client'

import { useState, useRef, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ArrowLeft, ArrowRight, Loader2, Trophy, MapPin, User, Calendar, Smartphone, Check } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent } from '@/components/ui/card'
import { cn } from '@/lib/utils'
import { useRouter } from 'next/navigation'

// Types
type OnboardingStep = 'mobile' | 'otp' | 'personal' | 'location' | 'cricket' | 'avatar'

interface UserData {
    mobile: string
    otp: string
    fullName: string
    gender: 'male' | 'female' | 'other' | ''
    birthday: string
    city: string
    role: 'batsman' | 'bowler' | 'all-rounder' | ''
    battingStyle: 'right' | 'left' | ''
    bowlingStyle: string
    jerseyNumber: string
}

export function OnboardingWizard() {
    const router = useRouter()
    const [step, setStep] = useState<OnboardingStep>('mobile')
    const [isLoading, setIsLoading] = useState(false)
    const [direction, setDirection] = useState(1)
    const [data, setData] = useState<UserData>({
        mobile: '',
        otp: '',
        fullName: '',
        gender: '',
        birthday: '',
        city: '',
        role: '',
        battingStyle: '',
        bowlingStyle: '',
        jerseyNumber: '',
    })

    // Simulated OTP
    const MOCK_OTP = '1234'

    const handleNext = async () => {
        setIsLoading(true)
        // Simulate API delay
        await new Promise(resolve => setTimeout(resolve, 600))
        setIsLoading(false)

        if (step === 'mobile') {
            if (data.mobile.length < 10) return // Basic validation
            setDirection(1)
            setStep('otp')
        } else if (step === 'otp') {
            if (data.otp === MOCK_OTP) {
                setDirection(1)
                setStep('personal')
            } else {
                alert('Invalid OTP (Try 1234)')
            }
        } else if (step === 'personal') {
            if (data.fullName && data.gender) {
                setDirection(1)
                setStep('location')
            }
        } else if (step === 'location') {
            if (data.city) {
                setDirection(1)
                setStep('cricket')
            }
        } else if (step === 'cricket') {
            if (data.role) {
                setDirection(1)
                setStep('avatar')
            }
        } else if (step === 'avatar') {
            // Finish
            console.log('Final Data:', data)
            // Save to localStorage or Cookie
            localStorage.setItem('superior_user', JSON.stringify(data))
            router.push('/')
        }
    }

    const handleBack = () => {
        setDirection(-1)
        if (step === 'otp') setStep('mobile')
        if (step === 'personal') setStep('otp')
        if (step === 'location') setStep('personal')
        if (step === 'cricket') setStep('location')
        if (step === 'avatar') setStep('cricket')
    }

    const updateData = (key: keyof UserData, value: string) => {
        setData(prev => ({ ...prev, [key]: value }))
    }

    const variants = {
        enter: (direction: number) => ({
            x: direction > 0 ? 50 : -50,
            opacity: 0,
        }),
        center: {
            x: 0,
            opacity: 1,
        },
        exit: (direction: number) => ({
            x: direction < 0 ? 50 : -50,
            opacity: 0,
        }),
    }

    return (
        <div className="w-full h-full">
            {/* Mobile Logo - Only show on mobile */}
            <div className="mb-8 text-center lg:hidden">
                <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-primary/10 mb-4 ring-2 ring-primary/20 animate-pulse">
                    <Trophy className="w-8 h-8 text-primary" />
                </div>
                <h1 className="text-3xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-primary to-blue-600">
                    CricPlay
                </h1>
                <p className="text-muted-foreground mt-2">The ultimate cricket community</p>
            </div>

            <Card className="border border-white/20 shadow-2xl bg-white/90 backdrop-blur-2xl overflow-hidden hover:shadow-3xl transition-all duration-300 w-full min-h-[600px] flex flex-col">
                <CardContent className="p-8 sm:p-10 lg:p-12 flex-1 flex flex-col">
                    <AnimatePresence mode="wait" custom={direction}>
                        <motion.div
                            key={step}
                            custom={direction}
                            variants={variants}
                            initial="enter"
                            animate="center"
                            exit="exit"
                            transition={{ type: "spring", stiffness: 300, damping: 30 }}
                        >
                            {/* STEP 1: MOBILE */}
                            {step === 'mobile' && (
                                <div className="space-y-8">
                                    <div className="space-y-3 text-center">
                                        <h2 className="text-4xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-primary to-blue-600">Get Started</h2>
                                        <p className="text-base text-muted-foreground">Enter your mobile number to begin your cricket journey</p>
                                    </div>
                                    <div className="relative">
                                        <Label className="mb-2 block text-sm font-medium">Mobile Number</Label>
                                        <div className="relative">
                                            <div className="absolute left-3 top-1/2 -translate-y-1/2 border-r pr-3 flex items-center gap-2 z-10">
                                                <span className="text-lg">🇮🇳</span>
                                                <span className="font-medium text-sm">+91</span>
                                            </div>
                                            <Input
                                                type="tel"
                                                placeholder="98765 43210"
                                                className="pl-20 h-14 text-lg tracking-wide bg-background/50 border-2 border-input focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                                                value={data.mobile}
                                                onChange={(e) => updateData('mobile', e.target.value.replace(/\D/g, '').slice(0, 10))}
                                                autoFocus
                                            />
                                        </div>
                                    </div>
                                    <Button
                                        onClick={handleNext}
                                        className="w-full h-14 text-lg shadow-lg shadow-primary/20 hover:shadow-xl hover:scale-[1.02] transition-all font-semibold"
                                        disabled={data.mobile.length !== 10 || isLoading}
                                    >
                                        {isLoading ? (
                                            <>
                                                <Loader2 className="animate-spin mr-2" />
                                                Sending OTP...
                                            </>
                                        ) : (
                                            'Continue'
                                        )}
                                    </Button>
                                </div>
                            )}

                            {/* STEP 2: OTP */}
                            {step === 'otp' && (
                                <div className="space-y-8">
                                    <div className="space-y-3 text-center">
                                        <h2 className="text-4xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-primary to-blue-600">Verification</h2>
                                        <p className="text-base text-muted-foreground">Enter the OTP sent to +91 {data.mobile}</p>
                                    </div>
                                    <div className="space-y-3">
                                        <Label className="text-sm font-medium">Enter OTP</Label>
                                        <div className="flex justify-center gap-3">
                                            {[0, 1, 2, 3].map((i) => (
                                                <Input
                                                    key={i}
                                                    type="text"
                                                    maxLength={1}
                                                    className="w-16 h-16 text-center text-2xl font-bold bg-background/50 border-2 border-input focus:ring-2 focus:ring-primary/20 focus:border-primary rounded-xl transition-all"
                                                    value={data.otp[i] || ''}
                                                    onChange={(e) => {
                                                        const val = e.target.value.replace(/\D/g, '')
                                                        const newOtp = data.otp.split('')
                                                        newOtp[i] = val
                                                        updateData('otp', newOtp.join('').slice(0, 4))
                                                        // Auto focus next
                                                        if (val && i < 3) {
                                                            const nextInput = document.querySelector(`input[name=otp-${i + 1}]`) as HTMLInputElement
                                                            nextInput?.focus()
                                                        }
                                                    }}
                                                    name={`otp-${i}`}
                                                    autoFocus={i === 0 && data.otp.length === 0}
                                                />
                                            ))}
                                        </div>
                                    </div>
                                    <div className="text-center space-y-2">
                                        <button className="text-sm text-primary hover:underline font-medium">Resend OTP</button>
                                        <p className="text-xs text-green-600 font-mono bg-green-50 inline-block px-2 py-1 rounded">Dev Note: Use OTP 1234</p>
                                    </div>
                                    <Button
                                        onClick={handleNext}
                                        className="w-full h-14 text-lg shadow-lg shadow-primary/20 hover:shadow-xl hover:scale-[1.02] transition-all font-semibold"
                                        disabled={data.otp.length !== 4 || isLoading}
                                    >
                                        {isLoading ? (
                                            <>
                                                <Loader2 className="animate-spin mr-2" />
                                                Verifying...
                                            </>
                                        ) : (
                                            'Verify OTP'
                                        )}
                                    </Button>
                                    <button onClick={handleBack} className="w-full text-sm text-muted-foreground hover:text-foreground">
                                        Change Number
                                    </button>
                                </div>
                            )}

                            {/* STEP 3: PERSONAL */}
                            {step === 'personal' && (
                                <div className="space-y-8">
                                    <div className="space-y-3 text-center">
                                        <h2 className="text-4xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-primary to-blue-600">About You</h2>
                                        <p className="text-base text-muted-foreground">Tell us a bit about yourself</p>
                                    </div>

                                    <div className="space-y-2">
                                        <Label className="text-sm font-medium">Full Name</Label>
                                        <Input
                                            value={data.fullName}
                                            onChange={(e) => updateData('fullName', e.target.value)}
                                            placeholder="e.g. Rohit Sharma"
                                            className="h-12 bg-background/50 border-2 border-input focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                                        />
                                    </div>

                                    <div className="space-y-2">
                                        <Label>Gender</Label>
                                        <div className="grid grid-cols-3 gap-3">
                                            {['Male', 'Female', 'Other'].map((g) => (
                                                <button
                                                    key={g}
                                                    onClick={() => updateData('gender', g.toLowerCase() as any)}
                                                    className={cn(
                                                        "h-11 rounded-lg text-sm font-medium transition-all border",
                                                        data.gender === g.toLowerCase()
                                                            ? "bg-primary text-primary-foreground border-primary shadow-md"
                                                            : "bg-background hover:bg-secondary border-input"
                                                    )}
                                                >
                                                    {g}
                                                </button>
                                            ))}
                                        </div>
                                    </div>

                                    <div className="space-y-2">
                                        <Label>Birthday</Label>
                                        <Input
                                            type="date"
                                            value={data.birthday}
                                            onChange={(e) => updateData('birthday', e.target.value)}
                                            className="h-12 bg-background/50 border-2 border-input focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                                        />
                                    </div>

                                    <div className="flex gap-3 pt-2">
                                        <Button variant="outline" onClick={handleBack} className="flex-1 h-11">Back</Button>
                                        <Button onClick={handleNext} className="flex-[2] h-11" disabled={!data.fullName || !data.gender}>Next</Button>
                                    </div>
                                </div>
                            )}

                            {/* STEP 4: LOCATION */}
                            {step === 'location' && (
                                <div className="space-y-6">
                                    <div className="space-y-2">
                                        <h2 className="text-2xl font-semibold">Location</h2>
                                        <p className="text-sm text-muted-foreground">Where do you play most of your cricket?</p>
                                    </div>

                                    <div className="space-y-2">
                                        <Label>City / Town</Label>
                                        <div className="relative">
                                            <MapPin className="absolute left-3 top-3 h-5 w-5 text-muted-foreground" />
                                            <Input
                                                value={data.city}
                                                onChange={(e) => updateData('city', e.target.value)}
                                                placeholder="Enter your city"
                                                className="pl-10 h-12 bg-secondary/50 border-0"
                                                autoFocus
                                            />
                                        </div>
                                    </div>

                                    <div className="flex gap-3 pt-4">
                                        <Button variant="outline" onClick={handleBack} className="flex-1 h-11">Back</Button>
                                        <Button onClick={handleNext} className="flex-[2] h-11" disabled={!data.city}>Next</Button>
                                    </div>
                                </div>
                            )}

                            {/* STEP 5: CRICKET PROFILE */}
                            {step === 'cricket' && (
                                <div className="space-y-6">
                                    <div className="space-y-2">
                                        <h2 className="text-2xl font-semibold">Cricket Profile</h2>
                                        <p className="text-sm text-muted-foreground">Define your style of play</p>
                                    </div>

                                    <div className="space-y-2">
                                        <Label>Role</Label>
                                        <div className="grid grid-cols-3 gap-2">
                                            {['Batsman', 'Bowler', 'All-Rounder'].map((r) => (
                                                <button
                                                    key={r}
                                                    onClick={() => updateData('role', r.toLowerCase() as any)}
                                                    className={cn(
                                                        "p-2 rounded-xl text-sm font-medium transition-all border flex flex-col items-center gap-1",
                                                        data.role === r.toLowerCase()
                                                            ? "bg-primary text-primary-foreground border-primary shadow-md"
                                                            : "bg-background hover:bg-secondary border-input"
                                                    )}
                                                >
                                                    {r === 'Batsman' && <span className="text-xl">🏏</span>}
                                                    {r === 'Bowler' && <span className="text-xl">🥎</span>}
                                                    {r === 'All-Rounder' && <span className="text-xl">⚒️</span>}
                                                    {r}
                                                </button>
                                            ))}
                                        </div>
                                    </div>

                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="space-y-2">
                                            <Label>Batting Style</Label>
                                            <div className="flex flex-col gap-2">
                                                {['Right Hand', 'Left Hand'].map((s) => (
                                                    <button
                                                        key={s}
                                                        onClick={() => updateData('battingStyle', s.split(' ')[0].toLowerCase() as any)}
                                                        className={cn(
                                                            "h-9 rounded-md text-xs font-medium border transition-colors",
                                                            data.battingStyle === s.split(' ')[0].toLowerCase()
                                                                ? "bg-primary/10 border-primary text-primary"
                                                                : "border-input hover:bg-secondary"
                                                        )}
                                                    >
                                                        {s}
                                                    </button>
                                                ))}
                                            </div>
                                        </div>
                                        <div className="space-y-2">
                                            <Label>Jersey No.</Label>
                                            <Input
                                                type="number"
                                                value={data.jerseyNumber}
                                                onChange={(e) => updateData('jerseyNumber', e.target.value)}
                                                placeholder="e.g. 18"
                                                className="h-20 text-3xl text-center font-bold bg-secondary/50 border-0"
                                            />
                                        </div>
                                    </div>

                                    <div className="flex gap-3 pt-2">
                                        <Button variant="outline" onClick={handleBack} className="flex-1 h-11">Back</Button>
                                        <Button onClick={handleNext} className="flex-[2] h-11" disabled={!data.role}>Next</Button>
                                    </div>
                                </div>
                            )}

                            {/* STEP 6: AVATAR */}
                            {step === 'avatar' && (
                                <div className="space-y-8 text-center">
                                    <div className="space-y-2">
                                        <h2 className="text-2xl font-semibold">Final Touch</h2>
                                        <p className="text-sm text-muted-foreground">Add a profile picture</p>
                                    </div>

                                    <div className="relative w-32 h-32 mx-auto rounded-full bg-secondary flex items-center justify-center overflow-hidden border-4 border-white shadow-xl">
                                        <User className="w-16 h-16 text-muted-foreground/50" />
                                        {/* Mock Upload Overlay */}
                                        <div className="absolute inset-0 bg-black/5 hover:bg-black/10 flex items-center justify-center cursor-pointer transition-colors group">
                                            <span className="text-xs font-medium text-transparent group-hover:text-black/50">Upload</span>
                                        </div>
                                    </div>

                                    <div className="space-y-1">
                                        <h3 className="text-xl font-bold">{data.fullName}</h3>
                                        <p className="text-muted-foreground">{data.role && data.role.charAt(0).toUpperCase() + data.role.slice(1)} • {data.city}</p>
                                    </div>

                                    <div className="flex gap-3 pt-4">
                                        <Button variant="outline" onClick={handleBack} className="flex-1 h-12">Back</Button>
                                        <Button onClick={handleNext} className="flex-[2] h-12 text-lg bg-green-600 hover:bg-green-700 shadow-lg shadow-green-600/20">
                                            Let's Play
                                        </Button>
                                    </div>
                                </div>
                            )}

                        </motion.div>
                    </AnimatePresence>
                </CardContent>
            </Card>
        </div>
    )
}
