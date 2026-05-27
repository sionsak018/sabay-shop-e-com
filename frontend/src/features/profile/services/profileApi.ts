import api from '../../../services/api';
import {type User } from '../../auth/types/auth.types';

export const profileApi = {
  update: (data: { name: string; phone: string }) => api.put<User>('/profile', data),
};