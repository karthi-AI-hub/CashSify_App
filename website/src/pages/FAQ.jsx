import React from 'react';
import { motion } from 'framer-motion';
import FAQSection from '../components/FAQ';
import { HelpCircle, Search, ArrowRight } from 'lucide-react';

const FAQ = () => {
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
                        <HelpCircle className="w-4 h-4" /> Global help center
                    </div>
                    <h1 className="text-6xl md:text-8xl font-black mb-8 leading-tight tracking-tighter text-gray-900">
                        Intelligence <br />
                        <span className="text-gradient-blue">On Demand.</span>
                    </h1>
                    <p className="text-xl md:text-2xl text-gray-500 font-light max-w-3xl mx-auto leading-relaxed tracking-tight">
                        The definitive repository for information regarding the
                        <span className="text-gray-900 font-medium"> Watch2Earn ecosystem</span>, rewards, and technical protocols.
                    </p>
                </motion.div>

                <div className="grid md:grid-cols-3 gap-8 mb-24">
                    {[
                        { title: "Account & Access", count: "14 Articles" },
                        { title: "Reward Distribution", count: "28 Articles" },
                        { title: "Security Protocols", count: "09 Articles" }
                    ].map((cat, i) => (
                        <div key={i} className="glass p-10 rounded-[40px] border-gray-100 flex items-center justify-between group hover:bg-gray-50 transition-all cursor-pointer shadow-sm">
                            <div>
                                <h3 className="text-2xl font-black mb-2 text-gray-900">{cat.title}</h3>
                                <span className="text-sm text-gray-500">{cat.count}</span>
                            </div>
                            <div className="w-12 h-12 rounded-full border border-gray-100 flex items-center justify-center group-hover:bg-blue-600 group-hover:border-blue-600 transition-all">
                                <ArrowRight className="w-5 h-5 text-gray-400 group-hover:text-white" />
                            </div>
                        </div>
                    ))}
                </div>

                <div className="glass-thick rounded-[60px] p-4 border-gray-100 mb-24">
                    <FAQSection />
                </div>

                <div className="text-center">
                    <h2 className="text-3xl font-black mb-8 italic text-gray-900">Still have inquiries?</h2>
                    <a href="/contact" className="btn-primary">Professional Support Ticket</a>
                </div>
            </div>
        </div>
    );
};

export default FAQ;
