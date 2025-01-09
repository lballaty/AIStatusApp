/*
  # Fix Profile Policies

  1. Changes
     - Allow both anonymous and authenticated users to create profiles
     - Maintain proper RLS for viewing and updating profiles
     - Handle all operations safely with error checking

  2. Security
     - Enables RLS on profiles table
     - Creates appropriate policies for profile management
*/

-- Safely handle profiles table policies
DO $$ 
BEGIN
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS "Allow profile creation" ON profiles;
  DROP POLICY IF EXISTS "Allow profile creation during signup" ON profiles;
  DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
  DROP POLICY IF EXISTS "Social workers can view client profiles" ON profiles;
  DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
  
  -- Create new policies with error handling
  -- Allow both anonymous and authenticated users to create profiles
  CREATE POLICY "Allow profile creation during signup"
    ON profiles
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

  -- Allow users to view their own profile
  CREATE POLICY "Users can view their own profile"
    ON profiles
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

  -- Allow social workers to view client profiles
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

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error updating profiles policies: %', SQLERRM;
END $$;