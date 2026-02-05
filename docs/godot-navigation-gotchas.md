# Godot 4 Navigation Gotchas

Lessons learned from implementing pathfinding in this RTS project.

## NavigationAgent2D Timing Issue

### Problem

Units wouldn't move even though:
- The navigation mesh was being created correctly (34+ polygons)
- The NavigationRegion2D and NavigationAgent2D had matching map RIDs
- `is_navigation_finished()` returned `false` after setting a target

**Symptom**: `NavigationServer2D.map_get_closest_point()` returned `(0, 0)` instead of the unit's actual position, indicating the agent couldn't find itself on the navigation mesh.

### Root Cause

The NavigationServer processes navigation data **asynchronously**. Even after assigning a NavigationPolygon to a NavigationRegion2D, the server needs time to index and make that data queryable.

Units were trying to pathfind before the NavigationServer had finished processing the mesh data.

### Solution

Explicitly set the navigation map on the agent **after** waiting for the physics frame:

```gdscript
func _ready():
    await get_tree().physics_frame
    # Configure agent...
    call_deferred("_setup_navigation_agent")

func _setup_navigation_agent():
    await get_tree().physics_frame
    navigation_agent.set_navigation_map(get_world_2d().get_navigation_map())
```

Also add a safety check in `_physics_process` to handle cases where the agent returns the current position as the next path position:

```gdscript
var next_path_position = navigation_agent.get_next_path_position()
var to_next = next_path_position - global_position
if to_next.length() < 1.0:
    return  # Agent not synced yet
```

---

## NavigationPolygon Outline Winding Order

### Problem

Error: `NavigationPolygon: Convex partition failed! Failed to convert outlines to a valid NavigationPolygon.`

### Root Cause

In Godot 4, NavigationPolygon outlines must all use the **same winding order**. The error message says: "To add holes inside this outline add the smaller outlines with same winding order."

### Solution

Use consistent clockwise winding for both outer boundary and holes:

```gdscript
# Outer boundary (clockwise)
var outer_outline = PackedVector2Array([
    Vector2(bounds.position.x, bounds.position.y),                              # top-left
    Vector2(bounds.position.x + bounds.size.x, bounds.position.y),              # top-right
    Vector2(bounds.position.x + bounds.size.x, bounds.position.y + bounds.size.y),  # bottom-right
    Vector2(bounds.position.x, bounds.position.y + bounds.size.y)               # bottom-left
])

# Holes (SAME clockwise winding)
var hole_outline = PackedVector2Array([
    Vector2(rect.position.x, rect.position.y),                              # top-left
    Vector2(rect.position.x + rect.size.x, rect.position.y),                # top-right
    Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y),  # bottom-right
    Vector2(rect.position.x, rect.position.y + rect.size.y)                 # bottom-left
])
```

---

## Overlapping Obstacle Outlines

### Problem

Same error as above, but caused by obstacle outlines overlapping each other (especially after adding margins).

### Solution

Merge overlapping obstacle rectangles before adding them as outlines:

1. Expand obstacle bounds by margin
2. Clamp to navigation area bounds
3. Merge any overlapping rectangles into single bounding rectangles
4. Add merged rectangles as hole outlines

This prevents the "outlines can not overlap" error when obstacles are placed close together or when margins cause overlap.

---

## Debugging Tips

When pathfinding isn't working:

1. **Check if mesh exists**: `navigation_polygon.get_polygon_count()` should be > 0
2. **Check map RIDs match**: Compare `navigation_region.get_navigation_map()` with `navigation_agent.get_navigation_map()`
3. **Check if unit is on mesh**: `NavigationServer2D.map_get_closest_point(map_rid, position)` should return a point close to the unit's position, not `(0, 0)`
4. **Enable debug visualization**: Debug > Visible Navigation in the editor while running
