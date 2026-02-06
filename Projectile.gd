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
	
	# Create visual (snowball sprite from sprite sheet)
	_visual = Node2D.new()
	add_child(_visual)
	
	var spritesheet = preload("res://assets/spritesheet.png")
	var snowball_sprite = Sprite2D.new()
	snowball_sprite.texture = spritesheet
	snowball_sprite.region_enabled = true
	# Row 3 (y=417), use column 2 for a medium-sized snowball
	snowball_sprite.region_rect = Rect2(512, 417, 256, 141)
	snowball_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Scale down to projectile size (~14px)
	snowball_sprite.scale = Vector2(0.12, 0.12)
	
	_visual.add_child(snowball_sprite)

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
