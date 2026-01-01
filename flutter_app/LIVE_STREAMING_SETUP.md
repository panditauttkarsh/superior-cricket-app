# Live Streaming Setup Guide

This guide explains how to set up the "Go Live" feature for matches using Mux and YouTube restreaming.

## Architecture Overview

1. **App captures video** from device camera
2. **Streams to Mux** via RTMP
3. **Mux provides HLS playback** URL for in-app viewing
4. **Mux simultaneously restreams** to YouTube (RTMP) using YouTube stream key
5. **YouTube stream key** is stored securely on backend, never exposed to app

## Prerequisites

### 1. Mux Account Setup

1. Go to [Mux Dashboard](https://dashboard.mux.com)
2. Create an account or log in
3. Navigate to **Settings > Access Tokens**
4. Create a new access token with **Full Access** permissions
5. Copy the **Token ID** and **Secret Key**

### 2. Configure Mux Credentials

Open `flutter_app/lib/core/config/mux_config.dart` and update:

```dart
static const String accessTokenId = 'YOUR_MUX_ACCESS_TOKEN_ID';
static const String secretKey = 'YOUR_MUX_SECRET_KEY';
```

### 3. YouTube Stream Key Setup

1. Go to [YouTube Studio](https://studio.youtube.com)
2. Navigate to **Go Live > Stream**
3. Copy your **Stream Key** (keep this secret!)
4. In Supabase Dashboard:
   - Go to **Edge Functions**
   - Navigate to `get-youtube-stream-key` function
   - Go to **Settings > Secrets**
   - Add secret: `YOUTUBE_STREAM_KEY` = your YouTube stream key

### 4. Database Setup

Run the SQL schema in Supabase SQL Editor:

```bash
# Run this file:
flutter_app/supabase_live_stream_schema.sql
```

This creates the `match_live_streams` table to store stream information.

### 5. Install Dependencies

```bash
cd flutter_app
flutter pub get
```

### 6. Deploy Supabase Edge Function

```bash
# Install Supabase CLI if not already installed
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy the function
supabase functions deploy get-youtube-stream-key
```

## How It Works

### For Match Creators (Streamers)

1. **Navigate to Match Details** page
2. **Click "GO LIVE"** button (only visible to match creator)
3. **Grant camera permission** when prompted
4. **Camera preview** appears
5. **Click "GO LIVE"** to start streaming
6. App:
   - Creates Mux live stream
   - Gets YouTube stream key from backend (secure)
   - Configures Mux to restream to YouTube
   - Starts RTMP streaming from camera to Mux
   - Saves stream info to database

### For Viewers

1. **Navigate to Match Details** page
2. If live stream is active, see **"Watch Live"** option
3. **Click to watch** - opens HLS player
4. Stream plays in-app (no external apps)

## Technical Details

### RTMP Streaming

The app uses `flutter_rtmp_publisher` to stream camera feed to Mux RTMP endpoint:

```
rtmp://rtmp.live.mux.com/app/{stream_key}
```

### Mux Simulcast

Mux automatically restreams to YouTube when configured with simulcast targets:

```json
{
  "simulcast_targets": [
    {
      "url": "rtmp://a.rtmp.youtube.com/live2",
      "stream_key": "YOUTUBE_STREAM_KEY",
      "passthrough": "youtube-restream"
    }
  ]
}
```

### HLS Playback

Viewers receive HLS playback URL from Mux:

```
https://stream.mux.com/{playback_id}.m3u8
```

This URL is used with Flutter's `video_player` package for in-app viewing.

## Security

- ✅ YouTube stream key is **NEVER** exposed to the app
- ✅ Stream key is stored in Supabase Edge Function secrets
- ✅ Only match creator can start live stream (verified in backend)
- ✅ RLS policies ensure proper access control

## Troubleshooting

### Camera Permission Denied

- Check app permissions in device settings
- Ensure `permission_handler` is properly configured

### Stream Not Starting

- Verify Mux credentials are correct
- Check network connection
- Ensure YouTube stream key is set in Supabase secrets

### YouTube Restream Not Working

- Verify YouTube stream key is correct
- Check Mux dashboard for simulcast status
- Ensure YouTube live stream is enabled in YouTube Studio

### Video Not Playing

- Check HLS URL is valid
- Verify stream status is "active" in database
- Check network connectivity

## Next Steps

1. **Test the flow**: Create a match and try going live
2. **Monitor Mux Dashboard**: Check stream status and quality
3. **Check YouTube**: Verify restream is working
4. **Optimize**: Adjust video quality, bitrate, etc. in Mux settings

## Notes

- RTMP streaming implementation (`flutter_rtmp_publisher`) may need additional setup
- Consider using WebRTC for lower latency (future enhancement)
- Monitor Mux usage to stay within free tier limits
- YouTube has stream key rotation - update in Supabase secrets when changed

