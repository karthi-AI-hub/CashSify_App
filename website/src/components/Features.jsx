import React from 'react';
import { motion } from 'framer-motion';
import { Zap, Shield, Gift, Globe, TrendingUp, Lock } from 'lucide-react';

const BentoCard = ({ icon: Icon, title, description, className, delay }) => (
    <motion.div
        initial={{ opacity: 0, y: 30 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ delay, duration: 1.2, ease: [0.22, 1, 0.36, 1] }}
        className={`glow-card group relative p-10 rounded-[32px] glass-thick flex flex-col justify-between hover:translate-y-[-8px] transition-all duration-700 overflow-hidden ${className}`}
    >
        <div className="absolute top-0 right-0 p-8 opacity-[0.02] group-hover:opacity-[0.05] transition-opacity duration-700">
            <Icon className="w-32 h-32 text-blue-600" />
        </div>

        <div>
            <div className="w-16 h-16 rounded-2xl bg-blue-50 flex items-center justify-center mb-10 group-hover:bg-blue-100 transition-colors duration-500">
                <Icon className="text-blue-600 w-8 h-8" />
            </div>
            <h3 className="text-2xl font-black mb-4 tracking-tighter text-gray-900">{title}</h3>
            <p className="text-gray-500 leading-relaxed font-light text-lg tracking-tight">{description}</p>
        </div>
    </motion.div>
);

const Features = () => {
    return (
        <section id="features" className="py-32 px-6 relative bg-slate-50 bg-grid-slate">
            <div className="container mx-auto">
                <div className="flex flex-col md:flex-row items-end justify-between mb-20 gap-8">
                    <div className="max-w-2xl text-left">
                        <h2 className="text-4xl md:text-6xl font-black mb-6 leading-tight tracking-[-0.04em]">
                            Engineered for <br />
                            <span className="text-gradient-blue">Global Excellence.</span>
                        </h2>
                        <p className="text-xl text-gray-500 font-light leading-relaxed tracking-[-0.01em]">
                            Watch2Earn isn't just an app—it's a professional ecosystem designed to provide
                            sustainable digital rewards for users worldwide.
                        </p>
                    </div>
                    <div className="pb-2">
                        <span className="text-sm font-black tracking-[0.4em] uppercase text-blue-400/50">Core Capabilities</span>
                    </div>
                </div>

                <div className="grid md:grid-cols-6 gap-6">
                    <BentoCard
                        icon={Zap}
                        title="Hyper-Optimized Passive Income"
                        description="Our proprietary distribution algorithm ensures you capture the highest market value for your digital interactions globally."
                        className="md:col-span-3"
                        delay={0.1}
                    />
                    <BentoCard
                        icon={Lock}
                        title="Secure Ad-Based Earnings"
                        description="We deploy bank-grade encryption protocols and advanced biometric safeguards to protect every transaction."
                        className="md:col-span-3"
                        delay={0.2}
                    />
                    <BentoCard
                        icon={Gift}
                        title="Zero-Investment Work From Home"
                        description="A borderless opportunity for everyone. Build your digital portfolio with absolutely zero upfront investment required."
                        className="md:col-span-2"
                        delay={0.3}
                    />
                    <BentoCard
                        icon={Globe}
                        title="Premier Remote Opportunities: US, UK & Canada"
                        description="Engineered specifically for the economies of the US, UK, and Canada, enabling seamless global reward management."
                        className="md:col-span-4"
                        delay={0.4}
                    />
                </div>
            </div>
        </section>
    );
};

export default Features;
