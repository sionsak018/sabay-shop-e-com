import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from '../features/auth/hooks/useAuth';
import { Layout } from '../components/layout/Layout';
import { LoginPage } from '../features/auth/pages/LoginPage';
import { RegisterPage } from '../features/auth/pages/RegisterPage';
import { HomePage } from '../features/products/pages/HomePage';
import { CreateProductPage } from '../features/products/pages/CreateProductPage';
import { CartPage } from '../features/cart/pages/CartPage';
import { CheckoutPage } from '../features/cart/pages/CheckoutPage';
import { OrdersPage } from '../features/cart/pages/OrdersPage';
import { InboxPage } from '../features/messages/pages/InboxPage';
import { ProductDetailPage } from '../features/products/pages/ProductDetailPage';


const AppRoutes = () => {
  const { user, loading } = useAuth();
  if (loading) return <div>Loading...</div>;

  return (
    // src/routes/AppRoutes.tsx
<Routes>
  {/* Public routes */}
  <Route path="/login" element={!user ? <LoginPage /> : <Navigate to="/" />} />
  <Route path="/register" element={!user ? <RegisterPage /> : <Navigate to="/" />} />

  {/* Protected routes with layout */}
  <Route element={user ? <Layout /> : <Navigate to="/login" />}>
    <Route path="/" element={<HomePage />} />   {/* 👈 HomePage is the default */}
    <Route path="/sell" element={<CreateProductPage />} />
    <Route path="/cart" element={<CartPage />} />
    <Route path="/checkout" element={<CheckoutPage />} />
    <Route path="/orders" element={<OrdersPage />} />
    <Route path="/inbox" element={<InboxPage />} />
    <Route path="/product/:id" element={<ProductDetailPage />} />

  </Route>
</Routes>
  );
};

export default AppRoutes;