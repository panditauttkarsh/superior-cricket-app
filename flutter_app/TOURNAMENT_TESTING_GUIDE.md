# Tournament Module Testing Guide

## 🎯 How to Test the Tournament Module

### Step 1: Setup Database (Required First)
1. Open **Supabase Dashboard** → **SQL Editor**
2. Run the SQL script: `supabase_tournament_schema.sql`
3. Create Storage Buckets:
   - Go to **Storage** → **Create Bucket**
   - Create `tournaments` bucket (Public: Yes, Authenticated Write: Yes)
   - Create `teams` bucket (Public: Yes, Authenticated Write: Yes)

### Step 2: Navigate to Tournaments

**Option 1: From Dashboard Quick Actions**
- Open the app
- On the **Dashboard** (Home screen)
- Look for **"Quick Actions"** section
- Tap the **"Tournaments"** button (trophy icon)

**Option 2: From Hamburger Menu**
- Tap the **hamburger menu** (☰) icon in the top-left
- Scroll to **"PROFILE"** section
- Tap **"Tournaments"**

**Option 3: Direct Navigation**
- The app will automatically check if you have a tournament
- If **NO tournament exists** → Opens **"Add A Tournament"** screen
- If **tournament exists** → Opens **Tournament Home** screen

### Step 3: Create Your First Tournament

1. **Fill Tournament Details:**
   - **Tournament Name*** (e.g., "Summer Cricket League")
   - **City*** (e.g., "Jammu")
   - **Ground*** (select from dropdown)
   - **Organizer Name*** (e.g., "SHIVAM GANJU")
   - **Organizer Number*** (10-digit mobile, e.g., "7889447881")

2. **Upload Images:**
   - Tap **"Add Tournament Banner"** → Choose from Gallery or Camera
   - Tap **"Add Tournament Logo"** → Choose from Gallery or Camera

3. **Select Dates:**
   - Tap **"Tournament Start Date"** → Select a future date
   - Tap **"Tournament End Date"** → Select a date after start date

4. **Select Options:**
   - **Tournament Category***: Open, Corporate, Community, School, College, Series, or Other
   - **Ball Type***: Leather, Tennis, or Other
   - **Pitch Type***: Matting, Rough, Cemented, or Astro-turf

5. **Register:**
   - Tap the **"Register"** button at the bottom
   - Wait for images to upload
   - Tournament will be created and you'll be navigated to **Tournament Home**

### Step 4: Tournament Home Screen

You'll see:
- **Tournament Header** with logo, name, and date range
- **5 Tabs**: Matches, Teams, Points Table, Leaderboard, Stats
- **Teams tab is selected by default**

### Step 5: Add Teams

**From Teams Tab:**

1. **Invite Captains:**
   - Scroll to **"Invite Captains to Add Teams"** section
   - Tap **"SHARE WITH CAPTAINS"** button
   - This opens the **Add Teams** screen

2. **Add Teams Screen Options:**

   **A. Invite Link:**
   - Toggle **Invite Link** ON/OFF
   - Tap **"Share"** to share via system share
   - Tap **"WhatsApp"** to share via WhatsApp
   - Captains can use this link to join the tournament

   **B. Add New Teams (Manual):**
   - Scroll to **"Add New Teams"** section
   - Tap the circular image area to upload **Team Logo** (optional)
   - Enter **Team Name** (e.g., "Brave Hearts")
   - Tap **"Add Team"** button
   - Team will be added to the tournament

   **C. QR Code:**
   - Scroll to **"Add via QR Code"** section
   - QR code is displayed automatically
   - Others can scan this to join

3. **View Teams:**
   - Go back to **Teams Tab**
   - You'll see the team count (e.g., "1 Teams")
   - Teams list will show all added teams

### Step 6: Test Navigation Flow

**First Time User (No Tournament):**
1. Tap **Tournaments** → Opens **Add Tournament** screen
2. Create tournament → Navigates to **Tournament Home**

**Existing User (Has Tournament):**
1. Tap **Tournaments** → Opens **Tournament Home** directly
2. Can view teams, matches, etc.

### Step 7: Test Validation

**Try these to test validation:**
- Leave required fields empty → Should show error
- Enter invalid mobile (not 10 digits) → Should show error
- Select end date before start date → Should show error
- Try to add team without name → Should show error

### Step 8: Test Image Upload

1. **Upload Tournament Banner:**
   - Tap banner area → Choose image
   - Image should appear in the preview
   - After registration, image should be uploaded to Supabase Storage

2. **Upload Tournament Logo:**
   - Tap logo area → Choose image
   - Image should appear in the preview
   - After registration, logo should appear in Tournament Home header

3. **Upload Team Logo:**
   - In Add Teams screen
   - Tap team logo area → Choose image
   - Image should appear in preview

## 📍 Navigation Paths

```
Dashboard
  └─ Quick Actions → Tournaments
       └─ /tournament (checks if tournament exists)
            ├─ NO tournament → /tournament/add (Add Tournament)
            │     └─ After create → /tournament/{id} (Tournament Home)
            │
            └─ HAS tournament → /tournament/{id} (Tournament Home)
                  └─ Teams Tab → "SHARE WITH CAPTAINS" or "ADD MANUALLY"
                       └─ /tournament/{id}/add-teams (Add Teams Screen)
```

## ✅ Expected Behavior

### ✅ Should Work:
- Navigate to Tournaments from dashboard
- Create tournament with all fields
- Upload images (banner and logo)
- Add teams manually
- Share invite link
- View QR code
- See teams list
- Navigate between tabs

### ⚠️ Known Limitations:
- QR code scanning is disabled (package issue)
- My Teams feature is placeholder (needs implementation)
- Matches, Points Table, Leaderboard, Stats tabs are placeholders

## 🐛 Troubleshooting

**If tournament doesn't appear:**
- Check if database schema was run
- Check if user is logged in
- Check Supabase logs for errors

**If images don't upload:**
- Check if storage buckets exist
- Check bucket permissions (public read, authenticated write)
- Check Supabase logs for upload errors

**If navigation doesn't work:**
- Check if route is registered in `app_router.dart`
- Check console for navigation errors

## 📝 Next Steps After Testing

1. **Add Teams via Invite Link:**
   - Share the invite link with another user
   - They should be able to join the tournament

2. **Test Team Management:**
   - Add multiple teams
   - Verify team count updates
   - Check teams appear in list

3. **Test Tournament Persistence:**
   - Close and reopen app
   - Navigate to Tournaments
   - Tournament should still be there

