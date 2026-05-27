export interface Message {
  id: number;
  from_user_id: number;
  to_user_id: number;
  product_id: number | null;
  message: string;
  is_read: boolean;
  created_at: string;
  from_user: { id: number; name: string; avatar?: string };
  to_user: { id: number; name: string };
  product?: { id: number; title: string };
}