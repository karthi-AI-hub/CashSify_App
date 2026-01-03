import React from 'react';
import { motion } from 'framer-motion';

const Terms = () => {
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
                        Platform Usage Protocol
                    </div>
                    <h1 className="text-5xl md:text-7xl font-black mb-6 leading-[0.9] tracking-tighter text-gray-900">
                        Terms and <span className="text-gradient-blue">Conditions</span>
                    </h1>
                    <p className="text-gray-500 font-bold uppercase tracking-widest text-[10px]">Efficient Protocol: 03-JAN-2026</p>
                </motion.div>

                <div className="prose prose-slate max-w-none text-gray-500 space-y-12">
                    <section>
                        <h2 className="text-2xl font-black text-gray-900 mb-6 tracking-tight">1. Introduction</h2>
                        <div className="space-y-4 font-light leading-relaxed text-lg">
                            <p>
                                Welcome to Watch2Earn! These Terms and Conditions ("Terms") govern your use of the Watch2Earn application ("the App"). By using the App, you agree to comply with these Terms. If you do not agree, please refrain from using the App.
                            </p>
                        </div>
                    </section>

                    <section>
                        <h2 className="text-2xl font-black text-gray-900 mb-6 tracking-tight">2. User Eligibility</h2>
                        <div className="p-8 rounded-[32px] glass border-gray-100 shadow-sm">
                            <ul className="space-y-4 font-light text-lg list-none">
                                <li className="flex items-center gap-3"><div className="w-1.5 h-1.5 rounded-full bg-blue-500 flex-shrink-0" /> You must be at least 13 years old to use the App.</li>
                                <li className="flex items-center gap-3"><div className="w-1.5 h-1.5 rounded-full bg-blue-500 flex-shrink-0" /> Minors must have verifiable parental consent for platform interaction.</li>
                            </ul>
                        </div>
                    </section>

                    <section>
                        <h2 className="text-2xl font-black text-gray-900 mb-6 tracking-tight">3. Rewards System</h2>
                        <div className="bg-gray-50 p-10 rounded-[40px] border border-gray-100">
                            <p className="mb-6 font-light leading-relaxed text-lg italic">The Watch2Earn rewards loop is a privilege governed by strict integrity standards.</p>
                            <ul className="space-y-4 font-light text-base list-none">
                                <li className="flex items-start gap-2">✓ Watch2Earn reserves the right to modify yield rates based on global market conditions.</li>
                                <li className="flex items-start gap-2">✓ Any exploitation (bots, farm systems) will result in immediate asset forfeiture.</li>
                                <li className="flex items-start gap-2">✓ Payouts are processed via institutional-grade financial pipelines.</li>
                            </ul>
                        </div>
                    </section>

                    <section>
                        <h2 className="text-2xl font-black text-gray-900 mb-6 tracking-tight">4. Advertisements</h2>
                        <p className="font-light leading-relaxed text-lg">
                            Watch2Earn integrates with third-party ad networks (e.g., Google AdMob). The content of advertisements is the responsibility of the advertisers, not Watch2Earn. Users must adhere to the terms and conditions of the respective ad networks.
                        </p>
                    </section>

                    <section className="bg-gray-900 p-12 rounded-[48px] text-white shadow-2xl relative overflow-hidden group">
                        <div className="absolute inset-0 bg-blue-600 scale-0 group-hover:scale-100 transition-transform duration-1000 origin-bottom-right" />
                        <div className="relative z-10">
                            <h2 className="text-3xl font-black mb-4">Termination Protocol</h2>
                            <p className="text-gray-400 group-hover:text-blue-100 transition-colors font-light text-lg mb-8 leading-relaxed">
                                We reserve the right to suspend or terminate user access for violations of these Terms or behavior deemed detrimental to the ecosystem's integrity.
                            </p>
                            <a href="mailto:app.watch2earn@gmail.com" className="inline-flex items-center gap-2 bg-white text-gray-900 px-8 py-4 rounded-2xl font-black uppercase text-[10px] tracking-widest hover:bg-blue-500 hover:text-white transition-all shadow-xl">
                                Contact Ethics Board
                            </a>
                        </div>
                    </section>

                    <p className="text-center font-display text-2xl font-black text-gray-900 mt-20 italic">By using Watch2Earn, you agree to these legal standards.</p>
                </div>
            </div>
        </div>
    );
};

export default Terms;
