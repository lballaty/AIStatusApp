/*
  # Add email column to profiles table

  1. Changes
    - Add email column to profiles table if it doesn't exist
*/

DO $$ 
BEGIN
  -- Add email column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'profiles' 
    AND column_name = 'email'
  ) THEN
    ALTER TABLE profiles ADD COLUMN email text;
  END IF;
EXCEPTION
  WHEN undefined_table THEN
    -- Table doesn't exist yet, which is fine
    NULL;
END $$;