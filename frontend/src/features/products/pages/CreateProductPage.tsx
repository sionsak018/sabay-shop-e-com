import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { productApi } from '../services/productApi';

export const CreateProductPage = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    price: '',
    condition: 'new',
    location: '',
    category_id: '1', // hardcoded for now, later fetch categories
  });
  const [images, setImages] = useState<File[]>([]);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    const submitForm = new FormData();
    Object.entries(formData).forEach(([key, value]) => {
      submitForm.append(key, value);
    });
    images.forEach((img) => {
      submitForm.append('images[]', img);
    });

    try {
      await productApi.create(submitForm);
      navigate('/'); // redirect to home after success
    } catch (error) {
      console.error(error);
      alert('Failed to create product');
    } finally {
      setLoading(false);
    }
  };

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      setImages(Array.from(e.target.files));
    }
  };

  return (
    <div className="max-w-2xl mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">Sell an Item</h1>
      <form onSubmit={handleSubmit} className="space-y-4">
        <input type="text" placeholder="Title" required
          value={formData.title} onChange={e => setFormData({...formData, title: e.target.value})}
          className="w-full border p-2 rounded" />
        <textarea placeholder="Description" required rows={4}
          value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})}
          className="w-full border p-2 rounded" />
        <input type="number" placeholder="Price ($)" required
          value={formData.price} onChange={e => setFormData({...formData, price: e.target.value})}
          className="w-full border p-2 rounded" />
        <select value={formData.condition} onChange={e => setFormData({...formData, condition: e.target.value})}
          className="w-full border p-2 rounded">
          <option value="new">New</option>
          <option value="used">Used</option>
        </select>
        <input type="text" placeholder="Location" required
          value={formData.location} onChange={e => setFormData({...formData, location: e.target.value})}
          className="w-full border p-2 rounded" />
        <input type="file" multiple accept="image/*" onChange={handleImageChange}
          className="w-full border p-2 rounded" />
        <button type="submit" disabled={loading}
          className="bg-blue-600 text-white px-4 py-2 rounded disabled:bg-gray-400">
          {loading ? 'Creating...' : 'Create Listing'}
        </button>
      </form>
    </div>
  );
};