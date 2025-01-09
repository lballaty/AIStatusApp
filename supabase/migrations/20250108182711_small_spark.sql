/*
  # Error Handling for Schema

  1. Purpose
    - Add error handling for existing schema
    - Ensure idempotent operations
    - Prevent disruption of existing data
    - Safe handling of type creation and policy updates

  2. Changes
    - Wrapped operations in DO blocks
    - Added existence checks
    - Proper error handling for each operation
*/

-- Safely handle user_role enum type
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('social_worker', 'client', 'admin');
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error creating enum type: %', SQLERRM;
END $$;

-- Safely handle profiles table policies
DO $$ 
BEGIN
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS "Allow profile creation" ON profiles;
  DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
  DROP POLICY IF EXISTS "Social workers can view client profiles" ON profiles;
  DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
  
  -- Create new policies with error handling
  CREATE POLICY "Allow profile creation"
    ON profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

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

  CREATE POLICY "Users can update their own profile"
    ON profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error updating profiles policies: %', SQLERRM;
END $$;

-- Ensure RLS is enabled on all tables
DO $$ 
BEGIN
  ALTER TABLE IF EXISTS profiles ENABLE ROW LEVEL SECURITY;
  ALTER TABLE IF EXISTS cases ENABLE ROW LEVEL SECURITY;
  ALTER TABLE IF EXISTS appointments ENABLE ROW LEVEL SECURITY;
  ALTER TABLE IF EXISTS case_notes ENABLE ROW LEVEL SECURITY;
  ALTER TABLE IF EXISTS assessments ENABLE ROW LEVEL SECURITY;
  ALTER TABLE IF EXISTS documents ENABLE ROW LEVEL SECURITY;
  ALTER TABLE IF EXISTS referrals ENABLE ROW LEVEL SECURITY;
  ALTER TABLE IF EXISTS goals ENABLE ROW LEVEL SECURITY;
  ALTER TABLE IF EXISTS resources ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error enabling RLS: %', SQLERRM;
END $$;

-- Add any missing columns to profiles table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'profiles' 
    AND column_name = 'email'
  ) THEN
    ALTER TABLE profiles ADD COLUMN email text;
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error adding email column: %', SQLERRM;
END $$;

-- Ensure proper indexes exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_indexes 
    WHERE tablename = 'profiles' 
    AND indexname = 'profiles_email_idx'
  ) THEN
    CREATE INDEX IF NOT EXISTS profiles_email_idx ON profiles(email);
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error creating index: %', SQLERRM;
END $$;