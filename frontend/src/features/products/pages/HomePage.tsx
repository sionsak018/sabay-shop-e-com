
import { useState, useEffect, useRef } from 'react';
import { useProducts, type ProductFilters } from '../hooks/useProducts';
import { ProductCard } from '../components/ProductCard';
import { categoryApi } from '../../categories/services/categoryApi';
import { type Category } from '../../categories/types/category.types';

interface LocalFilters {
  keyword: string;
  category_id: string;
  min_price: string;
  max_price: string;
  location: string;
}

export const HomePage = () => {
  const [filters, setFilters] = useState<LocalFilters>({
    keyword: '',
    category_id: '',
    min_price: '',
    max_price: '',
    location: '',
  });
  const [activeFilters, setActiveFilters] = useState<LocalFilters>({
    keyword: '',
    category_id: '',
    min_price: '',
    max_price: '',
    location: '',
  });
  const [page, setPage] = useState(1);
  const [categories, setCategories] = useState<Category[]>([]);
  const topRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    categoryApi.getAll()
      .then(res => setCategories(res.data))
      .catch(err => console.error('Failed to load categories', err));
  }, []);

  const productFilters: ProductFilters = {
    keyword: activeFilters.keyword || undefined,
    category_id: activeFilters.category_id || undefined,
    min_price: activeFilters.min_price || undefined,
    max_price: activeFilters.max_price || undefined,
    location: activeFilters.location || undefined,
    page,
  };

  const { products, loading, error, pagination, refetch } = useProducts(productFilters);

  const handleSearch = () => {
    setPage(1);
    setActiveFilters({ ...filters });
    topRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleReset = () => {
    const emptyFilters = {
      keyword: '',
      category_id: '',
      min_price: '',
      max_price: '',
      location: '',
    };
    setFilters(emptyFilters);
    setActiveFilters(emptyFilters);
    setPage(1);
    topRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const goToPage = (newPage: number) => {
    if (newPage >= 1 && newPage <= pagination.lastPage) {
      setPage(newPage);
      topRef.current?.scrollIntoView({ behavior: 'smooth' });
    }
  };

  const getPageNumbers = () => {
    const current = pagination.currentPage;
    const last = pagination.lastPage;
    const delta = 2;
    const range: (number | string)[] = [];
    for (let i = Math.max(2, current - delta); i <= Math.min(last - 1, current + delta); i++) {
      range.push(i);
    }
    if (current - delta > 2) range.unshift('...');
    if (current + delta < last - 1) range.push('...');
    range.unshift(1);
    if (last !== 1) range.push(last);
    return range;
  };

  const pageNumbers = getPageNumbers();

  // Modern Skeleton Loader for a smooth fallback experience
  if (loading && products.length === 0) {
    return (
      <div className="container mx-auto px-6 py-12 max-w-7xl animate-pulse">
        <div className="h-9 w-48 bg-gray-200 rounded-lg mb-8"></div>
        <div className="h-32 bg-gray-100 rounded-2xl mb-8"></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
          {[...Array(8)].map((_, i) => (
            <div key={i} className="bg-gray-100 h-80 rounded-2xl"></div>
          ))}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col justify-center items-center h-96 text-center max-w-md mx-auto px-4">
        <div className="p-4 bg-red-50 text-red-500 rounded-full mb-4">
          <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        <h3 className="text-lg font-semibold text-gray-900 mb-1">Something went wrong</h3>
        <p className="text-gray-500 mb-6 text-sm">{error}</p>
        <button 
          onClick={() => refetch()} 
          className="w-full bg-gray-900 text-white font-medium py-2.5 px-5 rounded-xl hover:bg-gray-800 active:scale-[0.98] transition-all shadow-sm"
        >
          Try Again
        </button>
      </div>
    );
  }

  return (
    <div ref={topRef} className="container mx-auto px-4 sm:px-6 py-10 max-w-7xl text-gray-900 antialiased">
      
      {/* Header section */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">Discover Products</h1>
        <p className="mt-2 text-sm text-gray-500">Explore premium offerings tailored to your location and style.</p>
      </div>

      {/* Filter Card Container */}
      <div className="bg-white border border-gray-200 rounded-2xl mb-10 shadow-sm overflow-hidden">
        <div className="p-5 sm:p-6 lg:p-8">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            
            {/* Keyword Input */}
            <div className="relative">
              <span className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none text-gray-400">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
              </span>
              <input
                type="text"
                placeholder="Search products..."
                value={filters.keyword}
                onChange={(e) => setFilters({ ...filters, keyword: e.target.value })}
                className="w-full pl-10 pr-4 py-2.5 bg-gray-50/50 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-600/20 focus:border-blue-600 transition"
              />
            </div>

            {/* Category Select */}
            <div className="relative">
              <select
                value={filters.category_id}
                onChange={(e) => setFilters({ ...filters, category_id: e.target.value })}
                className="w-full px-4 py-2.5 bg-gray-50/50 border border-gray-200 rounded-xl text-sm appearance-none focus:outline-none focus:ring-2 focus:ring-blue-600/20 focus:border-blue-600 transition text-gray-700"
              >
                <option value="">All Categories</option>
                {categories.map((cat) => (
                  <option key={cat.id} value={cat.id}>{cat.name}</option>
                ))}
              </select>
              <span className="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none text-gray-400">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"/></svg>
              </span>
            </div>

            {/* Min Price */}
            <div className="relative">
              <span className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none text-gray-400 text-sm">$</span>
              <input
                type="number"
                placeholder="Min price"
                value={filters.min_price}
                onChange={(e) => setFilters({ ...filters, min_price: e.target.value })}
                className="w-full pl-7 pr-4 py-2.5 bg-gray-50/50 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-600/20 focus:border-blue-600 transition"
              />
            </div>

            {/* Max Price */}
            <div className="relative">
              <span className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none text-gray-400 text-sm">$</span>
              <input
                type="number"
                placeholder="Max price"
                value={filters.max_price}
                onChange={(e) => setFilters({ ...filters, max_price: e.target.value })}
                className="w-full pl-7 pr-4 py-2.5 bg-gray-50/50 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-600/20 focus:border-blue-600 transition"
              />
            </div>

            {/* Location */}
            <div className="relative">
              <span className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none text-gray-400">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
                </svg>
              </span>
              <input
                type="text"
                placeholder="Location"
                value={filters.location}
                onChange={(e) => setFilters({ ...filters, location: e.target.value })}
                className="w-full pl-9 pr-4 py-2.5 bg-gray-50/50 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-600/20 focus:border-blue-600 transition"
              />
            </div>

          </div>

          {/* Action Buttons */}
          <div className="flex justify-end gap-3 mt-5 pt-4 border-t border-gray-100">
            <button
              onClick={handleReset}
              className="px-5 py-2 text-sm font-medium text-gray-600 hover:text-gray-900 bg-gray-100 hover:bg-gray-200/80 rounded-xl transition active:scale-[0.98]"
            >
              Reset Filters
            </button>
            <button
              onClick={handleSearch}
              className="px-6 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-xl transition shadow-sm shadow-blue-600/10 active:scale-[0.98]"
            >
              Apply Filters
            </button>
          </div>
        </div>
      </div>

      {/* Grid Content */}
      {products.length === 0 ? (
        <div className="text-center py-20 bg-gray-50 rounded-2xl border border-dashed border-gray-200 max-w-3xl mx-auto px-4">
          <svg className="mx-auto h-10 w-10 text-gray-400 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0a2 2 0 01-2 2H6a2 2 0 01-2-2m16 0l-3.586-3.586a2 2 0 00-2.828 0L16 11m-7 3l-3-3m0 0l-1.01-1.01m1.01 1.01L9 9m1.01 1.01L12 7" />
          </svg>
          <p className="text-gray-600 font-medium text-base mb-1">No products found</p>
          <p className="text-gray-400 text-sm">
            {activeFilters.keyword || activeFilters.category_id || activeFilters.min_price || activeFilters.max_price || activeFilters.location
              ? 'Try widening your search terms or adjustments.'
              : 'Be the first to list an item on the marketplace!'}
          </p>
        </div>
      ) : (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-x-6 gap-y-10">
            {products.map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>

          {/* Clean Modern Pagination Controls */}
          {pagination.lastPage > 1 && (
            <div className="flex justify-center items-center gap-1.5 mt-16 pt-6 border-t border-gray-100">
              <button
                onClick={() => goToPage(pagination.currentPage - 1)}
                disabled={pagination.currentPage === 1}
                className="p-2 text-gray-500 hover:text-gray-900 hover:bg-gray-100 rounded-lg disabled:opacity-30 disabled:hover:bg-transparent transition"
                aria-label="Previous page"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 19l-7-7 7-7"/></svg>
              </button>
              
              {pageNumbers.map((num, idx) => (
                <button
                  key={idx}
                  onClick={() => typeof num === 'number' && goToPage(num)}
                  className={`min-w-10 h-10 px-3 text-sm font-medium rounded-lg transition-all ${
                    num === pagination.currentPage
                      ? 'bg-blue-600 text-white shadow-sm shadow-blue-600/10'
                      : typeof num === 'number'
                      ? 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
                      : 'text-gray-400 cursor-default tracking-widest'
                  }`}
                  disabled={typeof num !== 'number'}
                >
                  {num}
                </button>
              ))}

              <button
                onClick={() => goToPage(pagination.currentPage + 1)}
                disabled={pagination.currentPage === pagination.lastPage}
                className="p-2 text-gray-500 hover:text-gray-900 hover:bg-gray-100 rounded-lg disabled:opacity-30 disabled:hover:bg-transparent transition"
                aria-label="Next page"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5l7 7-7 7"/></svg>
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
};

// src/features/products/pages/HomePage.tsx
// import { useState, useEffect, useRef } from 'react';
// import { useProducts, type ProductFilters } from '../hooks/useProducts';
// import { ProductCard } from '../components/ProductCard';
// import { categoryApi } from '../../categories/services/categoryApi';
// import { type Category } from '../../categories/types/category.types';

// interface LocalFilters {
//   keyword: string;
//   category_id: string;
//   min_price: string;
//   max_price: string;
//   location: string;
// }

// export const HomePage = () => {
//   const [filters, setFilters] = useState<LocalFilters>({
//     keyword: '',
//     category_id: '',
//     min_price: '',
//     max_price: '',
//     location: '',
//   });
//   const [activeFilters, setActiveFilters] = useState<LocalFilters>({
//     keyword: '',
//     category_id: '',
//     min_price: '',
//     max_price: '',
//     location: '',
//   });
//   const [page, setPage] = useState(1);
//   const [categories, setCategories] = useState<Category[]>([]);
//   const topRef = useRef<HTMLDivElement>(null);

//   useEffect(() => {
//     categoryApi.getAll()
//       .then(res => setCategories(res.data))
//       .catch(err => console.error('Failed to load categories', err));
//   }, []);

//   const productFilters: ProductFilters = {
//     keyword: activeFilters.keyword || undefined,
//     category_id: activeFilters.category_id || undefined,
//     min_price: activeFilters.min_price || undefined,
//     max_price: activeFilters.max_price || undefined,
//     location: activeFilters.location || undefined,
//     page,
//   };

//   const { products, loading, error, pagination, refetch } = useProducts(productFilters);

//   const handleSearch = () => {
//     setPage(1);
//     setActiveFilters({ ...filters });
//     topRef.current?.scrollIntoView({ behavior: 'smooth' });
//   };

//   const handleReset = () => {
//     const emptyFilters = {
//       keyword: '',
//       category_id: '',
//       min_price: '',
//       max_price: '',
//       location: '',
//     };
//     setFilters(emptyFilters);
//     setActiveFilters(emptyFilters);
//     setPage(1);
//     topRef.current?.scrollIntoView({ behavior: 'smooth' });
//   };

//   const goToPage = (newPage: number) => {
//     if (newPage >= 1 && newPage <= pagination.lastPage) {
//       setPage(newPage);
//       // Scroll to top immediately after clicking
//       topRef.current?.scrollIntoView({ behavior: 'smooth' });
//     }
//   };

//   const getPageNumbers = () => {
//     const current = pagination.currentPage;
//     const last = pagination.lastPage;
//     const delta = 2;
//     const range: (number | string)[] = [];
//     for (let i = Math.max(2, current - delta); i <= Math.min(last - 1, current + delta); i++) {
//       range.push(i);
//     }
//     if (current - delta > 2) range.unshift('...');
//     if (current + delta < last - 1) range.push('...');
//     range.unshift(1);
//     if (last !== 1) range.push(last);
//     return range;
//   };

//   const pageNumbers = getPageNumbers();

//   if (loading && products.length === 0) {
//     return (
//       <div className="flex justify-center items-center h-64">
//         <p className="text-gray-500">Loading products...</p>
//       </div>
//     );
//   }

//   if (error) {
//     return (
//       <div className="text-center text-red-600">
//         <p>{error}</p>
//         <button onClick={() => refetch()} className="mt-2 bg-blue-600 text-white px-4 py-2 rounded">
//           Retry
//         </button>
//       </div>
//     );
//   }

//   return (
//     <div ref={topRef} className="container mx-auto px-4 py-8">
//       <h1 className="text-3xl font-bold mb-6">Latest Products</h1>

//       {/* Search & Filters Section */}
//       <div className="bg-gray-50 p-4 rounded-lg mb-6 shadow-sm">
//         <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-3">
//           <input
//             type="text"
//             placeholder="Search by title or description..."
//             value={filters.keyword}
//             onChange={(e) => setFilters({ ...filters, keyword: e.target.value })}
//             className="border border-gray-300 rounded-md p-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
//           />
//           <select
//             value={filters.category_id}
//             onChange={(e) => setFilters({ ...filters, category_id: e.target.value })}
//             className="border border-gray-300 rounded-md p-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
//           >
//             <option value="">All Categories</option>
//             {categories.map((cat) => (
//               <option key={cat.id} value={cat.id}>
//                 {cat.name}
//               </option>
//             ))}
//           </select>
//           <input
//             type="number"
//             placeholder="Min price ($)"
//             value={filters.min_price}
//             onChange={(e) => setFilters({ ...filters, min_price: e.target.value })}
//             className="border border-gray-300 rounded-md p-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
//           />
//           <input
//             type="number"
//             placeholder="Max price ($)"
//             value={filters.max_price}
//             onChange={(e) => setFilters({ ...filters, max_price: e.target.value })}
//             className="border border-gray-300 rounded-md p-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
//           />
//           <input
//             type="text"
//             placeholder="Location"
//             value={filters.location}
//             onChange={(e) => setFilters({ ...filters, location: e.target.value })}
//             className="border border-gray-300 rounded-md p-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
//           />
//         </div>
//         <div className="flex justify-end gap-2 mt-3">
//           <button
//             onClick={handleSearch}
//             className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 transition"
//           >
//             Search
//           </button>
//           <button
//             onClick={handleReset}
//             className="bg-gray-300 text-gray-800 px-4 py-2 rounded-md hover:bg-gray-400 transition"
//           >
//             Reset
//           </button>
//         </div>
//       </div>

//       {/* Products Grid */}
//       {products.length === 0 ? (
//         <div className="text-center py-12">
//           <p className="text-gray-500 text-lg">
//             {activeFilters.keyword || activeFilters.category_id || activeFilters.min_price || activeFilters.max_price || activeFilters.location
//               ? 'No products match your filters.'
//               : 'No products available. Be the first to sell!'}
//           </p>
//         </div>
//       ) : (
//         <>
//           <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
//             {products.map((product) => (
//               <ProductCard key={product.id} product={product} />
//             ))}
//           </div>

//           {/* Numbered Pagination Controls */}
//           {pagination.lastPage > 1 && (
//             <div className="flex justify-center items-center gap-2 mt-8">
//               <button
//                 onClick={() => goToPage(pagination.currentPage - 1)}
//                 disabled={pagination.currentPage === 1}
//                 className="px-3 py-1 bg-gray-200 rounded disabled:opacity-50 hover:bg-gray-300"
//               >
//                 Prev
//               </button>
//               {pageNumbers.map((num, idx) => (
//                 <button
//                   key={idx}
//                   onClick={() => typeof num === 'number' && goToPage(num)}
//                   className={`px-3 py-1 rounded ${
//                     num === pagination.currentPage
//                       ? 'bg-blue-600 text-white'
//                       : typeof num === 'number'
//                       ? 'bg-gray-200 hover:bg-gray-300'
//                       : 'cursor-default'
//                   }`}
//                   disabled={typeof num !== 'number'}
//                 >
//                   {num}
//                 </button>
//               ))}
//               <button
//                 onClick={() => goToPage(pagination.currentPage + 1)}
//                 disabled={pagination.currentPage === pagination.lastPage}
//                 className="px-3 py-1 bg-gray-200 rounded disabled:opacity-50 hover:bg-gray-300"
//               >
//                 Next
//               </button>
//             </div>
//           )}
//         </>
//       )}
//     </div>
//   );
// };


// src/features/products/pages/HomePage.tsx
// import { useState, useEffect, useRef } from 'react';
// import { useProducts, type ProductFilters } from '../hooks/useProducts';
// import { ProductCard } from '../components/ProductCard';
// import { categoryApi } from '../../categories/services/categoryApi';
// import { type Category } from '../../categories/types/category.types';

// interface LocalFilters {
//   keyword: string;
//   category_id: string;
//   min_price: string;
//   max_price: string;
//   location: string;
// }

// const SkeletonCard = () => (
//   <div className="border rounded-lg overflow-hidden shadow animate-pulse">
//     <div className="w-full h-48 bg-gray-300"></div>
//     <div className="p-4">
//       <div className="h-5 bg-gray-300 rounded w-3/4 mb-2"></div>
//       <div className="h-4 bg-gray-300 rounded w-1/2 mb-2"></div>
//       <div className="h-4 bg-gray-300 rounded w-2/3 mb-4"></div>
//       <div className="flex justify-between items-center">
//         <div className="h-5 bg-gray-300 rounded w-1/3"></div>
//         <div className="h-5 bg-gray-300 rounded w-1/4"></div>
//       </div>
//       <div className="mt-3 w-full h-8 bg-gray-300 rounded"></div>
//     </div>
//   </div>
// );

// export const HomePage = () => {
//   const [filters, setFilters] = useState<LocalFilters>({
//     keyword: '',
//     category_id: '',
//     min_price: '',
//     max_price: '',
//     location: '',
//   });
//   const [activeFilters, setActiveFilters] = useState<LocalFilters>({
//     keyword: '',
//     category_id: '',
//     min_price: '',
//     max_price: '',
//     location: '',
//   });
//   const [page, setPage] = useState(1);
//   const [categories, setCategories] = useState<Category[]>([]);
//   const [allProducts, setAllProducts] = useState<any[]>([]);
//   const [loadingMore, setLoadingMore] = useState(false);
//   const [hasMore, setHasMore] = useState(true);
//   const topRef = useRef<HTMLDivElement>(null);
//   const loadMoreRef = useRef<HTMLDivElement>(null);

//   useEffect(() => {
//     categoryApi.getAll()
//       .then(res => setCategories(res.data))
//       .catch(err => console.error('Failed to load categories', err));
//   }, []);

//   // Reset everything when filters change
//   useEffect(() => {
//     setAllProducts([]);
//     setPage(1);
//     setHasMore(true);
//     setLoadingMore(false);
//   }, [activeFilters]);

//   const productFilters: ProductFilters = {
//     keyword: activeFilters.keyword || undefined,
//     category_id: activeFilters.category_id || undefined,
//     min_price: activeFilters.min_price || undefined,
//     max_price: activeFilters.max_price || undefined,
//     location: activeFilters.location || undefined,
//     page,
//   };

//   const { products, loading, error, pagination, refetch } = useProducts(productFilters);

//   // Append new products to accumulated list
//   useEffect(() => {
//     if (!loading && products.length > 0) {
//       if (page === 1) {
//         setAllProducts(products);
//       } else {
//         setAllProducts(prev => [...prev, ...products]);
//       }
//       setHasMore(page < pagination.lastPage);
//       setLoadingMore(false);
//     }
//   }, [products, loading, page, pagination.lastPage]);

//   // Infinite scroll observer
//   useEffect(() => {
//     if (!hasMore || loadingMore || loading) return;
//     const observer = new IntersectionObserver(
//       (entries) => {
//         if (entries[0].isIntersecting && !loading && !loadingMore && hasMore) {
//           setLoadingMore(true);
//           setPage(prev => prev + 1);
//         }
//       },
//       { threshold: 0.5 }
//     );
//     if (loadMoreRef.current) observer.observe(loadMoreRef.current);
//     return () => observer.disconnect();
//   }, [hasMore, loading, loadingMore]);

//   const handleSearch = () => {
//     setPage(1);
//     setActiveFilters({ ...filters });
//     topRef.current?.scrollIntoView({ behavior: 'smooth' });
//   };

//   const handleReset = () => {
//     const emptyFilters = {
//       keyword: '',
//       category_id: '',
//       min_price: '',
//       max_price: '',
//       location: '',
//     };
//     setFilters(emptyFilters);
//     setActiveFilters(emptyFilters);
//     setPage(1);
//     topRef.current?.scrollIntoView({ behavior: 'smooth' });
//   };

//   const displayProducts = allProducts.length > 0 ? allProducts : products;
//   const isInitialLoading = loading && page === 1 && allProducts.length === 0;

//   if (isInitialLoading) {
//     return (
//       <div className="container mx-auto px-4 py-8">
//         <h1 className="text-3xl font-bold mb-6">Latest Products</h1>
//         <div className="bg-gray-50 p-4 rounded-lg mb-6 shadow-sm">
//           <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-3">
//             {[...Array(5)].map((_, i) => (
//               <div key={i} className="h-10 bg-gray-200 rounded animate-pulse"></div>
//             ))}
//           </div>
//           <div className="flex justify-end gap-2 mt-3">
//             <div className="w-20 h-10 bg-gray-200 rounded animate-pulse"></div>
//             <div className="w-20 h-10 bg-gray-200 rounded animate-pulse"></div>
//           </div>
//         </div>
//         <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
//           {[...Array(8)].map((_, i) => (
//             <SkeletonCard key={i} />
//           ))}
//         </div>
//       </div>
//     );
//   }

//   if (error && allProducts.length === 0) {
//     return (
//       <div className="text-center text-red-600">
//         <p>{error}</p>
//         <button onClick={() => refetch()} className="mt-2 bg-blue-600 text-white px-4 py-2 rounded">
//           Retry
//         </button>
//       </div>
//     );
//   }

//   return (
//     <div ref={topRef} className="container mx-auto px-4 py-8">
//       <h1 className="text-3xl font-bold mb-6">Latest Products</h1>

//       {/* Search & Filters Section */}
//       <div className="bg-gray-50 p-4 rounded-lg mb-6 shadow-sm">
//         <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-3">
//           <input
//             type="text"
//             placeholder="Search by title or description..."
//             value={filters.keyword}
//             onChange={(e) => setFilters({ ...filters, keyword: e.target.value })}
//             className="border border-gray-300 rounded-md p-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
//           />
//           <select
//             value={filters.category_id}
//             onChange={(e) => setFilters({ ...filters, category_id: e.target.value })}
//             className="border border-gray-300 rounded-md p-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
//           >
//             <option value="">All Categories</option>
//             {categories.map((cat) => (
//               <option key={cat.id} value={cat.id}>{cat.name}</option>
//             ))}
//           </select>
//           <input
//             type="number"
//             placeholder="Min price ($)"
//             value={filters.min_price}
//             onChange={(e) => setFilters({ ...filters, min_price: e.target.value })}
//             className="border border-gray-300 rounded-md p-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
//           />
//           <input
//             type="number"
//             placeholder="Max price ($)"
//             value={filters.max_price}
//             onChange={(e) => setFilters({ ...filters, max_price: e.target.value })}
//             className="border border-gray-300 rounded-md p-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
//           />
//           <input
//             type="text"
//             placeholder="Location"
//             value={filters.location}
//             onChange={(e) => setFilters({ ...filters, location: e.target.value })}
//             className="border border-gray-300 rounded-md p-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
//           />
//         </div>
//         <div className="flex justify-end gap-2 mt-3">
//           <button onClick={handleSearch} className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 transition">Search</button>
//           <button onClick={handleReset} className="bg-gray-300 text-gray-800 px-4 py-2 rounded-md hover:bg-gray-400 transition">Reset</button>
//         </div>
//       </div>

//       {/* Products Grid */}
//       {displayProducts.length === 0 ? (
//         <div className="text-center py-12">
//           <p className="text-gray-500 text-lg">
//             {activeFilters.keyword || activeFilters.category_id || activeFilters.min_price || activeFilters.max_price || activeFilters.location
//               ? 'No products match your filters.'
//               : 'No products available. Be the first to sell!'}
//           </p>
//         </div>
//       ) : (
//         <>
//           <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
//             {displayProducts.map((product) => (
//               <ProductCard key={product.id} product={product} />
//             ))}
//             {/* Skeleton cards while loading more */}
//             {loadingMore && [...Array(4)].map((_, i) => <SkeletonCard key={`skeleton-${i}`} />)}
//           </div>

//           {/* Sentinel for infinite scroll */}
//           {hasMore && !loadingMore && <div ref={loadMoreRef} className="h-10 w-full" />}
//           {loadingMore && <div className="text-center text-gray-500 mt-4">Loading more products...</div>}
//           {!hasMore && displayProducts.length > 0 && (
//             <p className="text-center text-gray-500 mt-8">✨ You've reached the end ✨</p>
//           )}
//         </>
//       )}
//     </div>
//   );
// };