import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Menu, X, Download } from 'lucide-react';
import { Link } from 'react-router-dom';

const Navbar = () => {
    const [scrolled, setScrolled] = useState(false);
    const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

    useEffect(() => {
        const handleScroll = () => setScrolled(window.scrollY > 20);
        window.addEventListener('scroll', handleScroll);
        return () => window.removeEventListener('scroll', handleScroll);
    }, []);

    return (
        <motion.nav
            initial={{ y: -100 }}
            animate={{ y: 0 }}
            className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 px-6 py-4 flex justify-between items-center ${scrolled ? 'glass-thick mx-4 mt-4 rounded-3xl border-gray-100' : 'bg-transparent mt-0 mx-0 rounded-none border-transparent'}`}
        >
            <Link to="/" className="flex items-center gap-2 group">
                <div className="w-10 h-10 flex items-center justify-center group-hover:scale-110 transition-transform">
                    <img src="/logo.png" alt="Watch2Earn Logo" className="w-full h-full object-contain" />
                </div>
                <span className={`text-xl font-black font-display tracking-tighter ${scrolled ? 'text-gray-900' : 'text-gray-900'}`}>Watch2Earn</span>
            </Link>

            <div className="hidden md:flex items-center gap-10 text-[10px] font-black uppercase tracking-[0.25em] text-gray-500">
                <Link to="/" className="hover:text-blue-600 transition-colors">Home</Link>
                <Link to="/about" className="hover:text-blue-600 transition-colors">About</Link>
                <Link to="/faq" className="hover:text-blue-600 transition-colors">FAQ</Link>
                <Link to="/contact" className="hover:text-blue-600 transition-colors">Contact</Link>
            </div>

            <div className="flex items-center gap-4">
                <a
                    href="https://play.google.com/store/apps/details?id=com.cashsify.android"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="hidden sm:flex btn-primary !py-3 !px-8 text-[10px] uppercase tracking-widest !rounded-xl items-center gap-2 group"
                >
                    Get App <Download className="w-4 h-4 group-hover:translate-y-1 transition-transform" />
                </a>

                <button
                    className="md:hidden glass p-3 rounded-xl border-gray-100"
                    onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                >
                    {mobileMenuOpen ? <X className="w-6 h-6 text-gray-900" /> : <Menu className="w-6 h-6 text-gray-900" />}
                </button>
            </div>

            {/* Mobile Menu */}
            <AnimatePresence>
                {mobileMenuOpen && (
                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: 20 }}
                        className="fixed inset-x-4 top-24 glass-thick p-8 rounded-[32px] md:hidden z-50 border-gray-100 shadow-2xl"
                    >
                        <div className="flex flex-col gap-6 text-center uppercase tracking-[0.3em] font-black text-xs text-gray-500">
                            <Link to="/" onClick={() => setMobileMenuOpen(false)} className="hover:text-blue-600 transition-colors">Home</Link>
                            <Link to="/about" onClick={() => setMobileMenuOpen(false)} className="hover:text-blue-600 transition-colors">About</Link>
                            <Link to="/faq" onClick={() => setMobileMenuOpen(false)} className="hover:text-blue-600 transition-colors">FAQ</Link>
                            <Link to="/contact" onClick={() => setMobileMenuOpen(false)} className="hover:text-blue-600 transition-colors">Contact</Link>
                            <div className="pt-4">
                                <a
                                    href="https://play.google.com/store/apps/details?id=com.cashsify.android"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="btn-primary flex items-center justify-center gap-2 !py-4"
                                >
                                    Download Now <Download className="w-5 h-5" />
                                </a>
                            </div>
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
        </motion.nav>
    );
};

export default Navbar;
