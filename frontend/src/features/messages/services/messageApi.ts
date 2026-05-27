import api from '../../../services/api';
import {type Message } from '../types/message.types';

export const messageApi = {
  getConversations: () => api.get<Message[]>('/messages'),
  sendMessage: (to_user_id: number, message: string, product_id?: number) =>
    api.post('/messages', { to_user_id, message, product_id }),
  markAsRead: (id: number) => api.put(`/messages/${id}/read`),
};