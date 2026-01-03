import React, { useEffect, Suspense, lazy } from 'react'
import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom'
import Navbar from './components/Navbar'
import Footer from './components/Footer'

// Lazy Load Pages
const Home = lazy(() => import('./pages/Home'))
const About = lazy(() => import('./pages/About'))
const Privacy = lazy(() => import('./pages/Privacy'))
const Terms = lazy(() => import('./pages/Terms'))
const Contact = lazy(() => import('./pages/Contact'))
const FAQ = lazy(() => import('./pages/FAQ'))
const Invite = lazy(() => import('./pages/Invite'))

// Loading Component
const PageLoader = () => (
  <div className="min-h-screen flex flex-col items-center justify-center bg-[#FCFCFD]">
    <div className="relative w-24 h-24 mb-8">
      <div className="absolute inset-0 bg-blue-500/10 rounded-full animate-ping"></div>
      <div className="relative z-10 w-full h-full bg-white rounded-[2rem] shadow-xl flex items-center justify-center border border-gray-100 p-4">
        <img src="/logo.png" alt="Loading..." className="w-full h-full object-contain animate-pulse" />
      </div>
    </div>
    <div className="text-sm font-black uppercase tracking-[0.3em] text-gray-400">Initializing</div>
  </div>
);

// Scroll to top on route change
const ScrollToTop = () => {
  const { pathname } = useLocation();
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);
  return null;
};

function App() {
  return (
    <Router>
      <ScrollToTop />
      <div className="min-h-screen flex flex-col font-sans">
        <Navbar />
        <main className="flex-grow relative">
          <Suspense fallback={<PageLoader />}>
            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/about" element={<About />} />
              <Route path="/privacy" element={<Privacy />} />
              <Route path="/terms" element={<Terms />} />
              <Route path="/contact" element={<Contact />} />
              <Route path="/faq" element={<FAQ />} />
              <Route path="/invite" element={<Invite />} />
            </Routes>
          </Suspense>
        </main>
        <Footer />
      </div>
    </Router>
  )
}

export default App
