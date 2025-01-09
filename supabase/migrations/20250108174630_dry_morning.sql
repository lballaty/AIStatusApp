/*
  # Create profiles table and security policies

  1. Tables
    - Creates the profiles table with:
      - id (uuid, primary key)
      - role (enum: social_worker, client, admin)
      - email (text)
      - created_at (timestamp)

  2. Security
    - Enables RLS
    - Adds policies for:
      - Viewing own profile
      - Social workers viewing client profiles
      - Updating own profile
      - Creating profile during signup
*/

-- Create role enum type if it doesn't exist
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('social_worker', 'client', 'admin');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  role user_role NOT NULL DEFAULT 'client',
  email text,
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
DO $$ BEGIN
  -- Users can view their own profile
  CREATE POLICY "Users can view their own profile"
    ON profiles
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  -- Social workers can view client profiles
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
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  -- Users can update their own profile
  CREATE POLICY "Users can update their own profile"
    ON profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  -- Allow insert during signup
  CREATE POLICY "Enable insert for authenticated users only"
    ON profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;