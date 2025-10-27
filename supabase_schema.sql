-- Create car_spots table
CREATE TABLE car_spots (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  brand TEXT NOT NULL,
  model TEXT NOT NULL,
  year TEXT NOT NULL,
  image_url TEXT,
  date TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create storage bucket for car spot images
INSERT INTO storage.buckets (id, name, public) VALUES ('car-spots', 'car-spots', true);

-- Create RLS policies for car_spots table
ALTER TABLE car_spots ENABLE ROW LEVEL SECURITY;

-- Policy to allow users to insert their own car spots
CREATE POLICY "Users can insert their own car spots" ON car_spots
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy to allow users to view their own car spots
CREATE POLICY "Users can view their own car spots" ON car_spots
  FOR SELECT USING (auth.uid() = user_id);

-- Policy to allow users to update their own car spots
CREATE POLICY "Users can update their own car spots" ON car_spots
  FOR UPDATE USING (auth.uid() = user_id);

-- Policy to allow users to delete their own car spots
CREATE POLICY "Users can delete their own car spots" ON car_spots
  FOR DELETE USING (auth.uid() = user_id);

-- Create storage policies for car-spots bucket
CREATE POLICY "Users can upload their own car spot images" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'car-spots' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view their own car spot images" ON storage.objects
  FOR SELECT USING (bucket_id = 'car-spots' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update their own car spot images" ON storage.objects
  FOR UPDATE USING (bucket_id = 'car-spots' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own car spot images" ON storage.objects
  FOR DELETE USING (bucket_id = 'car-spots' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_car_spots_updated_at
  BEFORE UPDATE ON car_spots
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
