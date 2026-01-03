import React, { useEffect } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { ArrowRight, Download, Gift, ShieldCheck, Smartphone } from 'lucide-react';

const Invite = () => {
    const [searchParams] = useSearchParams();
    const navigate = useNavigate();
    const refCode = searchParams.get('ref');

    useEffect(() => {
        // Validation: Redirect to home if no referral code is present
        if (!refCode) {
            navigate('/', { replace: true });
        }
    }, [refCode, navigate]);

    if (!refCode) return null; // Prevent flash of content before redirect

    const playStoreUrl = `https://play.google.com/store/apps/details?id=com.cashsify.android&referrer=utm_source%3Dinvite%26utm_medium%3Dweb%26utm_content%3D${refCode}`;

    return (
        <div className="min-h-screen pt-20 pb-12 bg-slate-50 relative overflow-hidden">
            {/* Background Decor */}
            <div className="absolute inset-0 bg-grid-slate-900/[0.04] -z-10" />
            <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full h-[500px] bg-blue-500/20 blur-[120px] rounded-full mix-blend-multiply -z-10" />

            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="flex flex-col lg:flex-row items-center gap-12 lg:gap-24">

                    {/* Content Side */}
                    <div className="flex-1 text-center lg:text-left z-10">
                        <motion.div
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ duration: 0.5 }}
                        >
                            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-blue-50 border border-blue-100 text-blue-600 font-medium text-sm mb-6">
                                <Gift className="w-4 h-4" />
                                <span>You've been invited!</span>
                            </div>

                            <h1 className="text-4xl lg:text-6xl font-black text-slate-900 tracking-tight leading-tight mb-6">
                                Claim Your <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-600 to-indigo-600">Exclusive Bonus</span>
                            </h1>

                            <p className="text-lg text-slate-600 mb-8 leading-relaxed max-w-2xl mx-auto lg:mx-0">
                                You've been invited to join Watch2Earn. Accept this invitation to unlock special rewards and start earning passive income immediately.
                            </p>

                            <div className="flex flex-col sm:flex-row items-center gap-4 justify-center lg:justify-start">
                                <a
                                    href={playStoreUrl}
                                    className="group relative inline-flex items-center justify-center gap-3 px-8 py-4 bg-slate-900 text-white rounded-2xl font-bold text-lg hover:bg-slate-800 transition-all duration-300 hover:shadow-2xl hover:shadow-blue-500/20 w-full sm:w-auto"
                                >
                                    <Download className="w-5 h-5 group-hover:-translate-y-1 transition-transform" />
                                    <span>Accept & Install App</span>
                                    <ArrowRight className="w-4 h-4 opacity-50 group-hover:translate-x-1 transition-transform" />
                                </a>
                            </div>

                            <div className="mt-8 flex items-center justify-center lg:justify-start gap-6 text-sm text-slate-500 font-medium">
                                <div className="flex items-center gap-2">
                                    <ShieldCheck className="w-4 h-4 text-emerald-500" />
                                    <span>Verified Invite</span>
                                </div>
                                <div className="flex items-center gap-2">
                                    <Smartphone className="w-4 h-4 text-blue-500" />
                                    <span>Android Only</span>
                                </div>
                            </div>
                        </motion.div>
                    </div>

                    {/* Visual Side */}
                    <div className="flex-1 relative w-full flex justify-center lg:justify-end">
                        <motion.div
                            initial={{ opacity: 0, scale: 0.9 }}
                            animate={{ opacity: 1, scale: 1 }}
                            transition={{ duration: 0.7, delay: 0.2 }}
                            className="relative h-[500px] sm:h-[650px] aspect-[9/19] rounded-[3rem] border-8 border-slate-900 bg-slate-900 overflow-hidden shadow-2xl"
                        >
                            {/* Screen Content Mockup */}
                            <div className="absolute inset-0 bg-white">
                                <div className="absolute inset-0 bg-gradient-to-br from-blue-600 to-indigo-700 opacity-90" />
                                <div className="relative h-full flex flex-col items-center justify-center p-8 text-center text-white">
                                    <div className="w-20 h-20 bg-white/20 backdrop-blur-xl rounded-3xl flex items-center justify-center mb-6 shadow-lg">
                                        <Gift className="w-10 h-10 text-white" />
                                    </div>
                                    <h3 className="text-2xl font-bold mb-2">Welcome Bonus</h3>
                                    <p className="text-white/80 text-sm mb-8">Your 500 coin reward is ready to be claimed.</p>
                                    <div className="w-full bg-white/10 backdrop-blur-md rounded-2xl p-4 border border-white/20">
                                        <div className="text-xs uppercase tracking-wider opacity-70 mb-1">Referral Code</div>
                                        <div className="text-xl font-mono font-bold tracking-widest">APPLIED</div>
                                    </div>
                                </div>
                            </div>
                        </motion.div>

                        {/* Context Floating Elements */}
                        <motion.div
                            animate={{ y: [0, -20, 0] }}
                            transition={{ duration: 3, repeat: Infinity, ease: "easeInOut", delay: 1 }}
                            className="absolute -top-12 -right-12 w-24 h-24 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-3xl rotate-12 shadow-xl blur-sm opacity-40 -z-10"
                        />
                        <motion.div
                            animate={{ y: [0, 20, 0] }}
                            transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
                            className="absolute -bottom-8 -left-8 w-32 h-32 bg-blue-500 rounded-full blur-2xl opacity-20 -z-10"
                        />
                    </div>

                </div>
            </div>
        </div>
    );
};

export default Invite;
