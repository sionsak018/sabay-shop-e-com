import { type Product } from '../types/product.types';
import { useNavigate } from 'react-router-dom';

interface ProductCardProps {
  product: Product;
}

export const ProductCard = ({ product }: ProductCardProps) => {
  const navigate = useNavigate();

  const coverImage = product.images?.[0]?.image_url
    ? `http://127.0.0.1:8000/storage/${product.images[0].image_url}`
    : 'https://via.placeholder.com/300x200?text=No+Image';

  const price = typeof product.price === 'number' 
    ? product.price.toFixed(2) 
    : Number(product.price)?.toFixed(2) || '0.00';

  return (
    <div className="border rounded-lg overflow-hidden shadow hover:shadow-lg transition">
      <img src={coverImage} alt={product.title || 'Product'} className="w-full h-48 object-cover" />
      <div className="p-4">
        <h3 className="text-lg font-semibold truncate">{product.title || 'Untitled'}</h3>
        <p className="text-gray-600">${price}</p>
        <p className="text-sm text-gray-500">{product.location || 'No location'}</p>
        <div className="mt-2 flex justify-between items-center">
          <span className="text-xs bg-gray-200 px-2 py-1 rounded">
            {product.condition || 'used'}
          </span>
          <span className="text-xs text-gray-500">
            by {product.seller?.name || 'Unknown seller'}
          </span>
        </div>
        <button 
          onClick={() => navigate(`/product/${product.id}`)}
          className="mt-3 w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700"
        >
          View Details
        </button>
      </div>
    </div>
  );
};