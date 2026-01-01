-- Live Stream Schema for Matches
-- Run this in Supabase SQL Editor

-- Match Live Streams table
CREATE TABLE IF NOT EXISTS public.match_live_streams (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE NOT NULL,
  mux_stream_id TEXT NOT NULL UNIQUE,
  rtmp_url TEXT,
  hls_playback_url TEXT,
  status TEXT NOT NULL CHECK (status IN ('active', 'ended', 'failed')),
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ended_at TIMESTAMP WITH TIME ZONE,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_match_live_streams_match_id ON public.match_live_streams(match_id);
CREATE INDEX IF NOT EXISTS idx_match_live_streams_status ON public.match_live_streams(status);
CREATE INDEX IF NOT EXISTS idx_match_live_streams_mux_stream_id ON public.match_live_streams(mux_stream_id);

-- Enable RLS
ALTER TABLE public.match_live_streams ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view all live streams" ON public.match_live_streams;
DROP POLICY IF EXISTS "Users can create live streams" ON public.match_live_streams;
DROP POLICY IF EXISTS "Users can update own live streams" ON public.match_live_streams;
DROP POLICY IF EXISTS "Users can delete own live streams" ON public.match_live_streams;

-- Users can view all live streams
CREATE POLICY "Users can view all live streams"
  ON public.match_live_streams
  FOR SELECT
  USING (true);

-- Users can create live streams for matches they created
CREATE POLICY "Users can create live streams"
  ON public.match_live_streams
  FOR INSERT
  WITH CHECK (
    auth.uid() = created_by AND
    EXISTS (
      SELECT 1 FROM public.matches m
      WHERE m.id = match_id
      AND m.created_by = auth.uid()
    )
  );

-- Users can update their own live streams
CREATE POLICY "Users can update own live streams"
  ON public.match_live_streams
  FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

-- Users can delete their own live streams
CREATE POLICY "Users can delete own live streams"
  ON public.match_live_streams
  FOR DELETE
  USING (auth.uid() = created_by);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_match_live_streams_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at
DROP TRIGGER IF EXISTS trigger_update_match_live_streams_updated_at ON public.match_live_streams;
CREATE TRIGGER trigger_update_match_live_streams_updated_at
  BEFORE UPDATE ON public.match_live_streams
  FOR EACH ROW
  EXECUTE FUNCTION update_match_live_streams_updated_at();

-- Comments
COMMENT ON TABLE public.match_live_streams IS 'Live stream information for matches';
COMMENT ON COLUMN public.match_live_streams.mux_stream_id IS 'Mux live stream ID';
COMMENT ON COLUMN public.match_live_streams.rtmp_url IS 'RTMP ingest URL for streaming';
COMMENT ON COLUMN public.match_live_streams.hls_playback_url IS 'HLS playback URL for viewers';

