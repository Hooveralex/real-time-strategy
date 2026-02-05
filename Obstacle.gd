extends StaticBody2D

# Obstacle properties
var obstacle_size: Vector2 = Vector2(80, 80)
var obstacle_color: Color = Color(0.4, 0.3, 0.2)  # Brown color for obstacles

# Visual components
var visual_node: Node2D

func _ready():
	# Create visual representation
	visual_node = Node2D.new()
	add_child(visual_node)
	
	# Create a rectangle shape for the obstacle
	var rect = Polygon2D.new()
	var points = PackedVector2Array([
		Vector2(-obstacle_size.x / 2, -obstacle_size.y / 2),
		Vector2(obstacle_size.x / 2, -obstacle_size.y / 2),
		Vector2(obstacle_size.x / 2, obstacle_size.y / 2),
		Vector2(-obstacle_size.x / 2, obstacle_size.y / 2)
	])
	rect.polygon = points
	rect.color = obstacle_color
	rect.position = Vector2.ZERO
	
	visual_node.add_child(rect)
	
	# Create collision shape
	var collision_shape = CollisionShape2D.new()
	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.size = obstacle_size
	collision_shape.shape = rectangle_shape
	collision_shape.position = Vector2.ZERO
	add_child(collision_shape)
	
	# Set collision layers - navigation system will detect StaticBody2D automatically
	# We don't want obstacles to physically collide with units, just block navigation
	collision_layer = 0  # Don't collide with units physically
	collision_mask = 0   # Don't detect collisions
	# NavigationRegion2D will automatically detect this StaticBody2D when baking

func set_size(size: Vector2):
	obstacle_size = size
	# Update visual and collision if already created
	if visual_node and visual_node.get_child_count() > 0:
		var rect = visual_node.get_child(0) as Polygon2D
		if rect:
			var points = PackedVector2Array([
				Vector2(-obstacle_size.x / 2, -obstacle_size.y / 2),
				Vector2(obstacle_size.x / 2, -obstacle_size.y / 2),
				Vector2(obstacle_size.x / 2, obstacle_size.y / 2),
				Vector2(-obstacle_size.x / 2, obstacle_size.y / 2)
			])
			rect.polygon = points
	
	if get_child_count() > 1:
		var collision_shape = get_child(1) as CollisionShape2D
		if collision_shape and collision_shape.shape:
			(collision_shape.shape as RectangleShape2D).size = obstacle_size

func set_color(color: Color):
	obstacle_color = color
	if visual_node and visual_node.get_child_count() > 0:
		var rect = visual_node.get_child(0) as Polygon2D
		if rect:
			rect.color = obstacle_color

func get_bounds() -> Rect2:
	# Return bounding box for overlap checking
	return Rect2(global_position - obstacle_size / 2, obstacle_size)
