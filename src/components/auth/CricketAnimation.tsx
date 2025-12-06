'use client'

import { motion } from 'framer-motion'
import { Trophy } from 'lucide-react'

export function CricketAnimation() {
    return (
        <div className="relative h-full w-full bg-gradient-to-br from-slate-900 via-slate-800 to-emerald-900 overflow-hidden flex flex-col justify-between p-10">
            {/* Modern Background Effects */}
            <div className="absolute inset-0">
                {/* Animated gradient orbs */}
                <motion.div
                    className="absolute top-20 left-10 w-96 h-96 bg-emerald-500/20 rounded-full blur-3xl"
                    animate={{
                        scale: [1, 1.2, 1],
                        opacity: [0.3, 0.5, 0.3],
                    }}
                    transition={{
                        duration: 8,
                        repeat: Infinity,
                        ease: "easeInOut"
                    }}
                />
                <motion.div
                    className="absolute bottom-20 right-10 w-96 h-96 bg-blue-500/20 rounded-full blur-3xl"
                    animate={{
                        scale: [1.2, 1, 1.2],
                        opacity: [0.3, 0.5, 0.3],
                    }}
                    transition={{
                        duration: 10,
                        repeat: Infinity,
                        ease: "easeInOut"
                    }}
                />
                
                {/* Grid pattern overlay */}
                <div className="absolute inset-0 opacity-10" style={{
                    backgroundImage: 'linear-gradient(rgba(255,255,255,0.1) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.1) 1px, transparent 1px)',
                    backgroundSize: '50px 50px'
                }} />
            </div>

            {/* Logo and Title */}
            <div className="relative z-10">
                <motion.div
                    initial={{ opacity: 0, y: -20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.8, ease: "easeOut" }}
                    className="flex items-center gap-3 mb-4"
                >
                    <motion.div
                        animate={{ 
                            rotate: [0, 5, -5, 0],
                            scale: [1, 1.05, 1]
                        }}
                        transition={{ 
                            duration: 3, 
                            repeat: Infinity, 
                            ease: "easeInOut" 
                        }}
                        className="relative"
                    >
                        <div className="absolute inset-0 bg-yellow-400/30 rounded-full blur-xl"></div>
                        <Trophy className="h-12 w-12 text-yellow-400 relative z-10" />
                    </motion.div>
                    <div>
                        <h1 className="text-4xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-yellow-300 via-white to-emerald-300">
                            CricPlay
                        </h1>
                        <motion.p
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            transition={{ delay: 0.4, duration: 0.8 }}
                            className="text-slate-300 text-sm font-light tracking-wide"
                        >
                            The ultimate cricket community
                        </motion.p>
                    </div>
                </motion.div>
            </div>

            {/* Modern Cricket Animation */}
            <div className="relative z-10 flex-1 flex items-center justify-center">
                <div className="relative w-full h-full flex items-center justify-center">
                    {/* Abstract Pitch Lines - Modern Design */}
                    <div className="absolute inset-0 flex items-center justify-center">
                        <div className="w-1 h-full bg-gradient-to-b from-transparent via-white/20 to-transparent"></div>
                        <div className="absolute w-full h-0.5 bg-gradient-to-r from-transparent via-white/10 to-transparent"></div>
                    </div>

                    {/* Particle Effects */}
                    {[...Array(15)].map((_, i) => (
                        <motion.div
                            key={i}
                            className="absolute w-1 h-1 bg-yellow-400 rounded-full"
                            style={{
                                left: `${20 + (i * 5)}%`,
                                top: `${30 + (i % 3) * 20}%`,
                            }}
                            animate={{
                                y: [0, -100, 0],
                                opacity: [0, 1, 0],
                                scale: [0, 1, 0],
                            }}
                            transition={{
                                duration: 2,
                                repeat: Infinity,
                                delay: i * 0.2,
                                ease: "easeOut"
                            }}
                        />
                    ))}

                    {/* Ball Trail - Modern */}
                    <motion.div
                        className="absolute z-20"
                        animate={{
                            x: [-300, 0, 400],
                            y: [0, -50, -300],
                            rotate: [0, 720, 1440],
                        }}
                        transition={{
                            duration: 2.5,
                            repeat: Infinity,
                            repeatDelay: 0.5,
                            ease: [0.4, 0, 0.2, 1]
                        }}
                    >
                        <div className="relative">
                            {/* Glow effect */}
                            <div className="absolute inset-0 bg-red-500 rounded-full blur-xl opacity-50"></div>
                            {/* Ball */}
                            <div className="relative w-10 h-10 bg-gradient-to-br from-red-500 via-red-600 to-red-700 rounded-full shadow-2xl border-2 border-red-400/50">
                                <div className="absolute inset-0 bg-gradient-to-tr from-white/30 to-transparent rounded-full"></div>
                                <div className="absolute top-2 left-2 w-2 h-2 bg-white/60 rounded-full"></div>
                            </div>
                        </div>
                    </motion.div>

                    {/* Modern Bat - Abstract Design */}
                    <motion.div
                        className="absolute z-30 origin-bottom"
                        animate={{
                            rotate: [-70, 20, -70],
                        }}
                        transition={{
                            duration: 2.5,
                            repeat: Infinity,
                            repeatDelay: 0.5,
                            ease: [0.4, 0, 0.2, 1]
                        }}
                        style={{ transformOrigin: 'bottom center' }}
                    >
                        <div className="relative">
                            {/* Bat Glow */}
                            <div className="absolute -inset-4 bg-amber-500/20 rounded-full blur-2xl"></div>
                            {/* Bat Handle */}
                            <div className="w-4 h-28 bg-gradient-to-b from-amber-800 via-amber-700 to-amber-900 rounded-t-xl shadow-2xl ml-3 relative">
                                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/10 to-transparent rounded-t-xl"></div>
                                {/* Grip texture */}
                                <div className="absolute top-2 left-0 right-0 h-0.5 bg-amber-950/50"></div>
                                <div className="absolute top-6 left-0 right-0 h-0.5 bg-amber-950/50"></div>
                                <div className="absolute top-10 left-0 right-0 h-0.5 bg-amber-950/50"></div>
                            </div>
                            {/* Bat Blade - Modern Design */}
                            <div className="absolute top-0 left-0 w-24 h-16 bg-gradient-to-br from-amber-600 via-amber-700 to-amber-800 rounded-t-2xl shadow-2xl border-2 border-amber-500/30">
                                <div className="absolute inset-0 bg-gradient-to-tr from-white/20 to-transparent rounded-t-2xl"></div>
                                {/* Modern lines */}
                                <div className="absolute top-2 left-2 right-2 h-0.5 bg-amber-800/40 rounded-full"></div>
                                <div className="absolute top-4 left-2 right-2 h-0.5 bg-amber-800/40 rounded-full"></div>
                                <div className="absolute top-6 left-2 right-2 h-0.5 bg-amber-800/40 rounded-full"></div>
                            </div>
                        </div>
                    </motion.div>

                    {/* Impact Effect - Modern */}
                    <motion.div
                        className="absolute z-15"
                        initial={{ scale: 0, opacity: 0 }}
                        animate={{
                            scale: [0, 3, 0],
                            opacity: [0, 0.8, 0],
                        }}
                        transition={{
                            duration: 0.5,
                            repeat: Infinity,
                            repeatDelay: 2.5,
                        }}
                    >
                        <div className="w-32 h-32 bg-gradient-to-r from-yellow-400 via-yellow-500 to-orange-500 rounded-full blur-3xl"></div>
                    </motion.div>

                    {/* Modern "6" Display */}
                    <motion.div
                        className="absolute z-40"
                        initial={{ scale: 0, opacity: 0, y: 0 }}
                        animate={{
                            scale: [0, 1.5, 1.3, 0],
                            opacity: [0, 1, 1, 0],
                            y: [0, -100, -200],
                        }}
                        transition={{
                            duration: 2,
                            repeat: Infinity,
                            repeatDelay: 2.5,
                            ease: "easeOut"
                        }}
                    >
                        <div className="relative">
                            {/* Glow behind */}
                            <div className="absolute inset-0 bg-yellow-400 rounded-full blur-3xl opacity-50"></div>
                            {/* Number */}
                            <div className="relative text-9xl font-black bg-clip-text text-transparent bg-gradient-to-b from-yellow-300 via-yellow-400 to-yellow-600" style={{
                                textShadow: '0 0 40px rgba(250, 204, 21, 0.8), 0 0 80px rgba(250, 204, 21, 0.6)',
                                filter: 'drop-shadow(0 0 30px rgba(250, 204, 21, 0.9))'
                            }}>
                                6
                            </div>
                        </div>
                    </motion.div>

                    {/* Ball flying away - Modern */}
                    <motion.div
                        className="absolute z-25"
                        animate={{
                            x: [0, 600],
                            y: [0, -400],
                            scale: [1, 0.2],
                            opacity: [1, 0],
                        }}
                        transition={{
                            duration: 2,
                            repeat: Infinity,
                            repeatDelay: 2.5,
                            ease: "easeOut"
                        }}
                    >
                        <div className="relative">
                            <div className="absolute inset-0 bg-red-500 rounded-full blur-2xl opacity-50"></div>
                            <div className="relative w-12 h-12 bg-gradient-to-br from-red-500 via-red-600 to-red-700 rounded-full shadow-2xl border-2 border-red-400/50">
                                <div className="absolute inset-0 bg-gradient-to-tr from-white/30 to-transparent rounded-full"></div>
                            </div>
                        </div>
                    </motion.div>

                    {/* Light Rays Effect */}
                    <motion.div
                        className="absolute z-5 top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2"
                        animate={{
                            rotate: [0, 360],
                        }}
                        transition={{
                            duration: 20,
                            repeat: Infinity,
                            ease: "linear"
                        }}
                    >
                        <div className="w-96 h-96">
                            {[...Array(8)].map((_, i) => (
                                <div
                                    key={i}
                                    className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-1 h-48 bg-gradient-to-b from-yellow-400/20 to-transparent origin-top"
                                    style={{
                                        transform: `translate(-50%, -50%) rotate(${i * 45}deg)`,
                                    }}
                                />
                            ))}
                        </div>
                    </motion.div>
                </div>
            </div>

            {/* Modern Testimonial */}
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.6, duration: 0.8, ease: "easeOut" }}
                className="relative z-10"
            >
                <div className="backdrop-blur-sm bg-white/5 rounded-2xl p-6 border border-white/10 shadow-2xl">
                    <blockquote className="space-y-3">
                        <p className="text-lg text-white/90 leading-relaxed font-light">
                            &ldquo;The best cricket scoring app I've ever used. It's not just about the numbers, it's about the experience.&rdquo;
                        </p>
                        <footer className="text-sm text-emerald-300 font-medium">
                            — Virat K., Club Captain
                        </footer>
                    </blockquote>
                </div>
            </motion.div>
        </div>
    )
}
