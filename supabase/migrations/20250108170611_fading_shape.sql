/*
  # Initial Schema Setup for Social Worker App

  1. New Tables
    - profiles
      - id (uuid, primary key)
      - role (enum)
      - full_name (text)
      - created_at (timestamp)
    - tasks
      - id (uuid, primary key)
      - title (text)
      - description (text)
      - due_date (timestamp)
      - completed (boolean)
      - client_id (uuid, foreign key)
      - social_worker_id (uuid, foreign key)
      - created_at (timestamp)
    - messages
      - id (uuid, primary key)
      - content (text)
      - sender_id (uuid, foreign key)
      - receiver_id (uuid, foreign key)
      - created_at (timestamp)
      - read (boolean)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Create role enum type
CREATE TYPE user_role AS ENUM ('social_worker', 'client', 'admin');

-- Create profiles table
CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  role user_role NOT NULL,
  full_name text,
  created_at timestamptz DEFAULT now()
);

-- Create tasks table
CREATE TABLE tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  due_date timestamptz,
  completed boolean DEFAULT false,
  client_id uuid REFERENCES profiles(id),
  social_worker_id uuid REFERENCES profiles(id),
  created_at timestamptz DEFAULT now()
);

-- Create messages table
CREATE TABLE messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  content text NOT NULL,
  sender_id uuid REFERENCES profiles(id),
  receiver_id uuid REFERENCES profiles(id),
  created_at timestamptz DEFAULT now(),
  read boolean DEFAULT false
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Social workers can view client profiles"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'social_worker'
    )
  );

-- Tasks policies
CREATE POLICY "Users can view their own tasks"
  ON tasks
  FOR SELECT
  TO authenticated
  USING (
    client_id = auth.uid()
    OR social_worker_id = auth.uid()
  );

CREATE POLICY "Social workers can create tasks"
  ON tasks
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'social_worker'
    )
  );

CREATE POLICY "Social workers can update tasks"
  ON tasks
  FOR UPDATE
  TO authenticated
  USING (
    social_worker_id = auth.uid()
  );

-- Messages policies
CREATE POLICY "Users can view their own messages"
  ON messages
  FOR SELECT
  TO authenticated
  USING (
    sender_id = auth.uid()
    OR receiver_id = auth.uid()
  );

CREATE POLICY "Users can send messages"
  ON messages
  FOR INSERT
  TO authenticated
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can mark messages as read"
  ON messages
  FOR UPDATE
  TO authenticated
  USING (receiver_id = auth.uid())
  WITH CHECK (receiver_id = auth.uid());