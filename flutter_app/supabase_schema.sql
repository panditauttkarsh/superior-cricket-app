-- Supabase Database Schema for CricPlay App
-- Run this SQL in your Supabase SQL Editor to create all necessary tables

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT,
  username TEXT, -- Unique username (auto-generated from name)
  name TEXT,
  phone TEXT,
  profile_image_url TEXT,
  city TEXT,
  state TEXT,
  role TEXT, -- 'player', 'coach', 'admin', 'academy_owner'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT unique_email UNIQUE (email)
);

-- Players table
CREATE TABLE IF NOT EXISTS public.players (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  profile_image_url TEXT,
  city TEXT,
  state TEXT,
  role TEXT, -- 'batsman', 'bowler', 'all-rounder', 'wicket-keeper'
  batting_stats JSONB DEFAULT '{}',
  bowling_stats JSONB DEFAULT '{}',
  total_matches INTEGER DEFAULT 0,
  rating DECIMAL(3,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Teams table
CREATE TABLE IF NOT EXISTS public.teams (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT,
  city TEXT,
  state TEXT,
  logo_url TEXT,
  captain_id UUID REFERENCES public.players(id),
  captain_name TEXT,
  player_ids UUID[] DEFAULT '{}',
  total_matches INTEGER DEFAULT 0,
  wins INTEGER DEFAULT 0,
  losses INTEGER DEFAULT 0,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Matches table
CREATE TABLE IF NOT EXISTS public.matches (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  team1_id UUID REFERENCES public.teams(id),
  team2_id UUID REFERENCES public.teams(id),
  team1_name TEXT,
  team2_name TEXT,
  overs INTEGER NOT NULL,
  ground_type TEXT NOT NULL, -- 'turf', 'cement', 'matting'
  ball_type TEXT NOT NULL, -- 'leather', 'tennis'
  youtube_video_id TEXT,
  status TEXT NOT NULL DEFAULT 'upcoming', -- 'upcoming', 'live', 'completed'
  scheduled_at TIMESTAMP WITH TIME ZONE,
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  toss_winner_id UUID REFERENCES public.teams(id),
  toss_decision TEXT, -- 'bat', 'bowl'
  winner_id UUID REFERENCES public.teams(id),
  scorecard JSONB,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tournaments table
CREATE TABLE IF NOT EXISTS public.tournaments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE,
  status TEXT NOT NULL DEFAULT 'registration_open', -- 'registration_open', 'ongoing', 'completed'
  total_teams INTEGER,
  registered_teams INTEGER DEFAULT 0,
  prize_pool DECIMAL(10,2),
  location TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tournament registrations
CREATE TABLE IF NOT EXISTS public.tournament_registrations (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE,
  team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
  registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(tournament_id, team_id)
);

-- Academies table
CREATE TABLE IF NOT EXISTS public.academies (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  registration_fee DECIMAL(10,2),
  total_students INTEGER DEFAULT 0,
  active_programs INTEGER DEFAULT 0,
  avg_attendance DECIMAL(5,2),
  top_coaches INTEGER DEFAULT 0,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Shop items table
CREATE TABLE IF NOT EXISTS public.shop_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  price DECIMAL(10,2) NOT NULL,
  discount_price DECIMAL(10,2),
  category TEXT NOT NULL, -- 'bat', 'ball', 'gloves', 'helmet', 'shoes', etc.
  brand TEXT,
  stock INTEGER DEFAULT 0,
  rating DECIMAL(3,2),
  review_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Posts/Feed table
CREATE TABLE IF NOT EXISTS public.posts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT,
  image_url TEXT,
  video_url TEXT,
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Post likes
CREATE TABLE IF NOT EXISTS public.post_likes (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Post comments
CREATE TABLE IF NOT EXISTS public.post_comments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Orders table (for shop)
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  items JSONB NOT NULL, -- Array of {item_id, quantity, price}
  total_amount DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending', -- 'pending', 'confirmed', 'shipped', 'delivered', 'cancelled'
  shipping_address JSONB,
  payment_status TEXT DEFAULT 'pending', -- 'pending', 'paid', 'failed'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_matches_status ON public.matches(status);
CREATE INDEX IF NOT EXISTS idx_matches_team1 ON public.matches(team1_id);
CREATE INDEX IF NOT EXISTS idx_matches_team2 ON public.matches(team2_id);
CREATE INDEX IF NOT EXISTS idx_matches_created_by ON public.matches(created_by);
CREATE INDEX IF NOT EXISTS idx_teams_created_by ON public.teams(created_by);
CREATE INDEX IF NOT EXISTS idx_tournaments_status ON public.tournaments(status);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_shop_items_category ON public.shop_items(category);

-- Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- RLS Policies (Basic - adjust based on your security requirements)
-- Drop existing policies if they exist, then create new ones

-- Profiles: Users can read all, create own, update own
DROP POLICY IF EXISTS "Users can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can create own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can view all profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can create own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Matches: Users can read all, create own, update own
DROP POLICY IF EXISTS "Users can view all matches" ON public.matches;
DROP POLICY IF EXISTS "Users can create matches" ON public.matches;
DROP POLICY IF EXISTS "Users can update own matches" ON public.matches;
CREATE POLICY "Users can view all matches" ON public.matches FOR SELECT USING (true);
CREATE POLICY "Users can create matches" ON public.matches FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Users can update own matches" ON public.matches FOR UPDATE USING (auth.uid() = created_by);

-- Teams: Users can read all, create own, update own
DROP POLICY IF EXISTS "Users can view all teams" ON public.teams;
DROP POLICY IF EXISTS "Users can create teams" ON public.teams;
DROP POLICY IF EXISTS "Users can update own teams" ON public.teams;
CREATE POLICY "Users can view all teams" ON public.teams FOR SELECT USING (true);
CREATE POLICY "Users can create teams" ON public.teams FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Users can update own teams" ON public.teams FOR UPDATE USING (auth.uid() = created_by);

-- Tournaments: Users can read all, create own
DROP POLICY IF EXISTS "Users can view all tournaments" ON public.tournaments;
DROP POLICY IF EXISTS "Users can create tournaments" ON public.tournaments;
CREATE POLICY "Users can view all tournaments" ON public.tournaments FOR SELECT USING (true);
CREATE POLICY "Users can create tournaments" ON public.tournaments FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Shop items: Everyone can read
DROP POLICY IF EXISTS "Users can view all shop items" ON public.shop_items;
CREATE POLICY "Users can view all shop items" ON public.shop_items FOR SELECT USING (true);

-- Posts: Users can read all, create own, update own, delete own
DROP POLICY IF EXISTS "Users can view all posts" ON public.posts;
DROP POLICY IF EXISTS "Users can create posts" ON public.posts;
DROP POLICY IF EXISTS "Users can update own posts" ON public.posts;
DROP POLICY IF EXISTS "Users can delete own posts" ON public.posts;
CREATE POLICY "Users can view all posts" ON public.posts FOR SELECT USING (true);
CREATE POLICY "Users can create posts" ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own posts" ON public.posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own posts" ON public.posts FOR DELETE USING (auth.uid() = user_id);

-- Orders: Users can only see their own orders
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create own orders" ON public.orders;
CREATE POLICY "Users can view own orders" ON public.orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own orders" ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers to auto-update updated_at (drop if exists, then create)
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
DROP TRIGGER IF EXISTS update_players_updated_at ON public.players;
DROP TRIGGER IF EXISTS update_teams_updated_at ON public.teams;
DROP TRIGGER IF EXISTS update_matches_updated_at ON public.matches;
DROP TRIGGER IF EXISTS update_tournaments_updated_at ON public.tournaments;
DROP TRIGGER IF EXISTS update_academies_updated_at ON public.academies;
DROP TRIGGER IF EXISTS update_shop_items_updated_at ON public.shop_items;
DROP TRIGGER IF EXISTS update_posts_updated_at ON public.posts;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_players_updated_at BEFORE UPDATE ON public.players FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON public.teams FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_matches_updated_at BEFORE UPDATE ON public.matches FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tournaments_updated_at BEFORE UPDATE ON public.tournaments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_academies_updated_at BEFORE UPDATE ON public.academies FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_shop_items_updated_at BEFORE UPDATE ON public.shop_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON public.posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- AUTHENTICATION & USERNAME HELPER FUNCTIONS
-- ============================================

-- Helper function to generate unique username
-- This function helps prevent race conditions when generating usernames
CREATE OR REPLACE FUNCTION generate_unique_username(base_name TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_name TEXT;
  username TEXT;
  counter INTEGER := 0;
  max_attempts INTEGER := 1000;
BEGIN
  -- Clean the base name: lowercase, remove spaces and special chars
  clean_name := lower(regexp_replace(base_name, '[^a-z0-9]', '', 'g'));
  
  -- Ensure minimum length
  IF length(clean_name) = 0 THEN
    clean_name := 'user';
  END IF;
  
  -- Limit length to 20 characters
  IF length(clean_name) > 20 THEN
    clean_name := substring(clean_name, 1, 20);
  END IF;
  
  -- Try to find a unique username
  username := clean_name;
  
  WHILE counter < max_attempts LOOP
    -- Check if username exists
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE username = username) THEN
      RETURN username;
    END IF;
    
    -- Append number
    counter := counter + 1;
    IF length(clean_name) + length(counter::TEXT) <= 20 THEN
      username := clean_name || counter::TEXT;
    ELSE
      username := 'user' || counter::TEXT;
    END IF;
  END LOOP;
  
  -- Fallback: use timestamp
  RETURN 'user' || extract(epoch from now())::BIGINT::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Function to check if email exists (for preventing duplicate accounts)
CREATE OR REPLACE FUNCTION email_exists(check_email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE LOWER(TRIM(email)) = LOWER(TRIM(check_email))
  );
END;
$$ LANGUAGE plpgsql;

-- Function to check if username exists
CREATE OR REPLACE FUNCTION username_exists(check_username TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE LOWER(TRIM(username)) = LOWER(TRIM(check_username))
  );
END;
$$ LANGUAGE plpgsql;

-- Index for faster email lookups
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(LOWER(TRIM(email)));

-- Index for faster username lookups (partial index for non-null usernames)
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_username_unique ON public.profiles(LOWER(TRIM(username))) WHERE username IS NOT NULL;

