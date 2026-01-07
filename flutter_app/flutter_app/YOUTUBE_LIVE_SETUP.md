# YouTube Live Streaming Setup Guide

This guide explains how to set up YouTube Live streaming inside the PITCH POINT app.

## Overview

The app uses YouTube IFrame Player embedded in a WebView to play live streams directly inside the app, without opening external browsers or the YouTube app.

## Prerequisites

1. **YouTube Data API v3 Key**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select an existing one
   - Enable "YouTube Data API v3"
   - Go to Credentials → Create Credentials → API Key
   - Copy your API key

2. **YouTube Channel**
   - Your channel should be set up for live streaming
   - Channel handle: `@PITCH-POINT` (or your channel handle)

## Setup Steps

### 1. Configure YouTube API Key

1. Open `flutter_app/lib/core/config/youtube_config.dart`
2. Replace `YOUR_YOUTUBE_API_KEY` with your actual API key:
   ```dart
   static const String apiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```

### 2. Install Dependencies

The required package `webview_flutter` is already added to `pubspec.yaml`. Run:

```bash
cd flutter_app
flutter pub get
```

### 3. Usage

#### Navigate to Live Screen

```dart
// Navigate to live screen (checks @PITCH-POINT channel by default)
context.push('/live');

// Or specify a channel handle
context.push('/live?channel=@PITCH-POINT');

// Or provide video ID directly
context.push('/live?videoId=YOUR_VIDEO_ID');
```

#### Use LiveStreamButton Widget

```dart
LiveStreamButton(
  channelHandle: '@PITCH-POINT',
  label: 'Watch Live',
)
```

## How It Works

1. **Check Live Status**: The app uses YouTube Data API v3 to check if the channel is currently live streaming
2. **Get Video ID**: If live, it fetches the active live video ID
3. **Embed Player**: Loads YouTube IFrame Player in a WebView with:
   - `autoplay=1` - Automatically starts playback
   - `playsinline=1` - Plays inline (not fullscreen)
   - `rel=0` - Doesn't show related videos
   - `modestbranding=1` - Minimal YouTube branding
4. **Prevent External Navigation**: WebView is configured to block all navigation outside YouTube embed URLs

## Features

- ✅ In-app playback (no external browser/app)
- ✅ Autoplay on load
- ✅ Live status checking
- ✅ "Live Not Started" state when offline
- ✅ Error handling and retry
- ✅ Live indicator badge
- ✅ Refresh button to check for new streams

## API Quota

YouTube Data API v3 has a default quota of 10,000 units per day. Each search request costs 100 units, so you can make approximately 100 live status checks per day.

To increase quota:
1. Go to Google Cloud Console
2. Navigate to APIs & Services → Quotas
3. Request quota increase if needed

## Troubleshooting

### "Live Not Started" when stream is active
- Check that your API key is correct
- Verify the channel handle is correct
- Ensure YouTube Data API v3 is enabled
- Check API quota hasn't been exceeded

### Video doesn't autoplay
- Some browsers/devices require user interaction for autoplay
- The WebView should handle this automatically
- If issues persist, check WebView permissions

### Navigation blocked errors
- This is expected behavior - the app prevents opening external browsers
- Only YouTube embed URLs are allowed

## Security Notes

- **DO NOT** commit your API key to version control
- Consider using environment variables or secure storage for production
- The current implementation stores the key in code (acceptable for development)

## Testing

1. Start a live stream on your YouTube channel
2. Open the app and navigate to `/live`
3. The stream should load and autoplay automatically
4. If no stream is active, you'll see "Live Not Started" message

