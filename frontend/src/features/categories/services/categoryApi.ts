import api from '../../../services/api';
import {type Category } from '../types/category.types';

export const categoryApi = {
  getAll: () => api.get<Category[]>('/categories'),
};