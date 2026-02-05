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

## 🎯 Next Steps (Priority Order)

### 1. Unit Control Groups/Hotkeys ⭐ (Recommended Next)
   - Assign selected units to control groups (1-9 keys)
   - Press number key to select that group
   - Press number key twice to focus camera on group
   - Essential for managing multiple units efficiently

### 2. Pathfinding
   - Implement A* pathfinding or use Godot's Navigation2D
   - Units navigate around obstacles intelligently
   - Smooth path following
   - *Note: Requires obstacles/terrain to be implemented first*

### 3. Obstacles and Terrain
   - Add walls, rocks, or terrain features to the map
   - Units avoid obstacles using pathfinding
   - Visual variety and strategic gameplay
   - *Prerequisite for pathfinding system*

### 4. Unit Types/Variants
   - Create different unit types (soldier, tank, scout, etc.)
   - Different stats (speed, health, damage, range)
   - Visual differentiation (colors, sizes, sprites)
   - Different abilities or behaviors

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

## 🔮 Future Ideas

- Unit health/damage system
- Combat mechanics (attacking, defending)
- AI/command system for units
- Minimap
- Unit production queues
- Tech tree/research system
- Multiplayer support
- Save/load game state

---

*Last Updated: After implementing camera controls with trackpad support*
