import { useCart } from '../hooks/useCart';
import { Link } from 'react-router-dom';

export const CartPage = () => {
  const { cart, loading, updateQuantity, removeItem, clearCart } = useCart();

  if (loading) return <div>Loading...</div>;
  if (!cart || cart.items.length === 0) return <div>Your cart is empty.</div>;

  const total = cart.items.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);

  return (
    <div className="max-w-4xl mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">Shopping Cart</h1>
      {cart.items.map(item => (
        <div key={item.id} className="flex gap-4 border-b py-4">
          <img src={item.product.images[0]?.image_url || '/placeholder.png'} className="w-24 h-24 object-cover" />
          <div className="flex-1">
            <h3 className="font-semibold">{item.product.title}</h3>
            <p>${item.product.price}</p>
            <div className="flex gap-2 mt-2">
              <input type="number" value={item.quantity} min={1}
                onChange={e => updateQuantity(item.id, parseInt(e.target.value))}
                className="w-16 border p-1 rounded" />
              <button onClick={() => removeItem(item.id)} className="text-red-600">Remove</button>
            </div>
          </div>
          <div className="font-bold">${item.product.price * item.quantity}</div>
        </div>
      ))}
      <div className="text-right mt-4">
        <button onClick={clearCart} className="text-red-600 mr-4">Clear Cart</button>
        <Link to="/checkout" className="bg-green-600 text-white px-6 py-2 rounded">Proceed to Checkout</Link>
      </div>
      <div className="text-xl font-bold mt-4">Total: ${total}</div>
    </div>
  );
};