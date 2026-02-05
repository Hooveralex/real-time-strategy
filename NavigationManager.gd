extends Node

# Navigation mesh management
var navigation_region: NavigationRegion2D
var navigation_polygon: NavigationPolygon

func _ready():
	pass

func setup_navigation(region: NavigationRegion2D):
	navigation_region = region
	navigation_polygon = NavigationPolygon.new()
	navigation_region.navigation_polygon = navigation_polygon

func bake_navigation_mesh(bounds: Rect2):
	if not navigation_region:
		push_error("NavigationRegion2D not set!")
		return
	
	# Create navigation polygon that covers the entire playable area
	# In Godot 4, obstacles with StaticBody2D and CollisionShape2D are automatically
	# excluded from the navigation mesh when we bake it
	var outline = PackedVector2Array([
		Vector2(bounds.position.x, bounds.position.y),
		Vector2(bounds.position.x + bounds.size.x, bounds.position.y),
		Vector2(bounds.position.x + bounds.size.x, bounds.position.y + bounds.size.y),
		Vector2(bounds.position.x, bounds.position.y + bounds.size.y)
	])
	
	navigation_polygon.clear_outlines()
	navigation_polygon.add_outline(outline)
	navigation_polygon.make_polygons_from_outlines()
	
	navigation_region.navigation_polygon = navigation_polygon
	
	# In Godot 4, we need to call bake_navigation_polygon() to update the mesh
	# This will automatically exclude obstacles with collision shapes
	call_deferred("_bake_nav_mesh")

func _bake_nav_mesh():
	if navigation_region:
		# Bake the navigation mesh - this will exclude obstacles automatically
		navigation_region.bake_navigation_polygon()
