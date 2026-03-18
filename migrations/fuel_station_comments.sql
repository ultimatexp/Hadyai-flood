-- Create fuel station comments table
CREATE TABLE IF NOT EXISTS fuel_station_comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  station_id UUID NOT NULL REFERENCES fuel_stations(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  fingerprint TEXT,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_fuel_comments_station ON fuel_station_comments(station_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_fuel_comments_fingerprint ON fuel_station_comments(fingerprint, station_id, created_at DESC);

-- RLS
ALTER TABLE fuel_station_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read comments"
  ON fuel_station_comments FOR SELECT
  USING (true);

CREATE POLICY "Anyone can insert comments"
  ON fuel_station_comments FOR INSERT
  WITH CHECK (true);
