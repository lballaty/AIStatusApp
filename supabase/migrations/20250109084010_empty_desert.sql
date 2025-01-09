/*
  # Assessment Configuration Schema

  1. New Tables
    - `assessment_types`
      - `id` (uuid, primary key)
      - `name` (text)
      - `description` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `categories`
      - `id` (uuid, primary key)
      - `assessment_type_id` (uuid, foreign key)
      - `name` (text)
      - `description` (text)
      - `default_value` (integer)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on both tables
    - Add policies for authenticated users
*/

-- Create assessment_types table
CREATE TABLE assessment_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create categories table
CREATE TABLE categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_type_id uuid REFERENCES assessment_types(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  default_value integer NOT NULL DEFAULT 3,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT default_value_range CHECK (default_value >= 1 AND default_value <= 5)
);

-- Enable RLS
ALTER TABLE assessment_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Create policies for assessment_types
CREATE POLICY "Users can view assessment types"
  ON assessment_types
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Social workers can manage assessment types"
  ON assessment_types
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'social_worker'
    )
  );

-- Create policies for categories
CREATE POLICY "Users can view categories"
  ON categories
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Social workers can manage categories"
  ON categories
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'social_worker'
    )
  );

-- Create indexes
CREATE INDEX categories_assessment_type_id_idx ON categories(assessment_type_id);