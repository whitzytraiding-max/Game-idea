# Don't Wake Dad — iOS Setup Guide

Everything you need to go from this repo to a running iPhone app.

---

## WHAT YOU NEED TO BUY / GET FIRST

| Item | Cost | Where |
|------|------|-------|
| Mac (M1/M2/M3 recommended) | You have one or borrow one | Required for iOS build |
| Apple Developer Account | $99/year | developer.apple.com |
| Xcode 15+ | Free | Mac App Store |
| Godot 4.2+ | Free | godotengine.org/download |
| Godot iOS Export Templates | Free | Inside Godot Editor |

---

## STEP 1 — Install Godot 4

1. Go to **godotengine.org/download**
2. Download **Godot Engine 4.x** (standard, not .NET/Mono)
3. Drag to Applications folder
4. Open it once to verify it launches

---

## STEP 2 — Install iOS Export Templates

1. Open Godot
2. Click **Editor → Manage Export Templates**
3. Click **Download and Install** next to the current version
4. Wait for download (about 500MB)
5. Close the dialog when done

---

## STEP 3 — Open the Project

1. In Godot, click **Import**
2. Navigate to this folder (`dont-wake-dad/`)
3. Click `project.godot`
4. Click **Import & Edit**

The game will open. You should see the main menu scene.

---

## STEP 4 — Install Xcode

