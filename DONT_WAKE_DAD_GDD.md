# DON'T WAKE DAD — Full Game Design Document
### Solo Indie Mobile MVP | TikTok Viral Design | Rewarded Ad Monetization

---

## TABLE OF CONTENTS

1. [Game Design Document](#1-game-design-document)
2. [Complete UI Plan](#2-complete-ui-plan)
3. [Development Roadmap](#3-development-roadmap)
4. [Gameplay Systems](#4-gameplay-systems)
5. [Monetization Plan](#5-monetization-plan)
6. [Virality Strategy](#6-virality-strategy)
7. [Retention System](#7-retention-system)
8. [Tech Stack](#8-tech-stack)
9. [Asset Strategy](#9-asset-strategy)
10. [Audio Design](#10-audio-design)

---

## 1. GAME DESIGN DOCUMENT

### Elevator Pitch

> "You're a kid. It's 2am. Dad is asleep. Don't. Make. Noise."

A vertical mobile stealth-panic game where silence is your only weapon and Dad is your nightmare. Every run lasts 30–60 seconds. Every run ends in laughter or terror. Every player immediately hits Retry.

---

### Core Loop

```
START RUN
  → Receive objective (get snacks / charge phone / reach bathroom / etc.)
  → Navigate dark house
  → Avoid / interact with noisy obstacles
  → Sound Meter rises with every noise
  → Random events inject chaos
  → Reach objective = WIN (score + unlock)
  → Sound Meter fills = DAD WAKES UP
      → Music spike + flicker
      → Dad sprints at you
      → Dodge / hide to survive
      → Caught = LOSE SCREEN
          → Rewarded Ad = Second Chance
          → Retry
```

**Session Target:** 30–60 seconds per run. Under 5 seconds to retry. The loop must be frictionless.

---

### Controls

| Input | Action |
|-------|--------|
| Tap | Move forward one tile / interact |
| Hold | Creep slowly (reduced noise) |
| Swipe Left/Right | Step sideways / dodge |
| Tap safe zone | Hide (under bed, behind couch) |
| Double-tap | Sprint (high noise — emergency only) |

**Design rule:** One thumb. Never require two fingers. Works portrait on any phone.

---

### Objective System

Each run assigns a random objective from a pool. This is shown on the main menu and for 2 seconds at run start.

**Objective Pool (MVP):**
- Get a snack from the kitchen
- Charge your phone in the living room
- Use the bathroom
- Steal the TV remote
- Rescue your Nintendo Switch from the couch
- Get a glass of water
- Retrieve your shoes before school

**Why randomize:** Players share clips saying "bro I just needed to charge my phone." The mundane framing makes it funnier.

---

### Mechanics

#### Noise System
Every player action generates a noise value (0–100 scale):
| Action | Noise |
|--------|-------|
| Walking on carpet | 5 |
| Walking on hardwood | 20 |
| Running | 50 |
| Stepping on Lego | 75 (instant spike) |
| Opening fridge | 30 |
| Bumping furniture | 40 |
| Dog barks | 60 (not player fault — adds tension) |

Noise decays at 10/sec when player is still. Max meter = 100. Above 80 = Dad stirs. At 100 = Dad wakes.

#### Sound Meter
- Displayed as a horizontal bar at top of screen
- Color: green → yellow → orange → red
- At 80%: meter pulses and vibrates phone
- At 95%: camera shakes slightly + Dad mutters from bedroom
- At 100%: CHAOS

#### Dad AI — Three States

**SLEEPING**
- Dad is in bedroom. Meter filling from 0–79.
- Soft snore audio plays. False security.

**STIRRING**
- Meter at 80–99.
- Dad rolls over, mutters, shadow visible under door.
- Player gets 3-second warning to reduce noise.
- If noise drops below 60 in 3 seconds → Dad goes back to sleep.

**AWAKE / CHASE**
- Meter hits 100.
- Door slams open. Lights flicker.
- Dad enters level at 1.5x player walk speed.
- Speed escalates every 5 seconds he doesn't catch player (+10% each interval).
- Player must reach a hide spot within 8–12 seconds or is caught.

#### Hide System
Designated hide spots in each level:
- Under bed
- Behind couch
- In closet
- Under kitchen table

If player enters hide spot → Dad searches for 4 seconds → gives up (if player doesn't move/make noise while hiding).
If player makes noise while hiding → Dad finds them instantly.

**Post-hide:** Dad returns to bed. Meter resets to 40. Game continues. This creates INCREDIBLE tension moments.

---

### Levels (MVP — 5 Levels)

| Level | Location | Special Hazard |
|-------|----------|----------------|
| 1 | Hallway to Kitchen | Creaky floorboard, dog bowl |
| 2 | Living Room | Dog sleeping on couch, LEGO minefield |
| 3 | Kitchen | Loud fridge, microwave with leftovers |
| 4 | Living Room (Night 2) | Sibling also awake, TV remote hidden |
| 5 | Dad's Domain | Dad's room adjacent, maximum tension |

---

### Difficulty Scaling (Per Run)

| Factor | Run 1 | Run 5 | Run 10+ |
|--------|-------|-------|---------|
| Dad wake speed | Slow | Medium | Instant |
| Random events | 1/run | 2/run | 3–4/run |
| Lego fields | 1 | 2 | 3 |
| Noise decay rate | Fast | Normal | Slow |
| Dog reactivity | Low | Medium | High |
| Dad chase speed | 1.5x | 1.8x | 2.2x |

---

### Dopamine Trigger Map

| Moment | Trigger |
|--------|---------|
| Almost full meter, player holds still | Relief / tension spike |
| Dog stirs but doesn't bark | Near miss dopamine hit |
| Lego missed by one tile | "OHHHH" reaction |
| Objective reached with meter at 95% | Incredible satisfaction |
| Dad wakes, player hides successfully | Biggest dopamine hit in game |
| Dad gives up and goes back to bed | Euphoria |
| Random fart sound from sibling | Unexpected laugh → share |
| Dad pretends to sleep then lunges | Jump scare → scream → share |

**The goal:** Every 8–10 seconds, one of these fires.

---

### Progression

**Stars Per Level:**
- 1 Star: Complete objective (any state)
- 2 Stars: Complete with meter under 50%
- 3 Stars: Complete silently (meter never above 30%)

**Stars unlock:**
- New Dad skins (Tired Dad, Angry Dad, Zombie Dad)
- New kid skins
- New objectives
- New random events

---

## 2. COMPLETE UI PLAN

### Main Menu

```
┌─────────────────────────────┐
│  [Dark house silhouette bg] │
│                             │
│   👁  DON'T WAKE DAD  👁    │
│   [flickering text effect]  │
│                             │
│   Tonight's Mission:        │
│   "Get the TV Remote"       │
│   [glowing objective card]  │
│                             │
│   ┌─────────────────────┐   │
│   │    SNEAK IN  🤫     │   │
│   └─────────────────────┘   │
│                             │
│   [Best: 3 Stars] [Shop]    │
│   [Settings]  [Daily Run]   │
└─────────────────────────────┘
```

**Design notes:**
- Background: dark house, single window with moon glow
- Dad silhouette visible through bedroom door crack — light off = safe, on = ominous
- Tap anywhere except buttons = "shh" animation from kid character
- Soft ambient house sounds + distant snoring

---

### HUD (In-Game)

```
┌─────────────────────────────┐
│ [NOISE METER ============--]│  ← top center, always visible
│ DAD: 😴 SLEEPING            │  ← Dad status, top left
│                       [🏠?] │  ← objective reminder, top right
│                             │
│                             │
│    [GAME WORLD VIEWPORT]    │
│                             │
│                             │
│      [HIDE SPOTS glow       │
│       when Dad is awake]    │
│                             │
│ [TAP TO MOVE] ←hint fades  │
└─────────────────────────────┘
```

**HUD rules:**
- Meter is the most important element — largest, always visible
- Dad status icon is emoji-style (😴 / 😤 / 😡)
- No score during play — pure tension
- Hide spots get golden outline when Dad is awake

---

### Lose Screen

```
┌─────────────────────────────┐
│                             │
│   [DAD FACE CLOSE-UP]       │
│   [animated: eyes open]     │
│                             │
│   ⚠️  DAD WOKE UP ⚠️        │
│                             │
│   You made it:  87%         │
│   [progress bar]            │
│   Personal Best: 92%        │
│                             │
│ ┌───────────────────────┐   │
│ │  📺 WATCH AD = ESCAPE  │   │  ← rewarded ad
│ └───────────────────────┘   │
│                             │
│ [TRY AGAIN]   [MAIN MENU]   │
│                             │
│ [Share Clip 🎵 TikTok]      │  ← share button always visible
└─────────────────────────────┘
```

**Lose screen psychology:**
- Show progress as a percentage (not "you failed") — reduces negative emotion
- "87%" completion feels close — triggers "one more try"
- Rewarded ad framed as ESCAPE, not "continue" — more thematic
- Share button prominently placed when emotion is highest

---

### Win Screen

```
┌─────────────────────────────┐
│                             │
│   [Kid pumping fist]        │
│   [silent celebration]      │
│                             │
│   🤫 MISSION COMPLETE 🤫    │
│                             │
│   ★ ★ ★  (1-3 stars)       │
│                             │
│   NOISE SCORE: 23%          │
│   CLOSE CALLS: 3            │
│   TIME: 0:47                │
│                             │
│ [NEXT MISSION]  [RETRY]     │
│                             │
│ [Share 🎵]  [Daily Run 🔥]  │
└─────────────────────────────┘
```

---

### Revive / Second Chance System

Triggered immediately when Dad catches player (before Lose Screen):

```
┌─────────────────────────────┐
│                             │
│  [Dad reaches for player]   │
│  [SLOW MOTION]              │
│                             │
│  ⏱  HIDE! WATCH AD (3s)    │
│     [countdown bar]         │
│                             │
│  ┌─────────────────────┐    │
│  │  HIDE UNDER BED 📺  │    │
│  └─────────────────────┘    │
│                             │
│  [No thanks — I give up]    │
│                             │
└─────────────────────────────┘
```

**Design:** Slow-motion moment gives player 3 seconds to decide. Creates "WAIT WAIT WAIT" panic. Perfect TikTok moment. Ad plays, player spawns in nearest hide spot with meter at 70%.

---

### Shop / Cosmetics Screen

Simple grid layout:
- Character skins (top row)
- Dad skins (middle row)
- House themes (bottom row)
- Meme Bundle featured item

Unlock via stars OR watch ad for temporary unlock preview.

---

## 3. DEVELOPMENT ROADMAP

**Total Target: 8 Hours to Playable MVP**
**Engine: Godot 4 (free, fast, mobile-ready)**

---

### HOUR 1 — Project Setup + Core Movement

**Goals:**
- Godot project created, Android export configured
- Tilemap for Level 1 (hallway + kitchen)
- Player character with tap-to-move
- Basic camera follow

**Tasks:**
- [ ] New Godot 4 project, set portrait resolution (390x844)
- [ ] Import 2D tileset (free asset pack — see Asset Strategy)
- [ ] Build Level 1 tilemap (simple L-shape: bedroom → hallway → kitchen)
- [ ] Player scene: sprite + CharacterBody2D
- [ ] Tap input → move toward tap position
- [ ] Hold to move slowly (speed multiplier 0.4x)
- [ ] Camera follow player with slight lag

**Checkpoint:** Kid walks through dark house with tap controls.

---

### HOUR 2 — Noise System + Sound Meter

**Goals:**
- Full noise detection system working
- Sound meter UI visible and functional
- Noise zones on tiles

**Tasks:**
- [ ] NoiseTile resource: each tile has noise_value property
- [ ] Player emits noise_signal(value) on each step
- [ ] NoiseMeter singleton: tracks current noise (0–100), decays 10/sec
- [ ] HUD: ProgressBar node styled as noise meter, color-coded
- [ ] Haptic feedback at 80% (Input.vibrate_handheld())
- [ ] Noise events: Lego (+75), dog bowl (+40), creaky floor (+25)
- [ ] Place 3 noisy obstacle objects in Level 1

**Checkpoint:** Walk on Lego → meter spikes → phone vibrates → terror.

---

### HOUR 3 — Dad AI (All Three States)

**Goals:**
- Dad sleeping, stirring, and chasing fully functional
- Chase is genuinely scary and funny

**Tasks:**
- [ ] Dad scene: sprite + NavigationAgent2D
- [ ] State machine: SLEEPING / STIRRING / CHASING / SEARCHING / RETURNING
- [ ] SLEEPING: Dad in bedroom, plays snore animation loop
- [ ] STIRRING: triggered at meter 80, Dad rolls over sprite, 3s timer
- [ ] CHASING: NavigationAgent pathfinds to player, speed 1.5x player
- [ ] Chase music trigger (AudioStreamPlayer, ducking ambient)
- [ ] Light flicker effect (CanvasModulate tween on wake)
- [ ] SEARCHING: Dad reaches hide spot, waits 4 seconds, returns
- [ ] RETURNING: Dad walks back to bed, meter resets to 40

**Checkpoint:** Dad wakes up and chases you. First time is terrifying.

---

### HOUR 4 — Objectives + Win/Lose States

**Goals:**
- Complete objective system
- Lose screen with ad button
- Win screen with stars

**Tasks:**
- [ ] Objective objects: InteractArea2D nodes (fridge, couch, phone charger)
- [ ] On player overlap + tap → objective_complete signal
- [ ] Noise cost for interaction (fridge = +30 noise)
- [ ] Win screen scene: star calculation, stats display
- [ ] Lose screen scene: percentage display, share button placeholder
- [ ] Revive popup: slow-motion (Engine.time_scale = 0.2), 3s countdown
- [ ] Retry button → reload current level
- [ ] 5 objectives randomized at run start

**Checkpoint:** Full run possible. Win and lose both working.

---

### HOUR 5 — Random Events System

**Goals:**
- 6 random events implemented
- Events fire unpredictably every 10–20 seconds

**Tasks:**
- [ ] EventManager singleton with weighted event table
- [ ] Timer: fires random event every 10–20 seconds (rand range)
- [ ] Event: DOG BARKS → noise +60, dog animation, audio
- [ ] Event: SIBLING DOOR → door crack opens, noise +20, light floods in
- [ ] Event: MICROWAVE BEEP → +45 noise, beep SFX
- [ ] Event: LEGO FIELD → 3 new Lego tiles spawn in path
- [ ] Event: FART (sibling) → +15 noise, laugh audio, meme text popup
- [ ] Event: DAD FAKE SLEEP → Dad appears to stir and stop (false alarm)
- [ ] Event: PHONE BUZZ → player's phone lights up, +30 noise
- [ ] Brief screen-edge indicator shows event direction

**Checkpoint:** Every run feels different. Random chaos.

---

### HOUR 6 — Audio + Juice

**Goals:**
- Full audio design implemented
- Game feels alive and reactive

**Tasks:**
- [ ] Ambient: house at night loop (HVAC hum, distant street)
- [ ] Dad snoring: looping audio on Dad node
- [ ] Footstep audio: different SFX per floor type (carpet, wood, tile)
- [ ] Noise impact sounds: Lego crunch, dog bark, microwave beep
- [ ] Chase music: tense stinger that loops during chase
- [ ] Caught SFX: dramatic sting + Dad yell (muffled/funny)
- [ ] Success SFX: quiet fist-pump sound
- [ ] Meter warning: heartbeat loop starts at 80%
- [ ] All audio normalized, tested on phone speaker

**Checkpoint:** Audio makes the game 3x more stressful and funny.

---

### HOUR 7 — Polish + Second Level + Difficulty

**Goals:**
- Level 2 built
- Difficulty scaling working
- Visual polish pass

**Tasks:**
- [ ] Level 2 tilemap (living room + couch, dog, LEGO minefield)
- [ ] Difficulty config resource: speed, event frequency, decay rate by level
- [ ] Dark vignette overlay (CanvasLayer with darkened edges)
- [ ] Flashlight effect on player (Light2D cone forward)
- [ ] Dad's eyes glow red in dark when chasing
- [ ] Screen shake on Lego step (camera.offset tween)
- [ ] Particle effect: dust puff on each step
- [ ] Dad face close-up on wake (quick cutscene, 1 second)
- [ ] Main menu scene complete with background + start button

**Checkpoint:** Game looks and feels like a real game.

---

### HOUR 8 — Ads Integration + Build + Testing

**Goals:**
- Rewarded ads integrated
- Android APK builds and runs
- All systems tested on real device

**Tasks:**
- [ ] AdMob plugin installed (Poing AdMob for Godot 4)
- [ ] Rewarded ad: loads on lose screen, plays on button tap
- [ ] Ad callback: on_reward_earned → respawn at hide spot
- [ ] Test ads enabled during development
- [ ] Android export: sign APK, test on device
- [ ] Fix any portrait-mode layout issues
- [ ] Test complete run 10 times, fix any blocking bugs
- [ ] Share button: native share intent with screenshot

**Checkpoint:** Shippable MVP on Android.**

---

### Post-MVP (Day 2–3 if needed)
- iOS export
- Level 3–5
- Cosmetics shop (stars currency)
- Daily challenge (same seed for everyone)
- Social leaderboard (best time / lowest noise)

---

## 4. GAMEPLAY SYSTEMS

### Sound Detection System

```
Architecture:
  PlayerController
    → on_step(tile_position)
    → get tile noise value from TileMap metadata
    → emit noise(value) to NoiseMeter

  NoiseMeter (Autoload Singleton)
    properties: current_noise (float), max_noise = 100
    
    func add_noise(value):
        current_noise = min(current_noise + value, 100)
        noise_changed.emit(current_noise)
        if current_noise >= 80: dad.set_state(STIRRING)
        if current_noise >= 100: dad.set_state(CHASING)
    
    func _process(delta):
        if player.is_still:
            current_noise = max(current_noise - (10 * delta), 0)
```

**Noise Sources:**

| Source | Value | Trigger |
|--------|-------|---------|
| Step on carpet | 5 | Player step |
| Step on hardwood | 20 | Player step |
| Step on tile | 15 | Player step |
| Step on Lego | 75 | Collision |
| Bump furniture | 40 | Collision |
| Open fridge | 30 | Interact |
| Dog bump | 35 | Collision |
| Random event | 15–75 | Timer |
| Sprint | 50/step | Input hold |

**Noise Decay:**
- Player still: -10/second
- Player crouching (hold): -5/second + only +3/step
- After hide: instant drop to 40

---

### Dad AI System

**State Machine:**

```
States: SLEEPING → STIRRING → CHASING → SEARCHING → RETURNING → SLEEPING

SLEEPING:
  - Position: in bedroom
  - Snore audio plays
  - Transition: NoiseMeter >= 80

STIRRING:
  - Plays roll-over animation
  - Emits warning (door light under crack)
  - 3 second timer
  - If NoiseMeter drops < 60 in 3s → SLEEPING
  - If timer expires → CHASING
  - Transition: meter < 60 OR 3s elapsed

CHASING:
  - NavigationAgent2D pathfinds to player
  - Speed: base_speed * chase_multiplier
  - chase_multiplier starts 1.5, increases 0.1 every 5s
  - Plays angry animation, red eye glow
  - Door slam SFX + light flicker on entry
  - If player enters hide spot → SEARCHING
  - If player caught → CAUGHT (lose state)
  - Transition: player in hide OR player caught

SEARCHING:
  - Dad navigates to last known player position
  - Waits 4 seconds
  - Looks left/right (animation)
  - If no noise during search → RETURNING
  - If noise during search → CHASING
  - Transition: 4s elapsed no noise

RETURNING:
  - Dad walks back to bedroom
  - Mutters ("must have been the cat...")
  - NoiseMeter.current = 40 on arrival
  - Transition: arrived at bedroom
```

---

### Chase System — Feel

The chase must be the funniest/scariest thing in the game. Key feel rules:
- Dad is FAST. Not unfairly fast but uncomfortably fast.
- Dad's footsteps are LOUD (heavy thud SFX, screen shakes slightly on each step)
- Dad's face is visible ahead of the player (camera loosens during chase)
- Chase music is chaotic — drums, bass, feels like a horror movie
- Dad never moves at exactly constant speed — slight acceleration variance
- When Dad gives up, slow comedic walk back + muttering audio

---

### Random Event System

```
EventManager (Autoload):
  event_table = [
    {name: "dog_bark", weight: 30, noise: 60, cooldown: 15},
    {name: "sibling_door", weight: 20, noise: 20, cooldown: 20},
    {name: "microwave_beep", weight: 25, noise: 45, cooldown: 12},
    {name: "lego_field", weight: 15, noise: 0, effect: "spawn_legos"},
    {name: "fart", weight: 40, noise: 15, meme_text: "💨"},
    {name: "phone_buzz", weight: 35, noise: 30, cooldown: 10},
    {name: "dad_fake_sleep", weight: 10, noise: 0, effect: "fake_wake"},
    {name: "flashlight_flicker", weight: 50, noise: 0, effect: "flicker"}
  ]
  
  func _on_event_timer():
    available = filter events not on cooldown
    chosen = weighted_random(available)
    execute_event(chosen)
    next_timer = randf_range(8, 18)
```

**Event feel rules:**
- Events can stack (two events close together = chaos)
- Player can never fully predict what comes next
- Some events are red herrings (flicker but no noise)
- One event per run is "fake Dad wake" — adds paranoia permanently

---

### Difficulty Scaling

Rather than "levels," difficulty scales on **run number** this session + **stars earned**:

```
DifficultyManager:
  run_index: int  (resets each session)
  stars_total: int
  
  func get_config():
    return {
      dad_wake_speed: 1.5 + (run_index * 0.05),
      noise_decay: 10 - (run_index * 0.3),
      event_frequency_min: max(5, 10 - run_index),
      lego_density: 1 + floor(run_index / 3),
      dog_reactivity: min(1.0, 0.3 + (run_index * 0.07))
    }
```

This means run 10 feels meaningfully harder than run 1 without being unfair.

---

## 5. MONETIZATION PLAN

### Philosophy

**Never block the fun. Monetization should feel like a service, not a tax.**

The player should always feel in control. Ads should appear at moments of peak emotion (just failed, want to try again) not as interruptions.

---

### Rewarded Ads — Core Mechanic

**Placement 1: The Escape**
- Trigger: Dad catches player (slow-motion moment)
- Framing: "WATCH AD = HIDE UNDER BED"
- Reward: Respawn at nearest hide spot, meter at 70%
- Frequency: Max 2 per run (no infinite grinding)
- Psychology: Players feel saved, not sold to

**Placement 2: Second Chance After Lose Screen**
- Trigger: Lose screen, button "Watch Ad → Try Again with head start"
- Reward: Run starts with meter at 0, noise decay doubled for 10 seconds
- Psychology: Lower frustration, higher completion rate

**Placement 3: Star Multiplier**
- Trigger: Win screen
- Framing: "Watch Ad → 2x Stars this run"
- Reward: Double star payout
- Psychology: Optional, feels like a bonus, never punishing

**Placement 4: Unlock Preview**
- Trigger: Shop screen, locked item
- Framing: "Watch 3 Ads to unlock for 24hrs"
- Psychology: Lets players sample skins without paying, drives conversion

---

### IAP (In-App Purchases)

| Item | Price | Value |
|------|-------|-------|
| Remove Interstitial Ads | $1.99 | Quality of life |
| Dad Skin Pack | $0.99 | Cosmetic, meme value |
| Nightmare Bundle | $2.99 | Includes 3 skins + nightmare mode |
| All Dads Pack | $4.99 | Every current + future dad skin |
| Star Booster (permanent 1.5x) | $1.99 | Progression speed |

**No pay-to-win. No energy systems. No timers. No premium currency confusion.**

---

### Interstitial Ads

- Fire at most every 3 runs (not every run)
- Fire only on main menu return, never mid-game
- Short (15s max, skippable at 5s preferred)
- Removed with $1.99 "No Ads" purchase

---

### Revenue Projections (Rough)

Assuming 10,000 daily active users (achievable with one viral TikTok):
- 3 rewarded ads/day/user × $0.02 RPM = $600/day
- 2% IAP conversion × $2 avg = $400/day
- **~$1,000/day potential at 10K DAU**

One viral clip = 100K downloads in a week = significant revenue spike.

---

## 6. VIRALITY STRATEGY

### Why People Share This Game

**The Fundamental Virality Mechanic:** Shared stress + immediate recognition.

Everyone has snuck around a house at night. Everyone has a "Dad" fear memory. The game instantly triggers a universal childhood feeling. When the player screams or laughs, they *want* witnesses.

---

### The 5 Shareable Moments (Design These Intentionally)

**1. The Lego Moment**
- Player is at 90% meter, nearly at objective
- Steps on Lego. Meter spikes. Dad wakes.
- Player screams. Clips itself.
- TikTok caption: "I ALMOST MADE IT 💀"

**2. The Fake-Out**
- Dad fake-wakes. Player panics, hides.
- Dad goes back to sleep.
- Player exhales. Chat goes wild.
- TikTok caption: "THE JUMPSCARE GOT ME TWICE"

**3. The Dog**
- Player carefully avoids everything.
- Dog barks randomly. Unprovoked.
- Dad wakes. Player blames dog on camera.
- Shareable rage moment.

**4. The Perfect Run**
- Player completes objective with meter at 2%.
- Nothing goes wrong.
- Feels incredible. People share victories.
- TikTok caption: "I AM A STEALTH GOD"

**5. The Revive Fail**
- Player watches ad to escape.
- Immediately steps on Lego after respawn.
- Caught again. Comedy gold.

---

### TikTok Hooks (For Your Own Marketing)

Post these video types:

| Video Type | Hook | Expected Performance |
|-----------|------|---------------------|
| "Nobody will survive Level 3" | Challenge energy | High CTR |
| "This game RUINED my night" | Emotion hook | Share trigger |
| Facecam + gameplay | Reactions are content | Viral potential |
| "This dog is the real villain" | Character comedy | Comment bait |
| Speedrun attempts | Skill display | Aspiration hook |
| Impossible level fails | Schadenfreude | Rewatch value |

**Post 3x/day for first 2 weeks. Reply to every comment. Use trending audio.**

---

### Streamer Bait Design

Streamers love this game because:
- Audience backseat drives ("DON'T STEP ON THE LEGO")
- Chat predicts when Dad wakes
- Jump scares = natural clip moments
- Short sessions = easy to cut into YouTube Shorts
- "One more try" keeps stream going

**Add:** A streamer mode toggle that:
- Adds 10% extra random chaos
- Chat-vote event (if connected) — audience triggers events
- "Dad Sense" indicator streamers can toggle for audience

---

### Psychological Hooks

| Hook | Mechanism |
|------|-----------|
| Near-miss bias | Always show "87%" on lose, never "failed" |
| Sunk cost | Stars system makes players want to finish collections |
| Social proof | "1,247 kids got caught today" counter on menu |
| Variable reward | Random events = unpredictable fun = slot machine psychology |
| Identity | "I'm a stealth god" vs "I always get caught" — people play into personas |

---

## 7. RETENTION SYSTEM

### Session Retention (Keep Playing Now)

- Run under 60 seconds → friction to stop is low
- Retry button 1 tap away → no exit friction
- Every run slightly harder → always something new to adapt to
- Daily challenge: same level for everyone → social competition

---

### Daily Retention (Come Back Tomorrow)

**Daily Challenge:**
- New objective + event seed every 24 hours
- Leaderboard for best noise score
- Share result card: "I got 3 stars on today's challenge. Can you beat 14% noise?"
- Reward: exclusive daily skin shard (7 days = 1 full skin)

**Streak System:**
- Day 1: +50 bonus stars
- Day 3: unlock "Tired Dad" skin
- Day 7: unlock "Dad in Bathrobe" — community favorite skin
- Day 30: "GOAT" badge — golden kid skin

**Push Notifications (Opt-in):**
- "Dad went back to sleep... for now. 😴"
- "New mission unlocked: Steal Dad's phone charger 📱"
- "Your best score was beaten by 10 players. Show them. 😤"

---

### Long-Term Retention (Week 2+)

#### Unlockable Lore
Hidden notes collectible during runs:
- Note 1: Kid's diary entry ("Day 3 of the mission...")
- Note 3: Dad's grocery list with suspicious items
- Note 5: Mom's text to Dad ("he's been getting up every night...")
- Note 7: Dad's journal entry (from Dad's perspective)
- Note 10: Secret page reveals Dad KNOWS and is letting it happen

This lore creates investment, YouTube video essays, fan theories.

#### Escalating Weirdness (Week 2 Update)
- Night 5: Dad's eyes glow in the dark (no explanation)
- Night 7: Extra door in hallway (doesn't exist in real level)
- Night 10: Dad is already awake when run starts
- Night 15: Dad is in two places at once
- Night 20: Screen static, "WHO IS CONTROLLING THE KID?"

This escalation creates ARG energy and community speculation.

#### Harder Modes (Stars Unlock)
| Mode | Unlock | Rule |
|------|--------|------|
| Whisper Mode | 15 stars | Noise meter 2x faster |
| Blind Run | 30 stars | Flashlight turns off for 5s randomly |
| Nightmare | 50 stars | Dad never fully sleeps |
| Dad's Perspective | 100 stars | Play AS DAD trying to catch the kid |

**"Dad's Perspective" is the most viral feature in the game.**

---

### Content Update Cadence

| Week | Update |
|------|--------|
| Launch | 2 levels, core game |
| Week 2 | Level 3, dog events expanded |
| Week 3 | Grandma Mode (harder, funnier) |
| Month 1 | Online leaderboard, daily challenge |
| Month 2 | School Mode (teacher = Dad equivalent) |
| Month 3 | Nightmare Mode, lore expansion |

---

## 8. TECH STACK

### Engine: Godot 4.x

**Why Godot:**
- Free, open source (no royalties)
- Excellent 2D performance
- Android + iOS export built-in
- GDScript is fast to write (Python-like)
- Large free asset store
- Active community
- Smaller APK than Unity

**Why not Unity:** Royalty controversy, heavier SDK, longer setup.
**Why not Unreal:** Overkill for 2D mobile.
**Why not GameMaker:** Less versatile, fewer free resources.

---

### Godot Plugins (All Free)

| Plugin | Purpose | Source |
|--------|---------|--------|
| Poing AdMob | AdMob rewarded ads | GitHub: Poing/Poing-Godot-AdMob |
| Phantom Camera | Smooth camera follow + shake | Godot Asset Library |
| GodotTouchInputManager | Better mobile touch | Godot Asset Library |
| LimboAI | State machine for Dad AI | Godot Asset Library |
| Godot Juice | Screen shake, flash, tween helpers | GitHub |

---

### Ad SDK

**AdMob (Google)** — Industry standard for mobile.
- Rewarded ads: eCPM $5–$25
- Interstitial: eCPM $1–$5
- Setup time with Poing plugin: ~1 hour
- Test ads available immediately

**Alternative:** Unity Ads (ironic) or IronSource (higher eCPM, more complex).

**Start with AdMob.** Add mediation later if revenue grows.

---

### Analytics

**GameAnalytics (free tier):**
- Track: run length, where players die, which events cause quits
- Tells you which level is too hard or too boring
- Integrate in 30 minutes
- Free up to 5 million events/month

---

### Share System

Godot 4 native: use `OS.shell_open()` for Android share intent.
Screenshot: `get_viewport().get_texture().get_image().save_png()`
Share the screenshot + deep link to app store.

---

### Backend (Optional, Week 2)

For leaderboard + daily challenge:
- **Nakama (self-hosted)** OR **GameSparks** OR simply **Firebase Realtime DB**
- Firebase easiest: free tier, Godot Firebase plugin exists
- Daily challenge seed: store in Firebase, update at midnight UTC

---

## 9. ASSET STRATEGY

### Free Assets (Use These First)

| Asset Type | Source | Search Term |
|-----------|--------|-------------|
| Tileset (top-down house) | itch.io | "top down house tileset free" |
| Character sprites | itch.io | "2d character sprite sheet free" |
| Furniture sprites | OpenGameArt.org | "furniture top down" |
| Sound effects | freesound.org | "footstep", "dog bark", "creaking" |
| Music | opengameart.org | "ambient horror loop" |
| UI elements | kenney.nl | "UI Pack" (legendary free resource) |

**Best free tileset for this game:**
- "Cozy Interior" by LimeZu on itch.io (free, top-down, perfect)
- "Top-Down Dungeon" adjusted with dark color palette

---

### Paid Assets (If Budget Allows — Under $50 Total)

| Asset | Price | Where |
|-------|-------|-------|
| Animated Dad character | $5–15 | itch.io |
| Premium house tileset | $5–10 | itch.io |
| Cartoon horror SFX pack | $10–15 | itch.io |
| Music pack (ambient horror) | $5–10 | itch.io |

**Total budget: $30–50 gets a great-looking game.**

---

### AI-Generated Assets (Speed Option)

Use these tools to fill gaps in 30 minutes:
- **Midjourney / DALL-E 3:** Dad face close-up, UI backgrounds, menu art
- **ElevenLabs:** Dad voice lines (muttering, snoring, yelling)
- **Suno.ai:** Generate custom chase music and ambient tracks
- **Stable Diffusion:** Custom character skins, meme textures

AI assets are free or cheap and uniquely yours — no copyright issues.

---

### How to Make It Look Good Fast

**The Dark House cheat:** Dark ambient lighting hides low-quality assets.
- Set ambient light to 15% (almost black)
- Player has a small flashlight (Light2D, soft cone)
- Objects only visible near flashlight = less pixel-art detail visible
- This technique makes any tileset look atmospheric and intentional

**Color palette:** Stick to 5 colors max:
- Near-black background (#0d0d1a)
- Deep blue walls (#1a1a3e)
- Warm orange lamp glow (#ff9933)
- Danger red for meter (#ff2222)
- Safe green (#22ff44)

This limited palette makes the game look designed even with simple assets.

---

### Asset Pipeline (Day 1 Speed Run)

1. Download Kenney.nl "1-Bit Pack" (free, 1000+ sprites, instant install)
2. Download "Cozy Interior" tileset from itch.io
3. Download freesound.org pack for footsteps + dog + creaking
4. Generate Dad yell + mutter with ElevenLabs (5 minutes)
5. Generate chase music with Suno.ai (5 minutes)
6. **Total asset time: 45 minutes**

---

## 10. AUDIO DESIGN

### Audio Is 70% of the Fear

The game is mostly dark with limited visuals. Sound does the heavy lifting. Every audio decision must reinforce tension, comedy, or both.

---

### Ambient Soundscape (Always Playing)

**Base layer (always on):**
- House at night: HVAC hum, refrigerator buzz, distant street
- Level: -20dB (barely audible, subliminal tension)
- This creates silence. Silence is scary.

**Dynamic layers (fade in/out based on meter):**
| Meter % | Added Layer |
|---------|-------------|
| 0–40% | Just base layer |
| 40–60% | Soft heartbeat (60 BPM, barely audible) |
| 60–80% | Heartbeat louder, slight bass hum |
| 80–95% | Heartbeat fast (120 BPM), breathing SFX |
| 95–99% | High-pitched tone, camera micro-shakes |
| CHASE | All ambient cuts. Chase music slams in. |

This dynamic audio system does most of the tension work automatically.

---

### Dad Footsteps (Chase)

- Heavy thud SFX — slightly muffled but LOUD
- Each step: phone vibrates 30ms
- Footstep volume increases as Dad gets closer (3D audio simulation via volume)
- Slight echo to suggest big body, heavy man
- Randomize pitch slightly (-5% to +5%) — no two steps sound identical

**Source:** Record own heavy footsteps OR freesound.org "heavy footstep hardwood"

---

### Jump Scare Timing

The primary jump scare is **Dad's door opening.**

**Timing sequence:**
1. Meter hits 100%
2. 0.3s silence (most important)
3. DOOR SLAM SFX (loud, low-frequency bang)
4. Light flicker (3 rapid flashes)
5. Dad's face close-up (0.8 second cutscene)
6. Chase music starts (hard cut, no fade)

**The 0.3s silence is critical.** The brain interprets silence after high tension as "it's okay" — then the slam hits harder.

---

### Random Event Audio

| Event | Sound | Feel |
|-------|-------|------|
| Dog bark | Loud sudden woof | Jump |
| Sibling door | Hinge creak + light | Dread |
| Microwave beep | Sharp electronic beep | Comic panic |
| Lego step | Crunch + player gasp | Pain/laugh |
| Fart | Classic fart SFX | Instant laugh |
| Phone buzz | Vibration SFX | Panic |
| Flashlight flicker | Electrical crackle | Atmosphere |
| Dad fake wake | Bed creak → silence | Pure dread |

---

### Dad Voice Lines (ElevenLabs — 10 minutes to generate)

**Snoring:** 3 variations of snore loop (so it doesn't repeat annoyingly)

**Stirring:**
- "Mmph..."
- "...huh?"
- "What the..."
- "*loud groan*"

**Searching:**
- "I know you're there..."
- "Go back to bed."
- "Must've been the cat."
- "*yawn* ...just a dream."

**Catching:**
- "GOT YA!"
- "IT'S 2 IN THE MORNING!"
- "I TOLD YOU ABOUT THIS."
- "*unintelligible angry dad sounds*"

Voice: Middle-aged, gruff, tired but instantly awake when angry. Muffled slightly (processing filter) for that "heard through a wall" quality until chase.

---

### Fail Sound Design

When caught, the audio tells a complete story:
1. Chase music stops (hard cut)
2. 0.2s silence
3. Dad yell SFX (short, sharp, funny)
4. Sad trombone (optional, 50% chance — adds humor)
5. Lose screen music: deflated, comic, short loop

The sad trombone option is KEY. It reframes failure as comedy rather than frustration. Players laugh instead of rage-quit.

---

### Success Sound Design

When objective reached:
1. All ambient audio ducks to 20%
2. Small "success chime" (quiet, so as not to wake Dad — thematic!)
3. If Dad is still asleep: relieved exhale SFX from player
4. If Dad is in chase: objective ping → immediately into hide sequence

The quiet success chime reinforces the stealth theme. Even winning feels tense.

---

## QUICK REFERENCE — SOLO DEV CHECKLIST

### Day 1 Must-Haves
- [ ] Player movement (tap to move, hold to creep)
- [ ] Noise meter (fills and decays)
- [ ] Noise tiles (carpet vs hardwood vs Lego)
- [ ] Dad state machine (sleep/stir/chase/search/return)
- [ ] 1 complete level (hallway → kitchen)
- [ ] 1 objective (get snack)
- [ ] Win state + Lose state
- [ ] 3 random events
- [ ] Core audio (footsteps, ambient, chase music, door slam)
- [ ] Rewarded ad button on lose screen
- [ ] Retry button

### That's It. Ship It.

Everything else is iteration. Get the core loop in front of players. Post it on TikTok yourself. See what they react to. Build what they want more of.

---

## FINAL NOTES

### The One Thing That Must Be Perfect

**The moment Dad wakes up.**

Get this moment right and everything else is secondary. The door slam, the flicker, the close-up, the chase music — this moment is why people share the game. This is your viral clip. This is your "one more try" trigger.

Playtest this moment 50 times before you playtest anything else.

---

### The Design Mantra

> Every decision asks: "Would someone screenshot this? Would someone clip this? Would someone say 'bro watch this' and hand someone their phone?"

If yes: keep it.
If no: cut it.

---

*Document version 1.0 — Don't Wake Dad MVP*
*Build target: Godot 4.x | Android first | iOS Week 2*
