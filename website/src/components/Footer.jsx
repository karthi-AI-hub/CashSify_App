import React from 'react';
import { ShieldCheck, Mail, Globe, Twitter, ArrowUpRight, Zap, Target, Star } from 'lucide-react';
import { Link } from 'react-router-dom';

const Footer = () => {
    return (
        <footer className="bg-gray-50 pt-32 pb-16 px-6 border-t border-gray-100">
            <div className="container mx-auto grid grid-cols-1 md:grid-cols-12 gap-16 mb-24">
                <div className="md:col-span-12 lg:col-span-6">
                    <Link to="/" className="flex items-center gap-3 mb-8">
                        <img src="/logo.png" alt="Logo" className="w-12 h-12" />
                        <span className="text-2xl font-black tracking-tighter text-gray-900">Watch2Earn</span>
                    </Link>
                    <p className="text-gray-500 text-lg font-light leading-relaxed mb-10 max-w-sm italic">
                        Architecting the infrastructure of digital value. A premier ecosystem engineered for sovereign asset appreciation across the global marketplace.
                    </p>
                </div>

                <div className="md:col-span-4 lg:col-span-3">
                    <h4 className="text-gray-900 font-black mb-10 uppercase text-xs tracking-[0.4em]">Engine</h4>
                    <ul className="space-y-6 text-gray-500 text-sm font-medium">
                        <li><Link to="/faq" className="hover:text-blue-400 transition-colors flex items-center gap-2">How it works <ArrowUpRight className="w-3 h-3" /></Link></li>
                        <li>
                            <a
                                href="https://play.google.com/store/apps/details?id=com.cashsify.android"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="hover:text-blue-400 transition-colors flex items-center gap-2"
                            >
                                Mobile App <ArrowUpRight className="w-3 h-3" />
                            </a>
                        </li>
                        <li><Link to="/about" className="hover:text-blue-400 transition-colors">Philosophy</Link></li>
                        <li><Link to="/contact" className="hover:text-blue-400 transition-colors">Contact Support</Link></li>
                        <li><a href="#" className="hover:text-blue-400 transition-colors">Global Stats</a></li>
                    </ul>
                </div>

                <div className="md:col-span-4 lg:col-span-3">
                    <h4 className="text-gray-900 font-black mb-10 uppercase text-xs tracking-[0.4em]">Protocols</h4>
                    <ul className="space-y-6 text-gray-500 text-sm font-medium">
                        <li><Link to="/privacy" className="hover:text-blue-400 transition-colors">Privacy Policy</Link></li>
                        <li><Link to="/terms" className="hover:text-blue-400 transition-colors">Terms of Service</Link></li>
                    </ul>
                </div>
            </div>

            <div className="container mx-auto pt-16 border-t border-gray-100 flex flex-col md:flex-row justify-center items-center gap-8">
                <p className="text-gray-400 text-xs font-black uppercase tracking-[0.2em]">
                    © {new Date().getFullYear()} WATCH2EARN GLOBAL ELITE • ALL RIGHTS RESERVED
                </p>
            </div>
        </footer>
    );
};

export default Footer;
