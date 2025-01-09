/*
  # Fix profiles table RLS policies

  1. Changes
    - Drop existing insert policy
    - Create new insert policy that allows both authenticated and anon users
    - This enables profile creation during signup
*/

-- Drop the existing insert policy if it exists
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
EXCEPTION
  WHEN undefined_object THEN
    NULL;
END $$;

-- Create new insert policy that allows both authenticated and anon users
CREATE POLICY "Allow profile creation during signup"
  ON profiles
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);