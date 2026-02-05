extends Node2D

signal selected
signal deselected

var target_position: Vector2
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
	
	target_position = position
	
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

func _process(delta):
	# Calculate separation force (always active to prevent stacking)
	var separation = calculate_separation()
	
	# Move toward target
	var to_target = target_position - position
	var velocity = Vector2.ZERO
	
	if to_target.length() > 5.0:
		velocity = to_target.normalized() * speed
	
	# Always add separation force
	velocity += separation
	
	# Apply movement if there's any velocity
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
	target_position = pos
