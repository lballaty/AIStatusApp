export interface User {
  id: string;
  email: string;
  role: 'social_worker' | 'client' | 'admin';
  created_at: string;
}

export interface Task {
  id: string;
  title: string;
  description: string;
  due_date: string;
  completed: boolean;
  client_id: string;
  social_worker_id: string;
  created_at: string;
}

export interface Message {
  id: string;
  content: string;
  sender_id: string;
  receiver_id: string;
  created_at: string;
  read: boolean;
}