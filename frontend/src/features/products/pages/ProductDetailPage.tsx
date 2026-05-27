import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { productApi } from '../services/productApi';
import { messageApi } from '../../messages/services/messageApi';
import { type Product } from '../types/product.types';
import { useAuth } from '../../auth/context/AuthContext'; // use context, not local hook

export const ProductDetailPage = () => {
  const { id } = useParams<{ id: string }>();
  const { user } = useAuth();
  const navigate = useNavigate();
  const [product, setProduct] = useState<Product | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState('');
  const [showMessageBox, setShowMessageBox] = useState(false);

  useEffect(() => {
    if (id) {
      productApi.getOne(parseInt(id))
        .then(res => setProduct(res.data))
        .catch(err => {
          console.error('Failed to load product', err);
          setError(err.response?.data?.message || 'Product not found');
        })
        .finally(() => setLoading(false));
    }
  }, [id]);

  const handleSendMessage = async () => {
    if (!user) {
      navigate('/login');
      return;
    }
    if (!message.trim()) return;
    try {
      await messageApi.sendMessage(product!.seller.id, message, product!.id);
      alert('Message sent!');
      setMessage('');
      setShowMessageBox(false);
    } catch (error) {
      alert('Failed to send message');
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <p className="text-gray-500">Loading product...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center text-red-600">
        <p>{error}</p>
        <button onClick={() => window.location.reload()} className="mt-2 bg-blue-600 text-white px-4 py-2 rounded">
          Try Again
        </button>
      </div>
    );
  }

  if (!product) return <div>Product not found</div>;

  const coverImage = product.images?.[0]?.image_url
    ? `http://127.0.0.1:8000/storage/${product.images[0].image_url}`
    : 'https://via.placeholder.com/600x400?text=No+Image';

  return (
    <div className="max-w-4xl mx-auto p-4">
      <div className="border rounded-lg overflow-hidden shadow-lg">
        <img src={coverImage} alt={product.title} className="w-full h-96 object-cover" />
        <div className="p-6">
          <h1 className="text-3xl font-bold mb-2">{product.title}</h1>
          <p className="text-2xl text-blue-600 font-bold mb-4">
            ${typeof product.price === 'number' ? product.price.toFixed(2) : product.price}
          </p>
          <p className="text-gray-700 mb-4">{product.description}</p>
          <div className="flex justify-between items-center mb-4">
            <span className="text-sm bg-gray-200 px-2 py-1 rounded">{product.condition}</span>
            <span className="text-sm text-gray-500">{product.location}</span>
          </div>
          <div className="border-t pt-4">
            <h3 className="font-semibold mb-2">Seller: {product.seller?.name || 'Unknown'}</h3>
            {user && user.id !== product.seller?.id && (
              <div>
                {!showMessageBox ? (
                  <button 
                    onClick={() => setShowMessageBox(true)}
                    className="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700"
                  >
                    Message Seller
                  </button>
                ) : (
                  <div className="mt-2">
                    <textarea
                      value={message}
                      onChange={e => setMessage(e.target.value)}
                      placeholder="Ask the seller about this product..."
                      className="w-full border p-2 rounded"
                      rows={3}
                    />
                    <div className="flex gap-2 mt-2">
                      <button onClick={handleSendMessage} className="bg-blue-600 text-white px-4 py-2 rounded">
                        Send
                      </button>
                      <button onClick={() => setShowMessageBox(false)} className="bg-gray-300 px-4 py-2 rounded">
                        Cancel
                      </button>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};