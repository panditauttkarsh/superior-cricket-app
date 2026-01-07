# Deploy Supabase Edge Function

## Step 1: Install Supabase CLI

```bash
# macOS
brew install supabase/tap/supabase

# Or using npm
npm install -g supabase
```

## Step 2: Login to Supabase

```bash
supabase login
```

## Step 3: Link to Your Project

```bash
cd flutter_app
supabase link --project-ref nhiyuosjiiabxxwpkpdi
```

## Step 4: Set the YouTube Stream Key Secret

```bash
supabase secrets set YOUTUBE_STREAM_KEY=your_youtube_stream_key_here
```

Replace `your_youtube_stream_key_here` with your actual YouTube stream key from YouTube Studio.

## Step 5: Deploy the Function

```bash
supabase functions deploy get-youtube-stream-key
```

## Step 6: Test the Function

Open in browser:
```
https://nhiyuosjiiabxxwpkpdi.supabase.co/functions/v1/get-youtube-stream-key
```

Expected response:
```json
{ "ok": true }
```

If you see this → Secrets are wired correctly! 🎯

## Alternative: Deploy via Supabase Dashboard

1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/nhiyuosjiiabxxwpkpdi)
2. Navigate to **Edge Functions**
3. Click **Create a new function**
4. Name it: `get-youtube-stream-key`
5. Copy the code from `supabase_functions/get-youtube-stream-key/index.ts`
6. Paste and deploy
7. Go to **Settings > Secrets**
8. Add secret: `YOUTUBE_STREAM_KEY` = your YouTube stream key

