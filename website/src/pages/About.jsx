import React from 'react';
import { motion } from 'framer-motion';
import { Globe, Users, Trophy, ShieldCheck, Zap, Heart } from 'lucide-react';

const About = () => {
    return (
        <div className="pt-40 pb-32 px-6 mesh-gradient min-h-screen">
            <div className="container mx-auto max-w-6xl">
                <motion.div
                    initial={{ opacity: 0, y: 30 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.8 }}
                    className="text-center mb-24"
                >
                    <div className="inline-flex items-center gap-2 px-4 py-1 rounded-full glass border-gray-100 text-[10px] font-black tracking-[0.3em] uppercase text-gray-500 mb-8 shadow-sm">
                        <Globe className="w-4 h-4" /> local roots, global reach
                    </div>
                    <h1 className="text-6xl md:text-8xl font-black mb-8 leading-tight tracking-tighter text-gray-900">
                        The Future of <br />
                        <span className="text-gradient-blue">Digital Value.</span>
                    </h1>
                    <p className="text-xl md:text-2xl text-gray-500 font-light max-w-3xl mx-auto leading-relaxed tracking-tight">
                        Watch2Earn is a professional-grade ecosystem built on the philosophy that
                        <span className="text-gray-900 font-medium font-semibold"> human attention</span> is the most valuable asset in the modern digital era.
                    </p>
                </motion.div>

                <div className="grid md:grid-cols-3 gap-8 mb-32">
                    {[
                        { icon: Globe, title: "Institutional Reach", desc: "Empowering sophisticated users from New York to London with transparent digital asset opportunities.", color: "blue" },
                        { icon: ShieldCheck, title: "Enterprise Integrity", desc: "Bank-grade encryption protocols safeguarding every interaction and reward distribution.", color: "emerald" },
                        { icon: Trophy, title: "Operational Precision", desc: "A commitment to sub-millisecond execution and 100% payout reliability globally.", color: "indigo" }
                    ].map((item, i) => (
                        <motion.div
                            key={i}
                            initial={{ opacity: 0, y: 20 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ delay: i * 0.1 }}
                            className="p-10 rounded-[40px] glass-thick border-gray-100 group hover:translate-y-[-10px] transition-all duration-500 shadow-sm"
                        >
                            <div className="w-16 h-16 rounded-2xl bg-blue-50 flex items-center justify-center mb-8 group-hover:scale-110 transition-transform">
                                <item.icon className="w-8 h-8 text-blue-600" />
                            </div>
                            <h3 className="text-2xl font-black mb-4 text-gray-900">{item.title}</h3>
                            <p className="text-gray-500 font-light leading-relaxed">{item.desc}</p>
                        </motion.div>
                    ))}
                </div>

                <div className="grid lg:grid-cols-2 gap-20 items-center">
                    <motion.div
                        initial={{ opacity: 0, x: -30 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                        className="space-y-8"
                    >
                        <h2 className="text-4xl md:text-5xl font-black leading-tight tracking-tighter text-gray-900 text-left">Our Philosophy</h2>
                        <div className="h-1.5 w-24 bg-blue-600 rounded-full" />
                        <p className="text-xl text-gray-500 font-light leading-relaxed tracking-tight text-left">
                            Watch2Earn was established at the frontier of the digital value revolution. Our founding team recognized the fundamental inefficiency in how traditional platforms undervalued human attention.
                        </p>
                        <p className="text-xl text-gray-500 font-light leading-relaxed tracking-tight text-left">
                            By deploying high-performance cloud infrastructure and proprietary reward-valuation models, we architected a sovereign ecosystem where digital participation is recognized as a professional asset.
                        </p>
                        <div className="flex items-center gap-6 pt-6">
                            <span className="text-sm font-black uppercase tracking-widest text-blue-600/50">Elite Protocol Verified</span>
                        </div>
                    </motion.div>

                    <motion.div
                        initial={{ opacity: 0, scale: 0.9 }}
                        whileInView={{ opacity: 1, scale: 1 }}
                        viewport={{ once: true }}
                        className="glass-thick p-1 rounded-[40px] border-gray-100 shadow-2xl"
                    >
                        <div className="aspect-square bg-white rounded-[36px] flex items-center justify-center relative overflow-hidden group">
                            <div className="absolute inset-0 bg-gradient-to-br from-blue-500/5 to-transparent opacity-50" />
                            <img src="/logo.png" alt="Brand Logo" className="w-40 h-40 opacity-80 group-hover:scale-110 transition-transform duration-700" />
                            <div className="absolute top-10 right-10 flex flex-col items-end">
                                <span className="text-5xl font-black text-gray-900 tracking-tighter">4.9/5</span>
                                <span className="text-[10px] font-black uppercase tracking-[0.3em] text-blue-600">Global Rating</span>
                            </div>
                            <div className="absolute bottom-10 left-10 flex flex-col">
                                <span className="text-3xl font-black text-gray-900 tracking-tighter">150+</span>
                                <span className="text-[10px] font-black uppercase tracking-[0.3em] text-emerald-600">Target Countries</span>
                            </div>
                        </div>
                    </motion.div>
                </div>
            </div>
        </div>
    );
};

export default About;
