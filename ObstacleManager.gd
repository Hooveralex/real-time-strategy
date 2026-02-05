extends Node2D

# Obstacle generation settings
var num_obstacles = 15
var min_size = Vector2(60, 60)
var max_size = Vector2(120, 120)
var placement_margin = 100.0  # Margin from screen edges
var min_distance_between = 150.0  # Minimum distance between obstacles

var obstacles: Array[Node] = []

func _ready():
	# Generate obstacles - they will be added to this node's children
	# NavigationRegion2D will detect them when baking
	generate_obstacles()

func generate_obstacles():
	# Place obstacles around origin (0,0) where the camera starts
	# But keep them away from the center where units spawn
	var placement_area = Rect2(-800, -600, 1600, 1200)
	
	var attempts = 0
	var max_attempts = num_obstacles * 10
	
	for i in range(num_obstacles):
		var obstacle = preload("res://Obstacle.tscn").instantiate()
		var placed = false
		attempts = 0
		
		while not placed and attempts < max_attempts:
			attempts += 1
			
			# Random position
			var pos = Vector2(
				randf_range(placement_area.position.x, placement_area.position.x + placement_area.size.x),
				randf_range(placement_area.position.y, placement_area.position.y + placement_area.size.y)
			)
			
			# Random size
			var size = Vector2(
				randf_range(min_size.x, max_size.x),
				randf_range(min_size.y, max_size.y)
			)
			
			obstacle.position = pos
			obstacle.set_size(size)
			
			# Check if this position overlaps with existing obstacles
			var overlaps = false
			var obstacle_bounds = obstacle.get_bounds()
			
			for existing_obstacle in obstacles:
				var existing_bounds = existing_obstacle.get_bounds()
				var expanded_existing = Rect2(
					existing_bounds.position - Vector2(min_distance_between, min_distance_between),
					existing_bounds.size + Vector2(min_distance_between * 2, min_distance_between * 2)
				)
				
				if obstacle_bounds.intersects(expanded_existing):
					overlaps = true
					break
			
			# Don't place obstacles too close to center (where units spawn)
			if pos.length() < 200:
				overlaps = true
			
			if not overlaps:
				placed = true
				obstacles.append(obstacle)
				add_child(obstacle)
		
		if not placed:
			print("Warning: Could not place obstacle ", i)
	
	print("Generated ", obstacles.size(), " obstacles")

func get_all_obstacles() -> Array[Node]:
	return obstacles.duplicate()
