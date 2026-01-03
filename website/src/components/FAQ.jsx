import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Minus, HelpCircle } from 'lucide-react';

const FAQItem = ({ question, answer, index }) => {
    const [isOpen, setIsOpen] = useState(false);

    return (
        <motion.div
            initial={{ opacity: 0, y: 10 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: index * 0.1 }}
            className="mb-4"
        >
            <button
                onClick={() => setIsOpen(!isOpen)}
                className={`w-full p-6 text-left rounded-2xl glass border-gray-100 flex items-center justify-between transition-all duration-500 shadow-sm ${isOpen ? 'bg-gray-50 border-gray-200' : 'hover:bg-gray-50'}`}
            >
                <span className="text-lg font-bold pr-8 tracking-tight text-gray-900">{question}</span>
                <div className={`w-8 h-8 rounded-full flex items-center justify-center transition-all duration-500 ${isOpen ? 'bg-blue-600 text-white shadow-lg' : 'bg-gray-100 text-gray-500'}`}>
                    {isOpen ? <Minus className="w-4 h-4" /> : <Plus className="w-4 h-4" />}
                </div>
            </button>
            <AnimatePresence>
                {isOpen && (
                    <motion.div
                        initial={{ height: 0, opacity: 0 }}
                        animate={{ height: "auto", opacity: 1 }}
                        exit={{ height: 0, opacity: 0 }}
                        transition={{ duration: 0.3, ease: "easeInOut" }}
                        className="overflow-hidden"
                    >
                        <div className="p-8 text-gray-500 font-light leading-relaxed border-t border-gray-100 bg-white/50 glass rounded-b-2xl -mt-2">
                            {answer}
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
        </motion.div>
    );
};

const FAQ = () => {
    const faqs = [
        {
            question: "How do I initiate my digital reward journey with Watch2Earn?",
            answer: "Onboarding is instantaneous. Download the official Watch2Earn application from the Google Play Store to join the most sophisticated ecosystem for passive income and digital asset management available today."
        },
        {
            question: "Are there any capital requirements to participate in the ecosystem?",
            answer: "Watch2Earn is committed to democratization. Our platform is strictly zero-capital, ensuring that every user in the US, UK, and Canada can generate value without any financial barriers."
        },
        {
            question: "What differentiates Watch2Earn from standard reward platforms?",
            answer: "We focus on institutional-grade integrity and premium value distribution. Our systems are optimized to prioritize user security and sustainable growth, offering a superior alternative to traditional ad-based models."
        },
        {
            question: "How are cross-border rewards managed and secured?",
            answer: "Our infrastructure utilize advanced global protocols and trusted financial partners to ensure that your digital rewards are processed with the highest level of security and efficiency across all major international markets."
        }
    ];

    return (
        <section id="faq" className="py-32 px-6 bg-white">
            <div className="container mx-auto max-w-4xl">
                <div className="text-center mb-20">
                    <div className="inline-flex items-center gap-2 px-4 py-1 rounded-full glass border-gray-100 text-[10px] font-black tracking-[0.3em] uppercase text-gray-500 mb-6 shadow-sm">
                        <HelpCircle className="w-4 h-4" /> common inquiries
                    </div>
                    <h2 className="text-4xl md:text-6xl font-black mb-6 tracking-tighter text-gray-900">Questions? <br /><span className="text-gradient-blue">We have answers.</span></h2>
                    <p className="text-xl text-gray-500 font-light tracking-tight">Everything you need to know about the world's elite rewards platform.</p>
                </div>

                <div className="space-y-2">
                    {faqs.map((faq, i) => (
                        <FAQItem key={i} index={i} {...faq} />
                    ))}
                </div>

                <div className="mt-20 p-12 rounded-[40px] glass-thick !border-0 text-center relative overflow-hidden group shadow-sm">
                    <div className="absolute top-0 left-0 w-full h-full bg-blue-500/5 opacity-0 group-hover:opacity-100 transition-opacity duration-700" />
                    <h3 className="text-3xl font-black mb-4 relative z-10 text-gray-900">Still have questions?</h3>
                    <p className="text-gray-500 mb-8 relative z-10">Our global support team is ready to assist you 24/7.</p>
                    <button className="btn-primary relative z-10">Contact Global Support</button>
                </div>
            </div>
        </section>
    );
};

export default FAQ;
