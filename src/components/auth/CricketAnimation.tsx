'use client'

import { motion } from 'framer-motion'
import Image from 'next/image'

export function CricketAnimation() {
    return (
        <div className="relative h-full w-full overflow-hidden flex flex-col justify-between p-10">
            {/* Modern Cricket Stadium Background */}
            <div className="absolute inset-0">
                {/* Background Image - Cricket Stadium */}
                <div className="absolute inset-0 bg-gradient-to-br from-emerald-900 via-green-800 to-emerald-700">
                    {/* Stadium field pattern */}
                    <div className="absolute inset-0 opacity-30">
                        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full h-2/3 bg-green-600/20 rounded-full"></div>
                        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-1 h-full bg-white/10"></div>
                        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full h-1 bg-white/10"></div>
                    </div>
                </div>
                
                {/* Overlay gradient */}
                <div className="absolute inset-0 bg-gradient-to-b from-black/40 via-transparent to-black/60"></div>
            </div>

            {/* Logo and Title with Bat Icon */}
            <div className="relative z-10">
                <motion.div
                    initial={{ opacity: 0, y: -20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.8, ease: "easeOut" }}
                    className="flex items-center gap-3 mb-4"
                >
                    {/* Bat Icon instead of Trophy */}
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
                        {/* Cricket Bat SVG Icon */}
                        <svg 
                            className="h-12 w-12 text-yellow-400 relative z-10" 
                            viewBox="0 0 100 200" 
                            fill="none" 
                            xmlns="http://www.w3.org/2000/svg"
                        >
                            {/* Bat Blade */}
                            <ellipse cx="50" cy="60" rx="35" ry="25" fill="currentColor" opacity="0.9"/>
                            <ellipse cx="50" cy="60" rx="30" ry="20" fill="currentColor" opacity="0.7"/>
                            {/* Bat Handle */}
                            <rect x="45" y="60" width="10" height="120" rx="5" fill="currentColor"/>
                            <rect x="47" y="65" width="6" height="110" rx="3" fill="currentColor" opacity="0.6"/>
                            {/* Grip lines */}
                            <line x1="48" y1="75" x2="52" y2="75" stroke="currentColor" strokeWidth="1" opacity="0.4"/>
                            <line x1="48" y1="90" x2="52" y2="90" stroke="currentColor" strokeWidth="1" opacity="0.4"/>
                            <line x1="48" y1="105" x2="52" y2="105" stroke="currentColor" strokeWidth="1" opacity="0.4"/>
                        </svg>
                    </motion.div>
                    <div>
                        <h1 className="text-4xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-yellow-300 via-white to-emerald-300">
                            CricPlay
                        </h1>
                        <motion.p
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            transition={{ delay: 0.4, duration: 0.8 }}
                            className="text-slate-200 text-sm font-light tracking-wide"
                        >
                            The ultimate cricket community
                        </motion.p>
                    </div>
                </motion.div>
            </div>

            {/* Modern LCD Screen Display with CricPlay */}
            <div className="relative z-10 flex-1 flex items-center justify-center">
                <motion.div
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ duration: 1, ease: "easeOut" }}
                    className="relative"
                >
                    {/* LCD Screen Frame */}
                    <div className="relative bg-gradient-to-br from-gray-900 via-gray-800 to-black rounded-2xl p-6 shadow-2xl border-4 border-gray-700">
                        {/* Screen Bezel */}
                        <div className="bg-black rounded-lg p-4 border-2 border-gray-600">
                            {/* LCD Screen */}
                            <div className="bg-gradient-to-br from-emerald-900/90 via-green-800/90 to-emerald-700/90 rounded-lg p-8 border-2 border-emerald-500/30 shadow-inner">
                                {/* Screen Content */}
                                <div className="text-center space-y-4">
                                    {/* CricPlay Logo on Screen */}
                                    <motion.div
                                        initial={{ opacity: 0, y: 20 }}
                                        animate={{ opacity: 1, y: 0 }}
                                        transition={{ delay: 0.5, duration: 0.8 }}
                                    >
                                        <div className="text-6xl font-black bg-clip-text text-transparent bg-gradient-to-r from-yellow-300 via-yellow-400 to-yellow-500 mb-2" style={{
                                            textShadow: '0 0 20px rgba(250, 204, 21, 0.8)',
                                            filter: 'drop-shadow(0 0 10px rgba(250, 204, 21, 0.6))'
                                        }}>
                                            CricPlay
                                        </div>
                                    </motion.div>
                                    
                                    {/* Score Display Style */}
                                    <motion.div
                                        initial={{ opacity: 0 }}
                                        animate={{ opacity: 1 }}
                                        transition={{ delay: 0.8, duration: 0.8 }}
                                        className="text-2xl font-mono text-green-300 font-bold"
                                    >
                                        142/3 (16.4)
                                    </motion.div>
                                    
                                    {/* Status Indicator */}
                                    <motion.div
                                        initial={{ opacity: 0 }}
                                        animate={{ opacity: 1 }}
                                        transition={{ delay: 1, duration: 0.8 }}
                                        className="flex items-center justify-center gap-2"
                                    >
                                        <span className="relative flex h-3 w-3">
                                            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                                            <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
                                        </span>
                                        <span className="text-green-400 font-semibold text-sm">LIVE</span>
                                    </motion.div>
                                </div>
                            </div>
                        </div>
                        
                        {/* Screen Stand/Base */}
                        <div className="absolute -bottom-4 left-1/2 -translate-x-1/2 w-32 h-4 bg-gray-800 rounded-b-lg border-2 border-gray-700"></div>
                    </div>
                    
                    {/* Glow Effect */}
                    <div className="absolute inset-0 bg-emerald-500/20 rounded-2xl blur-2xl -z-10"></div>
                </motion.div>
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
