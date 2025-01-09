import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import type { User } from '../types/database.types';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    console.log('AuthProvider: Initializing');
    
    // Check active sessions and sets the user
    supabase.auth.getSession().then(({ data: { session }, error }) => {
      if (error) {
        console.error('AuthProvider: Session check error:', error);
      }
      if (session?.user) {
        console.log('AuthProvider: Found existing session');
        setUser(session.user as User);
      } else {
        console.log('AuthProvider: No existing session');
      }
      setLoading(false);
    });

    // Listen for changes on auth state
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      console.log('AuthProvider: Auth state changed:', event);
      if (session?.user) {
        console.log('AuthProvider: User in session:', session.user.id);
        setUser(session.user as User);
      } else {
        console.log('AuthProvider: No user in session');
        setUser(null);
      }
      setLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const signIn = async (email: string, password: string) => {
    console.log('AuthProvider: Attempting sign in');
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) {
      console.error('AuthProvider: Sign in error:', error);
      throw error;
    }
    console.log('AuthProvider: Sign in successful');
  };

  const signUp = async (email: string, password: string) => {
    console.log('AuthProvider: Starting signup process');
    try {
      // First, create the auth user with metadata
      console.log('AuthProvider: Creating auth user');
      const { data: authData, error: signUpError } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            role: 'client',
            email: email
          }
        }
      });

      if (signUpError) {
        console.error('AuthProvider: Auth signup error:', signUpError);
        throw signUpError;
      }

      if (!authData.user) {
        console.error('AuthProvider: No user data after signup');
        throw new Error('Failed to create user account');
      }

      console.log('AuthProvider: Auth user created:', authData.user.id);

      // Add a small delay to ensure the auth user is fully created
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Create the profile
      console.log('AuthProvider: Creating user profile');
      const { error: profileError } = await supabase
        .from('profiles')
        .insert([
          {
            id: authData.user.id,
            role: 'client',
            email: email
          }
        ]);

      if (profileError) {
        console.error('AuthProvider: Profile creation error:', profileError);
        // Clean up by signing out
        await supabase.auth.signOut();
        throw new Error(`Failed to create user profile: ${profileError.message}`);
      }

      console.log('AuthProvider: Profile created successfully');
      setUser(authData.user as User);
      console.log('AuthProvider: Signup process completed successfully');

    } catch (error: any) {
      console.error('AuthProvider: Signup process error:', error);
      await supabase.auth.signOut();
      throw error;
    }
  };

  const signOut = async () => {
    console.log('AuthProvider: Signing out');
    const { error } = await supabase.auth.signOut();
    if (error) {
      console.error('AuthProvider: Sign out error:', error);
      throw error;
    }
    console.log('AuthProvider: Sign out successful');
  };

  return (
    <AuthContext.Provider value={{ user, loading, signIn, signUp, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}