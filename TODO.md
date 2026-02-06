# RTS Game Development TODO

## ✅ Completed Features

1. **Unit Selection System**
   - Single unit selection (left-click)
   - Multi-unit selection (box selection)
   - Shift-click to add/remove from selection
   - Visual selection indicators (blue circles)

2. **Unit Movement**
   - Right-click to move units
   - Formation spreading for multiple units
   - Smooth movement with separation forces

3. **Collision Detection & Separation**
   - Units maintain minimum distance from each other
   - Natural clustering behavior
   - Prevents units from stacking

4. **Random Unit Spawning**
   - Units spawn randomly scattered on game start
   - Units stay in place until given commands

5. **Reload Functionality**
   - Press `R` to reload the game scene
   - Units respawn in new random positions

6. **Camera Controls**
   - WASD/Arrow keys for panning
   - Edge scrolling (mouse near screen edges)
   - Mouse wheel zoom (0.5x to 2.0x)
   - Trackpad pinch/expand gesture support
   - Press `F` to focus camera on selected units

7. **Pathfinding & Obstacles**
   - Godot NavigationRegion2D/NavigationAgent2D pathfinding
   - Units navigate around obstacles intelligently
   - Dynamic navigation mesh rebaking when obstacles change
   - Random obstacle generation on startup
   - Manual obstacle add (`O`), remove (`X`), and clear (`Shift+C`)

8. **Combat System**
   - Team-based units (player green, enemy red)
   - Right-click an enemy to issue attack command
   - Units pathfind into attack range, then throw projectiles
   - Auto-attack nearest enemy when idle and in range
   - Projectiles with parabolic arc animation
   - Health system with visual health bars (green/yellow/red)
   - Units die and are removed when health reaches 0
   - Enemy units auto-attack nearby player units

## 🎯 Next Steps (Priority Order)

### 1. Unit Control Groups/Hotkeys ⭐ (Recommended Next)
   - Assign selected units to control groups (1-9 keys)
   - Press number key to select that group
   - Press number key twice to focus camera on group
   - Essential for managing multiple units efficiently

### 2. Unit Types/Variants
   - Create different unit types (soldier, tank, scout, etc.)
   - Different stats (speed, health, damage, range)
   - Visual differentiation (colors, sizes, sprites)
   - Different abilities or behaviors

### 3. Enemy AI
   - Enemies patrol or guard areas
   - Enemies chase and engage player units that get close
   - Different AI behaviors (aggressive, defensive, patrol)
   - Wave-based enemy spawning

### 4. Attack-Move Command
   - `A` + click to issue attack-move
   - Units move to target position but engage enemies along the way
   - Essential RTS micro-management tool

### 5. Building Placement
   - Place structures on the map
   - Buildings can block unit movement
   - Visual feedback for placement
   - Building types with different functions

### 6. Resource Management
   - Collect resources (gold, wood, energy, etc.)
   - Resource display UI
   - Use resources to build units/structures
   - Resource nodes on the map

### 7. Unit Production
   - Select a building to produce units
   - Production queue with progress bar
   - Rally point for newly created units

## 🔮 Future Ideas

- Minimap
- Fog of war
- Tech tree/research system
- Multiplayer support
- Save/load game state
- Sound effects and music
- Unit formations (line, wedge, box)
- Terrain types affecting movement speed

---

*Last Updated: After implementing combat system with projectiles, health, and team-based units*
