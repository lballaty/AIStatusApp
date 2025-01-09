/*
  # Initial Database Setup

  1. New Tables
    - `profiles`
      - `id` (uuid, primary key) - References auth.users
      - `role` (user_role enum) - User's role in the system
      - `full_name` (text) - User's full name
      - `created_at` (timestamptz) - When the profile was created

  2. Security
    - Enable RLS on profiles table
    - Add policies for:
      - Users can view their own profile
      - Social workers can view client profiles
*/

-- Create role enum type if it doesn't exist
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('social_worker', 'client', 'admin');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  role user_role NOT NULL DEFAULT 'client',
  full_name text,
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
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

-- Allow users to update their own profile
CREATE POLICY "Users can update their own profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Allow insert during signup
CREATE POLICY "Enable insert for authenticated users only"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);