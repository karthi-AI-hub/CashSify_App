import React, { useState, useEffect } from 'react';
import { motion, useScroll, useTransform } from 'framer-motion';
import { PlayCircle, Download, ArrowRight, ShieldCheck, Globe, Zap } from 'lucide-react';

const LiveCounter = ({ value, label }) => {
    const [count, setCount] = useState(value);

    useEffect(() => {
        const interval = setInterval(() => {
            setCount(prev => prev + (Math.random() * 0.5));
        }, 3000);
        return () => clearInterval(interval);
    }, []);

    return (
        <div className="flex flex-col">
            <span className="text-3xl font-black font-display text-gray-900 tracking-tighter">
                ${count.toLocaleString('en-US', { minimumFractionDigits: 1, maximumFractionDigits: 1 })}M+
            </span>
            <span className="text-[10px] uppercase tracking-[0.4em] text-blue-600 font-black mt-1">{label}</span>
        </div>
    );
};

const Hero = () => {
    const { scrollY } = useScroll();
    const y1 = useTransform(scrollY, [0, 500], [0, 200]);
    const y2 = useTransform(scrollY, [0, 500], [0, -150]);

    return (
        <section className="relative min-h-screen flex items-center justify-center pt-32 pb-20 overflow-hidden mesh-gradient">
            <div className="container mx-auto px-6 relative z-10">
                <div className="grid lg:grid-cols-2 gap-20 items-center">
                    <motion.div
                        initial={{ opacity: 0, x: -50 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ duration: 1, ease: "easeOut" }}
                    >
                        <motion.div
                            initial={{ opacity: 0, scale: 0.9 }}
                            animate={{ opacity: 1, scale: 1 }}
                            transition={{ delay: 0.2 }}
                            className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full glass border-gray-100 mb-10 shadow-sm"
                        >
                            <span className="flex h-2 w-2 rounded-full bg-blue-600 animate-pulse" />
                            <span className="text-[10px] font-black uppercase tracking-[0.3em] text-gray-500">Live Infrastructure Online</span>
                        </motion.div>

                        <h1 className="text-7xl md:text-9xl font-black mb-8 leading-[0.85] tracking-tighter text-gray-900 group">
                            Watch Ads. <br />
                            <span className="text-gradient-blue transition-all duration-700">Earn Cash.</span> <br />
                            Digital Sovereignty.
                        </h1>

                        <p className="text-xl md:text-2xl text-gray-500 font-light mb-12 max-w-xl leading-relaxed tracking-tight">
                            Welcome to the global gold standard for <span className="text-gray-900 font-medium border-b-2 border-blue-500/20">digital asset appreciation</span>.
                            Monetize your attention with institutional-grade precision.
                        </p>

                        <div className="flex flex-wrap gap-6 mb-16">
                            <a
                                href="https://play.google.com/store/apps/details?id=com.cashsify.android"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="btn-primary group flex items-center gap-2"
                            >
                                Start Earning <ArrowRight className="w-5 h-5 group-hover:translate-x-2 transition-transform" />
                            </a>
                            <a href="#features" className="btn-secondary group flex items-center gap-2">
                                Elite Protocol <Zap className="w-5 h-5" />
                            </a>
                        </div>

                        <div className="flex items-center gap-12 border-t border-gray-100 pt-10">
                            <div className="flex flex-col">
                                <span className="text-3xl font-black text-gray-900 tracking-tighter">1.2M+</span>
                                <span className="text-[10px] font-black uppercase tracking-[0.3em] text-blue-600 mt-1">Global Participants</span>
                            </div>
                            <div className="w-px h-12 bg-gray-100" />
                            <LiveCounter value={142.8} label="Distributed Rewards" />
                        </div>
                    </motion.div>

                    <motion.div
                        style={{ y: y1 }}
                        className="relative hidden lg:block"
                    >
                        <div className="relative z-10 glass-thick p-2 rounded-[60px] border-gray-100 shadow-[0_40px_100px_-20px_rgba(0,0,0,0.05)] overflow-hidden max-w-[320px] mx-auto">
                            <div className="bg-gray-50 rounded-[52px] overflow-hidden aspect-[9/19] relative group">
                                <img
                                    src="/screenshots/dashboard.png"
                                    alt="Elite App Interface"
                                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-1000"
                                />
                                <div className="absolute inset-0 bg-gradient-to-t from-gray-900/40 to-transparent p-10 flex flex-col justify-end">
                                    <div className="h-1 w-20 bg-blue-600 rounded-full mb-4" />
                                    <span className="text-2xl font-black text-white tracking-tighter">Liquid Generation</span>
                                </div>
                            </div>
                        </div>
                    </motion.div>
                </div>
            </div>
        </section>
    );
};

export default Hero;
