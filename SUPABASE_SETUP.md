# Supabase Integration Setup Guide

This guide will help you set up Supabase for your Spot Carz Flutter app.

## 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up or log in to your account
3. Click "New Project"
4. Choose your organization
5. Enter project details:
   - Name: `spot-carz`
   - Database Password: (generate a strong password)
   - Region: Choose the closest to your users
6. Click "Create new project"

## 2. Get Your Project Credentials

1. In your Supabase dashboard, go to Settings > API
2. Copy the following values:
   - Project URL
   - Anon/Public Key

## 3. Update Your Flutter App

1. Open `lib/main.dart`
2. Replace the placeholder values:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL', // Replace with your Project URL
     anonKey: 'YOUR_SUPABASE_ANON_KEY', // Replace with your Anon Key
   );
   ```

## 4. Set Up Database Schema

1. In your Supabase dashboard, go to SQL Editor
2. Copy and paste the contents of `supabase_schema.sql`
3. Click "Run" to execute the SQL

This will create:
- `car_spots` table for storing car spot data
- Row Level Security (RLS) policies
- Storage bucket for car images
- Storage policies for image access

## 5. Configure Authentication

1. In Supabase dashboard, go to Authentication > Settings
2. Configure the following:
   - Site URL: `http://localhost:3000` (for development)
   - Redirect URLs: Add your app's redirect URLs
   - Email templates: Customize as needed

## 6. Set Up Storage

1. Go to Storage in your Supabase dashboard
2. You should see the `car-spots` bucket created by the SQL script
3. Configure CORS if needed for image uploads

## 7. Test Your Integration

1. Run your Flutter app: `flutter run`
2. Try registering a new account
3. Try logging in
4. Add a car spot with an image
5. Verify data appears in your Supabase dashboard

## 8. Environment Variables (Optional)

For production, consider using environment variables:

1. Create a `.env` file in your project root:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

2. Add `flutter_dotenv` to your dependencies
3. Load the environment variables in `main.dart`

## Database Schema

### car_spots table
- `id`: UUID primary key
- `user_id`: Foreign key to auth.users
- `brand`: Car brand (text)
- `model`: Car model (text)
- `year`: Car year (text)
- `image_url`: URL to uploaded image
- `date`: Date when car was spotted
- `created_at`: Timestamp when record was created
- `updated_at`: Timestamp when record was last updated

### Storage
- Bucket: `car-spots`
- Structure: `car-spots/{user_id}/{filename}`
- Public access for authenticated users only

## Security Features

- Row Level Security (RLS) ensures users can only access their own data
- Storage policies restrict image access to owners
- All database operations are authenticated
- Automatic timestamp updates

## Troubleshooting

### Common Issues

1. **Authentication not working**
   - Check your Supabase URL and anon key
   - Verify email confirmation is set up correctly

2. **Image upload fails**
   - Check storage bucket exists
   - Verify storage policies are correct
   - Check CORS settings

3. **Database operations fail**
   - Verify RLS policies are enabled
   - Check user authentication status
   - Verify table schema matches your code

### Getting Help

- Check the [Supabase documentation](https://supabase.com/docs)
- Join the [Supabase Discord](https://discord.supabase.com)
- Review the [Flutter Supabase documentation](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
