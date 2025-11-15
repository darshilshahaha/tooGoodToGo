# Food Waste Challenge

A small management-style Godot 4 game where you plan meals for a household and try to minimize food waste across a seven-day run. Juggle pantry and fridge items, assign recipes to daily meal slots, and adapt to simple events that add or remove ingredient demands. Build score by cooking ingredients before they spoil.

## What the Game Does

**Food Waste Challenge** simulates household food planning to teach resource management and the impact of waste. You start with a fridge and pantry full of ingredients, each with a countdown timer until it spoils. Every day you:

1. **Check your inventory** – Items decay one day closer to spoiling. Anything that hits zero days is automatically discarded and counts as waste.
2. **Plan meals** – Select recipes for breakfast, lunch, and dinner. Each recipe consumes specific ingredients immediately (like "reserving" them for cooking).
3. **Adapt to events** – Random events (surprise guests, leftovers found, going out to eat) may force extra consumption or refund ingredients back to your inventory.
4. **Review your score** – At day's end, a summary shows what you cooked vs. what spoiled. Your score increases with every ingredient used but drops twice as much for every item wasted.

After 7 in-game days, you see your total waste footprint and receive feedback on your planning skills—perfect for HCI demos on decision-making under time pressure and trade-offs.

## How to Play

### Starting the Game
1. Launch the project in Godot 4 (see **How to Build & Run** below).
2. Click **Start Game** on the main menu.

### Daily Routine
**Day Start:**
- The day counter advances, and the game automatically removes any spoiled items from your pantry/fridge.
- A small warning in the console logs what spoiled (if anything).

**Planning Phase:**
- **Left Panel (Inventory):** View all items grouped into Pantry (grains, non-perishables) and Fridge (dairy, proteins, vegetables). Each row shows:
  - `Category • ItemName x Quantity (N days left)`
- **Right Panel (Recipes):** Scroll through available recipes. Each card displays:
  - Recipe name and description (e.g., "Sunrise Scramble – Eggs with spinach and cheese")
  - Buttons labeled **Breakfast**, **Lunch**, or **Dinner** to assign the recipe to that meal slot.
- **Assign a Recipe:** Click a meal button next to a recipe. The ingredients are consumed immediately, and the recipe name appears in the "Today's Plan" section below.
- **Clear a Meal:** Click the **Clear** button next to a meal type to undo that assignment and refund the ingredients.
- **Recipe Availability:** Buttons gray out when you lack enough ingredients. Hover to see which items are missing (via console warnings).

**Ending the Day:**
- **Show Summary (Preview):** Click this button to see a preview of your score delta without committing. Useful for experimenting with different meal plans.
- **End Day (Commit):** Click to finalize your plan. The game:
  1. Triggers a random event (35% chance: extra dinner guest, skipped meal, restocked pantry, etc.).
  2. Calculates score: `used_items - (2 × wasted_items)`.
  3. Shows a **Day Summary** popup with used/wasted breakdowns and the event result.
- Click **Next Day** in the summary to advance to Day 2 (or **Close** if you opened a preview).

**Repeat** for 7 days total.

### Final Summary
After Day 7:
- A **Final Summary** screen displays:
  - Total ingredients used
  - Total ingredients wasted
  - Final score
  - Qualitative feedback (e.g., "Solid effort" or "Waste was high")
- Click **Back to Main Menu** to restart.

## Strategy Tips
- **Use expiring items first:** Prioritize recipes that consume items with 1–2 days left to avoid spoilage.
- **Balance meal planning:** Don't over-assign recipes early in the week if you might get restock events later.
- **Preview summaries:** Use the "Show Summary" button to experiment without committing your plan.
- **Watch event probabilities:** About 1 in 3 days you'll face an event—keep some buffer ingredients for surprise guests or breakfast cravings.

## Controls Summary
| Action | Control |
|--------|---------|
| **Assign recipe to meal** | Click the meal-type button (Breakfast/Lunch/Dinner) next to a recipe |
| **Clear a meal slot** | Click the **Clear** button in the "Today's Plan" section |
| **Preview results** | Click **Show Summary** (does not advance the day) |
| **End day** | Click **End Day** (commits plan, triggers event, shows summary) |
| **Advance to next day** | Click **Next Day** in the Day Summary popup |
| **Return to main menu** | Click **Back to Main Menu** on the Final Summary screen |

## How to Build & Run
This project targets **Godot 4.x**. No custom build steps are required—open the project in the editor and run the main scene.

1. **Install Godot 4** (if needed)
   - Download from [godotengine.org](https://godotengine.org/download) (macOS `.dmg`) or use Homebrew:
     ```bash
     brew install --cask godot
     ```
2. **Open the project**
   - Launch Godot → `Import/Scan` → select the `FoodWasteChallenge` directory (this folder containing `project.godot`).
3. **Run**
   - Set `MainMenu.tscn` (already the default) as the main scene if prompted.
   - Press the Godot **Run** button (`Cmd + B`) to play.

### Command Line (optional)
Godot 4 can launch projects from the terminal:
```bash
cd /Users/Darshilshah/Desktop/CS/apprenticeship/tooGoodToGo/FoodWasteChallenge
/path/to/Godot.app/Contents/MacOS/Godot .
```
Use `Godot --headless .` to run without a window (useful for CI, though this game requires interaction).

## Customize Data & Assets
- **Inventory, recipes, events**: tweak the arrays near the top of `scripts/GameManager.gd`. Each recipe includes a `description` that shows in the UI, so you can narrate HCI scenarios.
- **Icons**: lightweight SVGs live under `assets/icons/`. Replace them with higher-fidelity art without touching code, or add new icons and wire them into `scenes/Game.tscn`.
- **UI text**: Labels are driven by `scenes/*.tscn`, so you can localize or restyle them directly in Godot’s editor.

## Notes & Future Ideas
- Add ambient audio cues for spoilage warnings and day transitions.
- Animate pantry/recipe cards expanding when selected.
- Persist high scores or allow sandbox/free-play modes for classroom demos.
