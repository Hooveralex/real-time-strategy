extends Node2D

signal selected
signal deselected

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

var speed = 300.0
var is_selected = false

# Collision and separation
var separation_radius = 100.0      # Units within this distance will push apart
var separation_strength = 1500.0   # How strongly units push
var min_separation_dist = 70.0    # Units will maintain at least this much distance

# Visual components
var selection_indicator: Node2D
var unit_visual: Polygon2D

func _ready():
	print("Unit _ready at position: ", position)
	
	# Wait for navigation map to be ready
	await get_tree().physics_frame
	
	# Configure navigation agent
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 20.0
	
	# Connect to velocity_computed for safer movement (optional but recommended)
	# Make sure agent syncs with navigation map
	call_deferred("_setup_navigation_agent")

func _setup_navigation_agent():
	# Wait for NavigationServer to sync
	await get_tree().physics_frame
	navigation_agent.set_navigation_map(get_world_2d().get_navigation_map())
	
	# Create selection indicator (circle)
	selection_indicator = Node2D.new()
	add_child(selection_indicator)
	
	var circle = Polygon2D.new()
	var points = PackedVector2Array()
	var radius = 25.0
	for i in range(33):
		var angle = (i * TAU) / 32
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	circle.polygon = points
	circle.color = Color(0.2, 0.6, 1.0, 0.5)
	selection_indicator.add_child(circle)
	selection_indicator.visible = false
	
	# Create unit visual (green square)
	unit_visual = Polygon2D.new()
	unit_visual.polygon = PackedVector2Array([
		Vector2(-12, -12),
		Vector2(12, -12),
		Vector2(12, 12),
		Vector2(-12, 12)
	])
	unit_visual.color = Color(0.2, 0.8, 0.3)
	add_child(unit_visual)
	
	print("Unit initialized with ", get_child_count(), " children")

func _physics_process(delta):
	# Skip if navigation agent isn't ready or has finished
	if not navigation_agent:
		return
	
	if navigation_agent.is_navigation_finished():
		# Still apply separation when stopped
		var separation = calculate_separation()
		if separation.length() > 0.1:
			position += separation * delta
		return
	
	# Get the next point in the path
	var next_path_position = navigation_agent.get_next_path_position()
	
	# Skip if next position is same as current (agent not synced yet)
	var to_next = next_path_position - global_position
	if to_next.length() < 1.0:
		return
	
	# Calculate direction to next path point
	var direction = to_next.normalized()
	var velocity = direction * speed
	
	# Add separation force for local avoidance
	var separation = calculate_separation()
	velocity += separation
	
	# Apply movement
	if velocity.length() > 0.1:
		position += velocity * delta

func calculate_separation() -> Vector2:
	var separation = Vector2.ZERO
	var all_units = get_tree().get_nodes_in_group("units")
	
	for unit in all_units:
		if unit == self:
			continue
		
		var distance = global_position.distance_to(unit.global_position)
		
		# Push apart when units are closer than min_separation_dist
		if distance < min_separation_dist and distance > 0:
			var direction = (global_position - unit.global_position).normalized()
			# Linear falloff - stronger when closer
			var normalized_dist = (min_separation_dist - distance) / min_separation_dist
			separation += direction * normalized_dist * separation_strength
	
	# Cap separation force to prevent vibration, but high enough to work
	var max_separation = 600.0
	if separation.length() > max_separation:
		separation = separation.normalized() * max_separation
	
	return separation

func is_point_inside(point: Vector2) -> bool:
	return global_position.distance_to(point) < 25.0

func set_selected(value: bool):
	is_selected = value
	selection_indicator.visible = is_selected
	if is_selected:
		selected.emit()
	else:
		deselected.emit()

func get_selection_bounds() -> Rect2:
	return Rect2(global_position - Vector2(25, 25), Vector2(50, 50))

func set_target_position(pos: Vector2):
	if navigation_agent:
		navigation_agent.target_position = pos
