import React from 'react';
import { motion } from 'framer-motion';
import { Mail, MessageSquare, Globe, ArrowRight, ShieldCheck } from 'lucide-react';

const Contact = () => {
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
                        <MessageSquare className="w-4 h-4" /> Global Support 24/7
                    </div>
                    <h1 className="text-6xl md:text-8xl font-black mb-8 leading-tight tracking-tighter text-gray-900">
                        Connect with the <br />
                        <span className="text-gradient-blue">Elite Network.</span>
                    </h1>
                    <p className="text-xl md:text-2xl text-gray-500 font-light max-w-3xl mx-auto leading-relaxed tracking-tight">
                        Our global infrastructure is designed to provide instantaneous support to our participants in the
                        <span className="text-gray-900 font-medium"> US, UK, and Canada</span>.
                    </p>
                </motion.div>

                <div className="grid lg:grid-cols-3 gap-8 mb-24">
                    {[
                        {
                            icon: Mail,
                            title: "Support Protocol",
                            label: "Official Correspondence",
                            value: "app.watch2earn@gmail.com",
                            desc: "Our priority response team averages sub-hour resolution times for all technical inquiries."
                        },
                        {
                            icon: Globe,
                            title: "Global Hubs",
                            label: "Jurisdictional Coverage",
                            value: "NYC • London • Toronto",
                            desc: "We maintain distributed nodes across major financial centers to ensure 100% platform stability."
                        },
                        {
                            icon: ShieldCheck,
                            title: "Security Ledger",
                            label: "Integrity Verification",
                            value: "Verified Ecosystem",
                            desc: "All communications are encrypted using bank-grade 256-bit AES protocols for your privacy."
                        }
                    ].map((item, i) => (
                        <motion.div
                            key={i}
                            initial={{ opacity: 0, y: 20 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ delay: i * 0.1 }}
                            className="p-10 rounded-[40px] glass-thick border-gray-100 group hover:translate-y-[-10px] transition-all duration-500 shadow-sm hover:shadow-xl"
                        >
                            <div className="w-16 h-16 rounded-2xl bg-blue-50 flex items-center justify-center mb-8 group-hover:scale-110 transition-transform">
                                <item.icon className="w-8 h-8 text-blue-600" />
                            </div>
                            <h3 className="text-2xl font-black mb-2 text-gray-900">{item.title}</h3>
                            <span className="text-[10px] font-black uppercase tracking-[0.2em] text-blue-600 block mb-6">{item.label}</span>
                            <div className="text-xl font-bold text-gray-900 mb-4 break-all">{item.value}</div>
                            <p className="text-gray-500 font-light leading-relaxed">{item.desc}</p>
                        </motion.div>
                    ))}
                </div>

                <div className="glass-thick rounded-[60px] p-12 md:p-20 border-gray-100 relative overflow-hidden group shadow-xl">
                    <div className="absolute inset-0 bg-gradient-to-br from-blue-600/5 to-transparent opacity-50" />
                    <div className="relative z-10 grid md:grid-cols-2 gap-16 items-center">
                        <div>
                            <h2 className="text-4xl md:text-5xl font-black mb-8 tracking-tighter text-gray-900">Instant Payout <br />Assistance</h2>
                            <p className="text-xl text-gray-500 font-light mb-10 leading-relaxed">
                                Need help with your reward distribution or digital assets? Our specialized agents are ready to assist you in real-time.
                            </p>

                            {/* Phone Number Section */}
                            <div className="mb-10 p-6 rounded-3xl bg-blue-50 border border-blue-100/50">
                                <span className="block text-xs font-black uppercase tracking-widest text-blue-600 mb-2">Priority Hotline</span>
                                <div className="text-2xl font-black text-gray-900 tracking-tight">+91 80722 23275</div>
                            </div>

                            <div className="flex items-center gap-4 text-emerald-600 font-black uppercase tracking-widest text-xs">
                                <span className="relative flex h-3 w-3">
                                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                                    <span className="relative inline-flex rounded-full h-3 w-3 bg-emerald-600"></span>
                                </span>
                                System Online & Verified
                            </div>
                        </div>

                        {/* Functional Form */}
                        <form
                            className="space-y-6"
                            onSubmit={(e) => {
                                e.preventDefault();
                                const name = e.target.name.value;
                                const email = e.target.email.value;
                                const message = e.target.message.value;
                                const mailtoLink = `mailto:app.watch2earn@gmail.com?subject=Support Inquiry: ${name}&body=Name: ${name}%0D%0AEmail: ${email}%0D%0A%0D%0AInquiry Details:%0D%0A${message}`;
                                window.location.href = mailtoLink;
                            }}
                        >
                            <div className="group/input relative">
                                <input name="name" required type="text" placeholder="Full Name" className="w-full bg-gray-50 border border-gray-100 rounded-2xl py-6 px-8 text-gray-900 focus:outline-none focus:border-blue-500/50 transition-all font-medium" />
                            </div>
                            <div className="group/input relative">
                                <input name="email" required type="email" placeholder="Email Address" className="w-full bg-gray-50 border border-gray-100 rounded-2xl py-6 px-8 text-gray-900 focus:outline-none focus:border-blue-500/50 transition-all font-medium" />
                            </div>
                            <div className="group/input relative">
                                <textarea name="message" required placeholder="Describe your inquiry..." rows="4" className="w-full bg-gray-50 border border-gray-100 rounded-2xl py-6 px-8 text-gray-900 focus:outline-none focus:border-blue-500/50 transition-all resize-none font-medium"></textarea>
                            </div>
                            <button type="submit" className="btn-primary w-full py-6 flex items-center justify-center gap-3 group">
                                Dispatch Inquiry <ArrowRight className="w-5 h-5 group-hover:translate-x-2 transition-transform" />
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Contact;
