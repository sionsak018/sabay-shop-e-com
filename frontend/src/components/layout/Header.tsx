

import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../features/auth/hooks/useAuth';

export const Header = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  // Helper to highlight active navigation states subtly
  const isActive = (path: string) => location.pathname === path;

  return (
    <header className="sticky top-0 z-50 w-full border-b border-gray-100 bg-white/80 backdrop-blur-md text-gray-900 antialiased">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 h-16 flex justify-between items-center max-w-7xl">
        
        {/* Logo Branding */}
        <Link 
          to="/" 
          className="text-xl font-bold tracking-tight bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent hover:opacity-90 transition"
        >
          Sabay Shop
        </Link>

        {/* Navigation & Action Area */}
        <nav className="flex items-center gap-1 sm:gap-4">
          {user ? (
            <>
              {/* Primary Store Links */}
              <div className="hidden md:flex items-center gap-1 mr-2 border-r border-gray-100 pr-4">
                <Link 
                  to="/orders" 
                  className={`px-3 py-2 text-sm font-medium rounded-lg transition-colors ${
                    isActive('/orders') ? 'bg-gray-50 text-gray-900' : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                  }`}
                >
                  Orders
                </Link>
                <Link 
                  to="/inbox" 
                  className={`px-3 py-2 text-sm font-medium rounded-lg transition-colors flex items-center gap-1.5 ${
                    isActive('/inbox') ? 'bg-gray-50 text-gray-900' : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                  }`}
                >
                  Messages
                  <span className="h-1.5 w-1.5 rounded-full bg-blue-600"></span>
                </Link>
              </div>

              {/* Shopping Cart Icon Action */}
              <Link 
                to="/cart" 
                className="p-2 text-gray-500 hover:text-gray-900 hover:bg-gray-50 rounded-xl transition relative"
                aria-label="Shopping Cart"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                </svg>
              </Link>

              {/* High-contrast Sell Button */}
              <Link 
                to="/sell" 
                className="ml-1 px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-xl transition shadow-sm shadow-blue-600/10 active:scale-[0.98]"
              >
                Sell Item
              </Link>

              {/* User Identity Info / Logout Wrapper */}
              <div className="flex items-center gap-3 pl-3 ml-2 border-l border-gray-100">
                <div className="hidden sm:flex flex-col text-right">
                  <span className="text-xs text-gray-400 font-medium">Welcome back</span>
                  <span className="text-sm font-semibold text-gray-700 max-w-[120px] truncate">{user.name}</span>
                </div>
                
                {/* Modern Avatar Ring Placeholder */}
                <div className="h-8 w-8 rounded-full bg-gradient-to-tr from-blue-500 to-indigo-500 flex items-center justify-center text-white text-xs font-bold shadow-sm select-none">
                  {user.name.charAt(0).toUpperCase()}
                </div>

                <button 
                  onClick={handleLogout} 
                  className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50/50 rounded-xl transition-all"
                  title="Logout"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 01-3-3h4a3 3 0 013 3v1" />
                  </svg>
                </button>
              </div>
            </>
          ) : (
            <>
              {/* Guest Actions */}
              <Link 
                to="/login" 
                className="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-xl transition"
              >
                Login
              </Link>
              <Link 
                to="/register" 
                className="px-4 py-2 text-sm font-medium text-white bg-gray-900 hover:bg-gray-800 rounded-xl transition shadow-sm active:scale-[0.98]"
              >
                Register
              </Link>
            </>
          )}
        </nav>
      </div>
    </header>
  );
};

// import { Link, useNavigate } from 'react-router-dom';
// import { useAuth } from '../../features/auth/hooks/useAuth';

// export const Header = () => {
//   const { user, logout } = useAuth();
//   const navigate = useNavigate();

//   const handleLogout = async () => {
//     await logout();
//     navigate('/login');
//   };

//   return (
//     <header className="bg-blue-600 text-white shadow-md">
//       <div className="container mx-auto px-4 py-3 flex justify-between items-center">
//         <Link to="/" className="text-xl font-bold">Sabay Shop</Link>
//         <nav className="flex gap-4">
//           {user ? (
//             <>
//               <Link to="/sell" className="hover:underline">Sell</Link>
//               <Link to="/cart" className="hover:underline">Cart</Link>
//               <Link to="/orders" className="hover:underline">Orders</Link>
//               <Link to="/inbox" className="hover:underline">Messages</Link>
//               <button onClick={handleLogout} className="hover:underline">Logout</button>
//               <span className="text-sm">Hi, {user.name}</span>
//             </>
//           ) : (
//             <>
//               <Link to="/login" className="hover:underline">Login</Link>
//               <Link to="/register" className="hover:underline">Register</Link>
//             </>
//           )}
//         </nav>
//       </div>
//     </header>
//   );
// };