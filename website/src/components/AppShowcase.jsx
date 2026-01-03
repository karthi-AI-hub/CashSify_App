import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const AppShowcase = () => {
    const [index, setIndex] = useState(0);
    const [isHovered, setIsHovered] = useState(false);

    const screenshots = [
        { src: '/screenshots/register.png', title: 'Member Access' },
        { src: '/screenshots/login.png', title: 'Secure Identity' },
        { src: '/screenshots/dashboard.png', title: 'Command Center' },
        { src: '/screenshots/watch_ads.png', title: 'Yield Generation' },
        { src: '/screenshots/referral.png', title: 'Network Effect' },
        { src: '/screenshots/withdraw.png', title: 'Instant Liquidity' },
        { src: '/screenshots/history.png', title: 'Ledger Integrity' },
    ];

    useEffect(() => {
        if (isHovered) return;
        const interval = setInterval(() => {
            setIndex((prev) => (prev + 1) % screenshots.length);
        }, 1000);
        return () => clearInterval(interval);
    }, [isHovered, screenshots.length]);

    return (
        <section className="py-32 px-6 bg-white overflow-hidden relative">
            {/* Ambient Background Glow */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[500px] bg-blue-400/10 blur-[120px] rounded-full pointer-events-none" />

            <div className="container mx-auto relative z-10">
                <motion.div
                    initial={{ opacity: 0, y: 30 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    className="text-center mb-24"
                >
                    <div className="inline-flex items-center gap-2 px-4 py-1 rounded-full glass border-gray-100 text-[10px] font-black tracking-[0.3em] uppercase text-blue-600 mb-8 shadow-sm">
                        <span className="w-2 h-2 rounded-full bg-blue-500 animate-pulse" />
                        Live Interface Preview
                    </div>
                    <h2 className="text-5xl md:text-7xl font-black mb-8 tracking-tighter text-gray-900 leading-[0.9]">
                        The <span className="text-gradient-blue">Apex</span> <br />
                        Experience.
                    </h2>
                    <p className="text-xl text-gray-500 font-light max-w-2xl mx-auto tracking-tight leading-relaxed">
                        Engineered for the 1%. A user interface that merges <span className="text-gray-900 font-medium">aesthetic perfection</span> with
                        institutional-grade capability.
                    </p>
                </motion.div>

                <div
                    className="relative max-w-[1400px] mx-auto perspective-1000"
                    onMouseEnter={() => setIsHovered(true)}
                    onMouseLeave={() => setIsHovered(false)}
                >
                    <div className="relative h-[700px] flex items-center justify-center">
                        {/* Spotlight Effect */}
                        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-white/80 pointer-events-none z-20" />

                        <div className="flex gap-12 transition-transform duration-700 ease-[cubic-bezier(0.25,1,0.5,1)] will-change-transform"
                            style={{ transform: `translateX(calc(50% - 140px - ${index * (280 + 48)}px))` }}>
                            {screenshots.map((item, i) => {
                                const isActive = i === index;
                                return (
                                    <motion.div
                                        key={i}
                                        animate={{
                                            scale: isActive ? 1.1 : 0.85,
                                            opacity: isActive ? 1 : 0.4,
                                            y: isActive ? 0 : 20,
                                            rotateY: isActive ? 0 : (i < index ? 15 : -15),
                                        }}
                                        transition={{ duration: 0.7, ease: "circOut" }}
                                        className={`w-[280px] flex-shrink-0 aspect-[9/19.5] relative group transition-all duration-700 ${isActive ? 'z-10' : 'z-0 grayscale-[0.5] blur-[1px]'}`}
                                    >
                                        {/* Physical Phone Frame */}
                                        <div className="w-full h-full rounded-[40px] border-[8px] border-white/60 shadow-2xl bg-gray-900 overflow-hidden relative ring-1 ring-gray-900/5">
                                            {/* Screen Content */}
                                            <img
                                                src={item.src}
                                                alt={item.title}
                                                className="w-full h-full object-cover"
                                            />

                                            {/* Glossy Overlay */}
                                            <div className="absolute inset-0 bg-gradient-to-tr from-white/20 via-transparent to-transparent opacity-50 pointer-events-none" />

                                            {/* Label Overlay */}
                                            <div className={`absolute bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-gray-900/90 to-transparent transition-opacity duration-500 ${isActive ? 'opacity-100' : 'opacity-0'}`}>
                                                <span className="text-white font-black text-lg tracking-tight block">{item.title}</span>
                                                <div className="h-0.5 w-12 bg-blue-500 mt-2" />
                                            </div>
                                        </div>

                                        {/* Reflection */}
                                        <div className="absolute -bottom-[20px] left-0 right-0 h-[200px] opacity-30 transform scale-y-[-1] pointer-events-none mask-image-gradient"
                                            style={{
                                                maskImage: 'linear-gradient(to bottom, rgba(0,0,0,1), rgba(0,0,0,0))',
                                                WebkitMaskImage: 'linear-gradient(to bottom, rgba(0,0,0,1), rgba(0,0,0,0))'
                                            }}>
                                            <div className="w-full h-full rounded-[40px] border-[8px] border-white/40 bg-gray-900 overflow-hidden">
                                                <img src={item.src} className="w-full h-full object-cover blur-sm" alt="" />
                                            </div>
                                        </div>
                                    </motion.div>
                                );
                            })}
                        </div>
                    </div>

                    {/* Navigation Dots */}
                    <div className="flex justify-center gap-4 mt-4 relative z-30">
                        {screenshots.map((_, i) => (
                            <button
                                key={i}
                                onClick={() => setIndex(i)}
                                className={`h-1.5 rounded-full transition-all duration-500 ${i === index ? 'w-16 bg-blue-600 shadow-lg shadow-blue-500/30' : 'w-4 bg-gray-200 hover:bg-gray-300'}`}
                                aria-label={`View screenshot ${i + 1}`}
                            />
                        ))}
                    </div>
                </div>
            </div>
        </section>
    );
};

export default AppShowcase;
