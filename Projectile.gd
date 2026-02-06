extends Node2D

var damage: float = 20.0
var speed: float = 600.0
var source_team: int = 0
var target: Node2D = null
var target_position: Vector2 = Vector2.ZERO

# Arc effect
var arc_height: float = 40.0
var _progress: float = 0.0
var _start_position: Vector2 = Vector2.ZERO
var _total_distance: float = 0.0

# Visual
var _visual: Node2D

func _ready():
	_start_position = global_position
	
	# Snapshot the target position in case the target dies mid-flight
	if is_instance_valid(target):
		target_position = target.global_position
	
	_total_distance = _start_position.distance_to(target_position)
	if _total_distance < 1.0:
		queue_free()
		return
	
	# Create visual (small circle)
	_visual = Node2D.new()
	add_child(_visual)
	
	var circle = Polygon2D.new()
	var points = PackedVector2Array()
	var radius = 5.0
	for i in range(9):
		var angle = (i * TAU) / 8
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	circle.polygon = points
	
	# Color based on source team
	if source_team == 0:
		circle.color = Color(1.0, 0.9, 0.3)  # Yellow for player
	else:
		circle.color = Color(1.0, 0.4, 0.2)  # Orange-red for enemy
	
	_visual.add_child(circle)

func _process(delta):
	# Update target position if target is still alive (tracking)
	if is_instance_valid(target):
		target_position = target.global_position
		_total_distance = _start_position.distance_to(target_position)
	
	# Move toward target
	var direction = (target_position - global_position)
	var dist_remaining = direction.length()
	
	if dist_remaining < 10.0:
		_on_hit()
		return
	
	# Move in a straight line
	var move_amount = speed * delta
	global_position += direction.normalized() * move_amount
	
	# Calculate arc offset for the visual child
	if _total_distance > 0 and _visual:
		var traveled = _start_position.distance_to(global_position)
		_progress = clampf(traveled / _total_distance, 0.0, 1.0)
		# Parabolic arc: peaks at midpoint
		var arc_offset = -arc_height * 4.0 * _progress * (1.0 - _progress)
		_visual.position.y = arc_offset

func _on_hit():
	# Deal damage to target if still alive
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)
	queue_free()
