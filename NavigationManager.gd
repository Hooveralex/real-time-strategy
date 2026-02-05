extends Node

# Navigation mesh management
var navigation_region: NavigationRegion2D
var navigation_polygon: NavigationPolygon

# Margin around obstacles for navigation (units won't path too close to edges)
var obstacle_margin: float = 15.0

func _ready():
	pass

func setup_navigation(region: NavigationRegion2D):
	navigation_region = region
	navigation_polygon = NavigationPolygon.new()
	navigation_region.navigation_polygon = navigation_polygon

func bake_navigation_mesh(bounds: Rect2, obstacles: Array = []):
	if not navigation_region:
		push_error("NavigationRegion2D not set!")
		return
	
	# Create a new navigation polygon
	navigation_polygon = NavigationPolygon.new()
	
	# Create outer boundary outline (clockwise winding)
	var outer_outline = PackedVector2Array([
		Vector2(bounds.position.x, bounds.position.y),
		Vector2(bounds.position.x + bounds.size.x, bounds.position.y),
		Vector2(bounds.position.x + bounds.size.x, bounds.position.y + bounds.size.y),
		Vector2(bounds.position.x, bounds.position.y + bounds.size.y)
	])
	
	navigation_polygon.add_outline(outer_outline)
	
	# Shrink bounds slightly for obstacle clamping (obstacles must be fully inside)
	var inner_bounds = Rect2(
		bounds.position + Vector2(obstacle_margin + 5, obstacle_margin + 5),
		bounds.size - Vector2((obstacle_margin + 5) * 2, (obstacle_margin + 5) * 2)
	)
	
	# Collect and merge overlapping obstacle bounds
	var obstacle_rects: Array[Rect2] = []
	for obstacle in obstacles:
		if obstacle.has_method("get_bounds"):
			var obs_bounds = obstacle.get_bounds()
			# Expand bounds by margin
			var expanded = Rect2(
				obs_bounds.position - Vector2(obstacle_margin, obstacle_margin),
				obs_bounds.size + Vector2(obstacle_margin * 2, obstacle_margin * 2)
			)
			
			# Clamp to inner bounds - skip if completely outside
			var clamped = expanded.intersection(inner_bounds)
			if clamped.size.x > 1 and clamped.size.y > 1:
				obstacle_rects.append(clamped)
	
	# Merge overlapping rectangles
	var merged_rects = _merge_overlapping_rects(obstacle_rects)
	
	# Add each merged obstacle as a hole (same clockwise winding as outer boundary)
	for rect in merged_rects:
		var hole_outline = PackedVector2Array([
			Vector2(rect.position.x, rect.position.y),                              # top-left
			Vector2(rect.position.x + rect.size.x, rect.position.y),                # top-right
			Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y),  # bottom-right
			Vector2(rect.position.x, rect.position.y + rect.size.y)                 # bottom-left
		])
		navigation_polygon.add_outline(hole_outline)
	
	# Generate the navigation mesh from outlines
	navigation_polygon.make_polygons_from_outlines()
	
	# Apply to the region
	navigation_region.navigation_polygon = navigation_polygon
	
	print("Navigation mesh created with ", merged_rects.size(), " obstacle holes (from ", obstacles.size(), " obstacles)")

func _merge_overlapping_rects(rects: Array[Rect2]) -> Array[Rect2]:
	"""Merge overlapping rectangles into larger bounding rectangles."""
	if rects.is_empty():
		return []
	
	var result: Array[Rect2] = []
	var used: Array[bool] = []
	used.resize(rects.size())
	used.fill(false)
	
	for i in range(rects.size()):
		if used[i]:
			continue
		
		var merged = rects[i]
		used[i] = true
		var changed = true
		
		# Keep merging until no more overlaps found
		while changed:
			changed = false
			for j in range(rects.size()):
				if used[j]:
					continue
				
				# Check if rectangles overlap or touch
				if merged.intersects(rects[j].grow(1)):
					# Merge by creating bounding rectangle
					merged = merged.merge(rects[j])
					used[j] = true
					changed = true
		
		result.append(merged)
	
	return result

func rebake_navigation(bounds: Rect2, obstacles: Array = []):
	# Convenience method to rebake navigation when obstacles change
	bake_navigation_mesh(bounds, obstacles)
