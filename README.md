# Purrithmetic (Prototype)

**Purrithmetic** is a cozy, mobile-focused **cat-themed arithmetic game prototype** built in **Godot 4.5.1**.  
The core loop is designed around a relaxing “home hub” where you customize your cat, unlock cosmetics through play, and jump into short math rounds for rewards.

## Game Design (Current Prototype Loop)
1. **Home Hub (RoomHub)**
   - A simple room scene with interactive hotspots (TV / Wardrobe / Desk).
2. **Play a timed math round**
   - Choose a mode (Addition / Subtraction / Multiplication / Division) and answer as many questions as possible in **60 seconds**.
3. **Earn coins**
   - Score is based on **total correct + longest streak**, which is converted into **coins**.
4. **Spend coins in the shop**
   - Buy new cosmetics (bodies/outfits/hats) and immediately equip them in customization.

This prototype focuses on building the **game systems and flow** first (UI, shop loop, minigame logic, unlocks). Visual polish and content expansion are planned next.

---

## Features (Implemented)

### Room Hub
- Interactive hotspot navigation (TV / Wardrobe / Desk)
- Hub acts as the “home base” for customization and minigame entry

### Character Customization
- Equip:
  - **Base body**
  - **Outfits**
  - **Hats**
- Customization UI dynamically shows items based on what the player **owns**

### Shop System
- Category tabs: **Body / Outfit / Hat**
- Purchase flow:
  - Confirmation popup (“Buy for X coins?”)
  - Warning popup for insufficient funds (“Meow! You don't have enough funds.”)
- Purchased items immediately unlock and appear in customization

### Math Minigame
- Mode selection: **Addition / Subtraction / Multiplication / Division**
- **60-second timed round**
- Score logic:
  - **Score = total correct + longest streak**
  - Score is converted into **coins** and added to player currency
- Adaptive difficulty:
  - Difficulty increases every **3 correct in a row**
  - Difficulty decreases every **3 wrong in a row**

---

## Tech Notes
- Engine: **Godot 4.5.1**
- UI: Control/Containers, TabContainer-based navigation, dynamic grid generation for shop/customization
- Data: Global state for currency, owned items, and equipped appearance (prototype-level persistence planned)

---

## Demo (Silent Preview)
<img width="800" height="466" alt="image" src="https://github.com/user-attachments/assets/350e989d-7b57-4b19-81a5-bdcc4985a204" />
<img width="800" height="466" alt="image" src="https://github.com/user-attachments/assets/bf657e43-1610-48d6-99f1-1aa2351fef3d" />
<img width="800" height="466" alt="image" src="https://github.com/user-attachments/assets/09520396-a7f1-4893-9d23-59b72b81e552" />

---

## How to Run
1. Install **Godot 4.5.1**
2. Open this folder as a project (it contains `project.godot`)
3. Run the main scene (e.g., `RoomHub.tscn`)

---

## Roadmap (Next)
- Room decoration mode (wall/floor/decor slot placement)
- Save/load persistence (purchases and loadout persist across sessions)
- More item categories + improved UI polish + audio feedback
- Difficulty settings menu + more question types and progression

---

## What This Project Demonstrates
- UI layout in Godot (containers, TabContainer styling, responsive layout)
- Gameplay-state management (owned items, equip flow, currency)
- Shop loop: **currency → purchase → unlock → equip**
- Minigame logic: keypad input, mode selection, difficulty scaling, timed scoring

---

## Art & Assets
All art and visual assets in this repository were created by me.

