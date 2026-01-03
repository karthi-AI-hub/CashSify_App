import React from 'react';
import { motion } from 'framer-motion';

const Privacy = () => {
    return (
        <div className="pt-40 pb-32 px-6 mesh-gradient min-h-screen">
            <div className="container mx-auto max-w-4xl">
                <motion.div
                    initial={{ opacity: 0, y: 30 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.8 }}
                    className="mb-16 text-center"
                >
                    <div className="inline-flex items-center gap-2 px-4 py-1 rounded-full glass border-gray-100 text-[10px] font-black tracking-[0.3em] uppercase text-gray-500 mb-8 shadow-sm">
                        Data Privacy Protocol
                    </div>
                    <h1 className="text-5xl md:text-7xl font-black mb-6 leading-[0.9] tracking-tighter text-gray-900">
                        Privacy <span className="text-gradient-blue">Policy</span>
                    </h1>
                    <p className="text-gray-500 font-bold uppercase tracking-widest text-[10px]">Efficient Protocol: 03-JAN-2026</p>
                </motion.div>

                <div className="prose prose-slate max-w-none text-gray-500 space-y-12">
                    <section>
                        <h2 className="text-2xl font-black text-gray-900 mb-6 tracking-tight">1. Introduction</h2>
                        <div className="space-y-4 font-light leading-relaxed text-lg">
                            <p>
                                Welcome to Watch2Earn, a platform where users can earn rewards by watching advertisements. This Privacy Policy outlines how we collect, use, and protect your personal information when you use the App.
                            </p>
                            <p>
                                By using Watch2Earn, you agree to the collection and use of information in accordance with this Privacy Policy. If you do not agree, please refrain from using the App.
                            </p>
                        </div>
                    </section>

                    <section>
                        <h2 className="text-2xl font-black text-gray-900 mb-6 tracking-tight">2. Information We Collect</h2>
                        <div className="grid md:grid-cols-2 gap-8">
                            <div className="p-8 rounded-[32px] glass border-gray-100 shadow-sm">
                                <h3 className="text-lg font-black text-blue-600 mb-4 uppercase tracking-widest text-xs">a. User Provided</h3>
                                <ul className="space-y-3 font-light text-base list-none">
                                    <li className="flex items-start gap-2"><div className="w-1.5 h-1.5 rounded-full bg-blue-500 mt-2 flex-shrink-0" /> Email & Auth Credentials</li>
                                    <li className="flex items-start gap-2"><div className="w-1.5 h-1.5 rounded-full bg-blue-500 mt-2 flex-shrink-0" /> Payment Distribution Data (UPI)</li>
                                </ul>
                            </div>
                            <div className="p-8 rounded-[32px] glass border-gray-100 shadow-sm">
                                <h3 className="text-lg font-black text-blue-600 mb-4 uppercase tracking-widest text-xs">b. System Logs</h3>
                                <ul className="space-y-3 font-light text-base list-none">
                                    <li className="flex items-start gap-2"><div className="w-1.5 h-1.5 rounded-full bg-blue-500 mt-2 flex-shrink-0" /> Device Telemetry (OS/Models)</li>
                                    <li className="flex items-start gap-2"><div className="w-1.5 h-1.5 rounded-full bg-blue-500 mt-2 flex-shrink-0" /> Engagement Metrics & Latency</li>
                                </ul>
                            </div>
                        </div>
                    </section>

                    <section>
                        <h2 className="text-2xl font-black text-gray-900 mb-6 tracking-tight">3. How We Use Your Information</h2>
                        <div className="bg-gray-50 p-8 rounded-[32px] border border-gray-100">
                            <ul className="grid md:grid-cols-2 gap-4 font-light text-gray-600 list-none">
                                <li className="flex items-center gap-3">✓ Optimization of App Core</li>
                                <li className="flex items-center gap-3">✓ Personalized Yield Delivery</li>
                                <li className="flex items-center gap-3">✓ Reward Pipeline Processing</li>
                                <li className="flex items-center gap-3">✓ Fraud Mitigation Protocols</li>
                            </ul>
                        </div>
                    </section>

                    <section>
                        <h2 className="text-2xl font-black text-gray-900 mb-6 tracking-tight">4. Sharing Your Information</h2>
                        <p className="font-light leading-relaxed text-lg mb-6">We do not sell your personal information. However, we may share your data with:</p>
                        <div className="flex flex-wrap gap-3">
                            {["Ad Networks", "Cloud Infrastructure", "Legal Entities", "Audit Partners"].map((tag, i) => (
                                <span key={i} className="px-4 py-2 rounded-full glass border-gray-100 text-[10px] font-black uppercase tracking-widest text-gray-400">{tag}</span>
                            ))}
                        </div>
                    </section>

                    <section className="bg-blue-600 p-12 rounded-[48px] text-white shadow-2xl relative overflow-hidden">
                        <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl -mr-32 -mt-32" />
                        <h2 className="text-3xl font-black mb-4 relative z-10">Integrity Standard</h2>
                        <p className="text-blue-100 font-light text-lg mb-8 relative z-10 leading-relaxed">
                            Watch2Earn integrates with third-party advertising partners, such as Google AdMob. These partners may collect and use your data as described in their privacy policies.
                        </p>
                        <a href="mailto:app.watch2earn@gmail.com" className="inline-flex items-center gap-2 bg-white text-blue-600 px-8 py-4 rounded-2xl font-black uppercase text-[10px] tracking-widest hover:scale-105 transition-transform shadow-xl relative z-10">
                            Request Data Audit
                        </a>
                    </section>

                    <p className="text-center font-display text-2xl font-black text-gray-900 mt-20 italic">Thank you for choosing Watch2Earn.</p>
                </div>
            </div>
        </div>
    );
};

export default Privacy;
