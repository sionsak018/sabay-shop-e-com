import { useAuth } from '../../auth/hooks/useAuth';
import { useState } from 'react';
import { profileApi } from '../services/profileApi';

export const ProfilePage = () => {
  const { user, updateUser } = useAuth();
  const [name, setName] = useState(user?.name || '');
  const [phone, setPhone] = useState(user?.phone || '');
  const [loading, setLoading] = useState(false);

  const handleUpdate = async () => {
    setLoading(true);
    try {
      const res = await profileApi.update({ name, phone });
      updateUser(res.data);
      alert('Profile updated');
    } catch (err) {
      alert('Update failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-md mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">My Profile</h1>
      <input value={name} onChange={e => setName(e.target.value)} className="border p-2 w-full mb-2" placeholder="Name" />
      <input value={phone} onChange={e => setPhone(e.target.value)} className="border p-2 w-full mb-2" placeholder="Phone" />
      <button onClick={handleUpdate} disabled={loading} className="bg-blue-600 text-white px-4 py-2 rounded w-full">
        {loading ? 'Saving...' : 'Save'}
      </button>
    </div>
  );
};