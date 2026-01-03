import React from 'react';
import Hero from '../components/Hero';
import Features from '../components/Features';
import AppShowcase from '../components/AppShowcase';
import FAQ from '../components/FAQ';
import { motion, useScroll, useSpring } from 'framer-motion';
import { ShieldCheck, Globe, Zap, Star } from 'lucide-react';

function Home() {
  const { scrollYProgress } = useScroll();
  const scaleX = useSpring(scrollYProgress, {
    stiffness: 100,
    damping: 30,
    restDelta: 0.001
  });

  return (
    <div className="relative">
      {/* Scroll Progress Bar */}
      <motion.div
        className="fixed top-0 left-0 right-0 h-1 bg-gradient-to-r from-blue-500 via-indigo-500 to-emerald-500 z-[100] origin-left"
        style={{ scaleX }}
      />

      <Hero />


      <Features />
      <AppShowcase />

      {/* Social Proof / Global Reach Section */}
      <section className="py-32 px-6 relative overflow-hidden bg-slate-50 bg-grid-slate">
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full h-full bg-blue-500/5 blur-[120px] rounded-full" />
        <div className="container mx-auto text-center relative z-10">
          <h2 className="text-4xl md:text-5xl font-black mb-16 tracking-[-0.03em] text-gray-900">Trusted by a <span className="text-gradient-blue">Global Community.</span></h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-12 max-w-5xl mx-auto">
            <div className="hover:scale-110 transition-transform duration-500">
              <div className="text-5xl font-black mb-2 tracking-[-0.05em] text-gray-900">1M+</div>
              <div className="text-gray-500 text-[10px] uppercase tracking-[0.4em] font-bold">Onboarded Participants</div>
            </div>
            <div className="hover:scale-110 transition-transform duration-500">
              <div className="text-5xl font-black mb-2 tracking-[-0.05em] text-gray-900">$5M+</div>
              <div className="text-gray-500 text-[10px] uppercase tracking-[0.4em] font-bold">Value Distributed</div>
            </div>
            <div className="hover:scale-110 transition-transform duration-500">
              <div className="text-5xl font-black mb-2 tracking-[-0.05em] text-gray-900">150+</div>
              <div className="text-gray-500 text-[10px] uppercase tracking-[0.4em] font-bold">Global Jurisdictions</div>
            </div>
            <div className="hover:scale-110 transition-transform duration-500">
              <div className="text-5xl font-black mb-2 tracking-[-0.05em] text-gray-900">4.8/5</div>
              <div className="text-gray-500 text-[10px] uppercase tracking-[0.4em] font-bold">Trust Index Score</div>
            </div>
          </div>
        </div>
      </section>

      <FAQ />

      {/* Final Global CTA */}
      <section className="py-32 px-6">
        <div className="container mx-auto max-w-6xl">
          <div className="relative rounded-[60px] overflow-hidden shadow-2xl group bg-white border border-gray-100">
            <div className="absolute inset-0 bg-gradient-to-br from-blue-50/50 via-indigo-50/50 to-emerald-50/50 opacity-100" />
            <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-blue-100/40 blur-[120px] rounded-full pointer-events-none" />

            <div className="relative z-10 p-16 md:p-24 text-center">
              <div className="w-28 h-28 flex items-center justify-center mx-auto mb-10 bg-white rounded-3xl border border-gray-100 shadow-xl">
                <img src="/logo.png" alt="Logo" className="w-20 h-20 object-contain" />
              </div>
              <h2 className="text-5xl md:text-7xl font-black mb-8 leading-tight tracking-[-0.05em] text-gray-900">Architect Your <br />Passive Portfolio.</h2>
              <p className="text-xl text-gray-500 mb-12 max-w-2xl mx-auto font-light tracking-[-0.02em]">
                Secure your entry into the world's most innovative reward ecosystem, precision-engineered for the modern global economy.
              </p>
              <div className="flex flex-col sm:flex-row items-center justify-center gap-6">
                <a
                  href="https://play.google.com/store/apps/details?id=com.cashsify.android"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="btn-primary text-lg"
                >
                  Download Watch2Earn
                </a>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}

export default Home;
