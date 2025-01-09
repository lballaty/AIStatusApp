/*
  # Add Case Management Tables

  This migration adds the case management tables while handling existing objects safely.
  
  1. New Tables
    - cases
    - appointments
    - case_notes
    - assessments
    - documents
    - referrals
    - goals
    - resources

  2. Security
    - Enable RLS on all new tables
    - Add appropriate policies for each table
*/

-- Cases table
CREATE TABLE IF NOT EXISTS cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES profiles(id) NOT NULL,
  social_worker_id uuid REFERENCES profiles(id) NOT NULL,
  status text NOT NULL DEFAULT 'open',
  priority text NOT NULL DEFAULT 'medium',
  title text NOT NULL,
  description text,
  opened_at timestamptz DEFAULT now(),
  closed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Appointments table
CREATE TABLE IF NOT EXISTS appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid REFERENCES cases(id) NOT NULL,
  client_id uuid REFERENCES profiles(id) NOT NULL,
  social_worker_id uuid REFERENCES profiles(id) NOT NULL,
  title text NOT NULL,
  description text,
  start_time timestamptz NOT NULL,
  end_time timestamptz NOT NULL,
  location text,
  status text NOT NULL DEFAULT 'scheduled',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Case Notes table
CREATE TABLE IF NOT EXISTS case_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid REFERENCES cases(id) NOT NULL,
  author_id uuid REFERENCES profiles(id) NOT NULL,
  note_type text NOT NULL,
  content text NOT NULL,
  is_confidential boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Assessments table
CREATE TABLE IF NOT EXISTS assessments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid REFERENCES cases(id) NOT NULL,
  assessor_id uuid REFERENCES profiles(id) NOT NULL,
  assessment_type text NOT NULL,
  status text NOT NULL DEFAULT 'draft',
  content jsonb NOT NULL DEFAULT '{}',
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Documents table
CREATE TABLE IF NOT EXISTS documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid REFERENCES cases(id) NOT NULL,
  uploader_id uuid REFERENCES profiles(id) NOT NULL,
  filename text NOT NULL,
  file_type text NOT NULL,
  file_size integer NOT NULL,
  storage_path text NOT NULL,
  is_confidential boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Referrals table
CREATE TABLE IF NOT EXISTS referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid REFERENCES cases(id) NOT NULL,
  client_id uuid REFERENCES profiles(id) NOT NULL,
  social_worker_id uuid REFERENCES profiles(id) NOT NULL,
  service_type text NOT NULL,
  provider_name text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Goals table
CREATE TABLE IF NOT EXISTS goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid REFERENCES cases(id) NOT NULL,
  client_id uuid REFERENCES profiles(id) NOT NULL,
  title text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'in_progress',
  target_date timestamptz,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Resources table
CREATE TABLE IF NOT EXISTS resources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  category text NOT NULL,
  description text,
  contact_info jsonb NOT NULL DEFAULT '{}',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS on all new tables
DO $$ 
BEGIN
  ALTER TABLE cases ENABLE ROW LEVEL SECURITY;
  ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
  ALTER TABLE case_notes ENABLE ROW LEVEL SECURITY;
  ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;
  ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
  ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
  ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
  ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create policies for each table
DO $$ 
BEGIN
  -- Cases policies
  CREATE POLICY "Social workers can view assigned cases"
    ON cases FOR SELECT TO authenticated
    USING (social_worker_id = auth.uid() OR client_id = auth.uid());

  CREATE POLICY "Social workers can create cases"
    ON cases FOR INSERT TO authenticated
    WITH CHECK (EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'social_worker'
    ));

  CREATE POLICY "Social workers can update their cases"
    ON cases FOR UPDATE TO authenticated
    USING (social_worker_id = auth.uid());

  -- Appointments policies
  CREATE POLICY "Users can view their appointments"
    ON appointments FOR SELECT TO authenticated
    USING (client_id = auth.uid() OR social_worker_id = auth.uid());

  CREATE POLICY "Social workers can create appointments"
    ON appointments FOR INSERT TO authenticated
    WITH CHECK (EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'social_worker'
    ));

  CREATE POLICY "Social workers can update appointments"
    ON appointments FOR UPDATE TO authenticated
    USING (social_worker_id = auth.uid());

  -- Case Notes policies
  CREATE POLICY "Social workers can view case notes"
    ON case_notes FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM cases 
        WHERE cases.id = case_notes.case_id 
        AND (cases.social_worker_id = auth.uid() OR 
             (cases.client_id = auth.uid() AND NOT case_notes.is_confidential))
      )
    );

  CREATE POLICY "Social workers can create case notes"
    ON case_notes FOR INSERT TO authenticated
    WITH CHECK (EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'social_worker'
    ));

  -- Assessments policies
  CREATE POLICY "Users can view their assessments"
    ON assessments FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM cases 
        WHERE cases.id = assessments.case_id 
        AND (cases.social_worker_id = auth.uid() OR cases.client_id = auth.uid())
      )
    );

  CREATE POLICY "Social workers can create and update assessments"
    ON assessments FOR ALL TO authenticated
    USING (EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'social_worker'
    ));

  -- Documents policies
  CREATE POLICY "Users can view their documents"
    ON documents FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM cases 
        WHERE cases.id = documents.case_id 
        AND (cases.social_worker_id = auth.uid() OR 
             (cases.client_id = auth.uid() AND NOT documents.is_confidential))
      )
    );

  CREATE POLICY "Social workers can manage documents"
    ON documents FOR ALL TO authenticated
    USING (EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'social_worker'
    ));

  -- Referrals policies
  CREATE POLICY "Users can view their referrals"
    ON referrals FOR SELECT TO authenticated
    USING (client_id = auth.uid() OR social_worker_id = auth.uid());

  CREATE POLICY "Social workers can manage referrals"
    ON referrals FOR ALL TO authenticated
    USING (EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'social_worker'
    ));

  -- Goals policies
  CREATE POLICY "Users can view their goals"
    ON goals FOR SELECT TO authenticated
    USING (client_id = auth.uid() OR EXISTS (
      SELECT 1 FROM cases WHERE cases.id = goals.case_id AND cases.social_worker_id = auth.uid()
    ));

  CREATE POLICY "Social workers can manage goals"
    ON goals FOR ALL TO authenticated
    USING (EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'social_worker'
    ));

  -- Resources policies
  CREATE POLICY "Everyone can view active resources"
    ON resources FOR SELECT TO authenticated
    USING (is_active = true);

  CREATE POLICY "Social workers can manage resources"
    ON resources FOR ALL TO authenticated
    USING (EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'social_worker'
    ));
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;