1. Open the **Mac App Store**
2. Search **Xcode**
3. Install (it's large, ~15GB, takes 20–30 minutes)
4. Open Xcode once → agree to license → let it install components

---

## STEP 5 — Set Up Apple Developer Account

1. Go to **developer.apple.com**
2. Sign in with your Apple ID
3. Enroll in the **Apple Developer Program** ($99/year)
4. Wait for enrollment approval (usually same day)

---

## STEP 6 — Create App ID

1. Go to **developer.apple.com/account**
2. Click **Certificates, IDs & Profiles**
3. Click **Identifiers** → **+**
4. Select **App IDs** → **App**
5. Description: `Don't Wake Dad`
6. Bundle ID (Explicit): `com.yourname.dontwakedad`
   - Replace `yourname` with your actual name/company
7. Click **Continue** → **Register**

---

## STEP 7 — Update export_presets.cfg

Open `dont-wake-dad/export_presets.cfg` in any text editor and replace:

```
application/app_store_team_id="YOUR_TEAM_ID"
application/bundle_identifier="com.yourname.dontwakedad"
```

**Finding your Team ID:**
- Go to developer.apple.com/account
- Click your name top-right → Membership Details
- Copy the **Team ID** (looks like: `A1B2C3D4E5`)

---

## STEP 8 — Add App Icons

You need an icon at these sizes. Use a simple image of a cartoon kid or just the title text:

| File | Size |
|------|------|
| icons/iphone_120x120.png | 120×120 px |
| icons/iphone_180x180.png | 180×180 px |
| icons/ipad_76x76.png | 76×76 px |
| icons/ipad_152x152.png | 152×152 px |
| icons/app_store_1024x1024.png | 1024×1024 px |

Quick option: Use **Canva** (free) to make a simple icon in 5 minutes.
Then update `export_presets.cfg` to point to each file path.

---

## STEP 9 — Export from Godot

1. In Godot, go to **Project → Export**
2. Click **Add...** → select **iOS**
3. Fill in:
   - **App Store Team ID**: your Team ID from Step 7
   - **Bundle Identifier**: `com.yourname.dontwakedad`
4. Check **Architectures**: both `arm64` selected
5. Scroll down → **Texture Format**: check `ETC2/ASTC` only
6. Click **Export Project**
7. Save as `build/DontWakeDad.ipa` (create the `build/` folder)
8. Godot will also create an Xcode project — let it

---

## STEP 10 — Deploy to Your iPhone (Testing)

### Option A: Direct USB (Fastest)
1. Open the Xcode project Godot created (`build/DontWakeDad.xcodeproj`)
2. Connect iPhone via USB
3. Trust the computer on your iPhone
4. In Xcode: select your iPhone as the target device
5. Click **Run** (▶) button
6. First time: go to iPhone **Settings → General → VPN & Device Management** → trust your developer cert

### Option B: TestFlight (For sharing with others)
1. In Xcode: **Product → Archive**
2. Click **Distribute App** → **TestFlight & App Store**
3. Follow prompts to upload to App Store Connect
4. Add testers in App Store Connect → TestFlight tab

---

## STEP 11 — Add Audio Assets (Day 2)

The game is fully playable without audio but needs sounds for full experience.

Download these FREE packs:
- **Footsteps**: freesound.org → search "footstep hardwood"
- **Dog bark**: freesound.org → search "dog bark short"
- **Creaky floor**: freesound.org → search "floor creak"
- **Microwave beep**: freesound.org → search "microwave beep"
- **Dad snore**: freesound.org → search "snoring loop"

Place `.wav` or `.ogg` files in `assets/audio/`.

Then in Godot, assign them to the `AudioStreamPlayer2D` nodes in the entity scenes:
- `entities/dad.tscn` → `SnoreAudio`, `FootstepAudio`, `YellAudio`
- `entities/player.tscn` → `StepAudio`, `CaughtAudio`
- `entities/noise_object.tscn` → `Audio`

---

## STEP 12 — Add AdMob (Rewarded Ads)

### Install Plugin
1. Go to: **github.com/Poing-Studios/godot-admob-ios**
2. Download the latest release
3. Copy the `addons/` folder into `dont-wake-dad/addons/`
4. In Godot: **Project → Project Settings → Plugins** → enable AdMob

### Get AdMob App ID
1. Go to **admob.google.com**
2. Create account (free)
3. Click **Apps → Add App → iOS**
4. Get your **App ID** (format: `ca-app-pub-XXXXXXXX~XXXXXXXXXX`)

### Wire Up Rewarded Ad
In `scripts/lose_screen.gd`, find `_on_ad_revive()` and replace the TODO with:

```gdscript
func _on_ad_revive() -> void:
    var admob = get_node_or_null("/root/AdMob")
    if admob:
        admob.load_rewarded_video("ca-app-pub-YOUR_ID/YOUR_UNIT_ID")
        admob.rewarded_video_ad_rewarded.connect(_on_reward_granted)
        admob.show_rewarded_video()
    else:
        # Fallback: grant without ad (remove in production)
        GameManager.go_to_game()

func _on_reward_granted(_reward) -> void:
    GameManager.go_to_game()
```

---

## WHAT'S ALREADY BUILT (No Setup Needed)

- Full gameplay loop (stealth, noise meter, Dad AI)
- 2 levels with obstacles, hide spots, objectives
- Win / Lose / Main Menu screens
- Revive slow-motion system
- Random event system (6 events)
- Difficulty scaling per run
- Share button (native iOS share sheet)
- Haptic feedback on noise spike
- Dad state machine (sleeping → stirring → chasing → searching → returning)

---

## QUICK BUG FIXES

**"Cannot open scene" error:**
→ Make sure you opened the project from inside the `dont-wake-dad/` folder, not the parent folder.

**Player doesn't move:**
→ Touch input may need enabling. Go to **Project Settings → Input Devices → Pointing** → enable **Emulate Touch From Mouse** (for desktop testing).

**Dad doesn't wake:**
→ NoiseMeter autoload might not be connected. Check **Project Settings → Autoload** — all four autoloads should be listed.

**Walls don't work:**
→ Check collision layers. Walls are layer 2, player is layer 1, player's collision mask should include layer 2.

**Game crashes on launch:**
→ Usually a missing node reference. Check Godot's Output panel for the specific error.

---

## TOTAL TIME ESTIMATE

| Task | Time |
|------|------|
| Install Godot + templates | 20 min |
| Install Xcode | 30 min (download) |
| Apple Developer enrollment | 15 min + approval wait |
| Open project + first test run | 10 min |
| Deploy to iPhone | 15 min |
| **First build on your phone** | **~90 min total** |

---

Good luck. Dad is sleeping. Don't wake him. 🤫
