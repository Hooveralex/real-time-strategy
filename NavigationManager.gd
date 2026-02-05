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
	
	# Add each obstacle as a hole (counter-clockwise winding for holes)
	for obstacle in obstacles:
		if obstacle.has_method("get_bounds"):
			var obs_bounds = obstacle.get_bounds()
			# Expand bounds by margin
			var expanded = Rect2(
				obs_bounds.position - Vector2(obstacle_margin, obstacle_margin),
				obs_bounds.size + Vector2(obstacle_margin * 2, obstacle_margin * 2)
			)
			
			# Counter-clockwise winding for holes
			var hole_outline = PackedVector2Array([
				Vector2(expanded.position.x, expanded.position.y),
				Vector2(expanded.position.x, expanded.position.y + expanded.size.y),
				Vector2(expanded.position.x + expanded.size.x, expanded.position.y + expanded.size.y),
				Vector2(expanded.position.x + expanded.size.x, expanded.position.y)
			])
			
			navigation_polygon.add_outline(hole_outline)
	
	# Generate the navigation mesh from outlines
	navigation_polygon.make_polygons_from_outlines()
	
	# Apply to the region
	navigation_region.navigation_polygon = navigation_polygon
	
	print("Navigation mesh created with ", obstacles.size(), " obstacle holes")

func rebake_navigation(bounds: Rect2, obstacles: Array = []):
	# Convenience method to rebake navigation when obstacles change
	bake_navigation_mesh(bounds, obstacles)
