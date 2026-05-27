export interface Category {
  id: number;
  name: string;
  slug: string;
  parent_id: number | null;
  created_at?: string;
  updated_at?: string;
}