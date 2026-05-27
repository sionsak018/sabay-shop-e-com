import { Outlet } from 'react-router-dom';
import { Header } from './Header';

export const Layout = () => {
  return (
    // Flexbox structure ensures the footer pushes down if the main content is short
    <div className="flex flex-col min-h-screen bg-gray-50/40 text-gray-900 antialiased selection:bg-blue-500/10 selection:text-blue-600">
      
      {/* Global Navigation Shell */}
      <Header />
      
      {/* Main Content Arena */}
      <main className="flex-grow w-full">
        <Outlet />
      </main>
      
      {/* Modern Footnote Segment */}
      <footer className="w-full bg-white border-t border-gray-100 mt-auto">
        <div className="container mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4 text-sm text-gray-500">
            
            {/* Copyright block */}
            <div className="flex items-center gap-1.5 font-medium text-gray-600">
              <span>&copy; {new Date().getFullYear()} Sabay Shop</span>
              <span className="text-gray-300 select-none">&bull;</span>
              <span className="text-xs tracking-wide bg-gray-100 text-gray-600 px-2 py-0.5 rounded-md font-normal">C2C Marketplace</span>
            </div>

            {/* Micro-Navigation Privacy/Terms Links */}
            <div className="flex items-center gap-6 text-xs font-normal">
              <a href="#privacy" className="hover:text-gray-900 transition-colors">Privacy Policy</a>
              <a href="#terms" className="hover:text-gray-900 transition-colors">Terms of Service</a>
              <a href="#support" className="hover:text-gray-900 transition-colors">Support</a>
            </div>

          </div>
        </div>
      </footer>

    </div>
  );
};

// import { Outlet } from 'react-router-dom';
// import { Header } from './Header';

// export const Layout = () => {
//   return (
//     <div>
//       <Header />
//       <main className="min-h-screen">
//         <Outlet />
//       </main>
//       <footer className="bg-gray-100 text-center py-4 text-sm text-gray-600">
//         &copy; 2026 Sabay Shop – C2C Marketplace
//       </footer>
//     </div>
//   );
// };