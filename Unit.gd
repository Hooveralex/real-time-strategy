extends Node2D

signal selected
signal deselected

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

var speed = 300.0
var is_selected = false

# Team: 0 = player, 1 = enemy
var team: int = 0

# Health
var max_health: float = 100.0
var health: float = 100.0

# Combat
var attack_damage: float = 20.0
var attack_range: float = 250.0      # pixels
var attack_cooldown: float = 1.5     # seconds between throws
var attack_timer: float = 0.0
var attack_target: Node2D = null     # manually assigned target

# Collision and separation
var separation_radius = 100.0      # Units within this distance will push apart
var separation_strength = 1500.0   # How strongly units push
var min_separation_dist = 70.0    # Units will maintain at least this much distance

# Visual components
var selection_indicator: Node2D
var unit_visual: Sprite2D
var health_bar: Node2D

# Preloaded scenes/resources
var _projectile_scene = preload("res://Projectile.tscn")
var _health_bar_script = preload("res://HealthBar.gd")
var _spritesheet = preload("res://assets/spritesheet.png")

# Sprite sheet layout (1024x558, 4 columns x 4 rows)
# Row 0: Blue (player), Row 1: Red (enemy), Row 2: Green (unused), Row 3: Snowballs
const SPRITE_FRAME_W = 256
const SPRITE_FRAME_H = 139
const SPRITE_ROWS = { 0: 0, 1: 139 }  # team -> y offset

func _ready():
	# Wait for navigation map to be ready
	await get_tree().physics_frame
	
	# Configure navigation agent
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 20.0
	
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
	
	# Create unit visual (sprite from sprite sheet)
	unit_visual = Sprite2D.new()
	unit_visual.texture = _spritesheet
	unit_visual.region_enabled = true
	var row_y = SPRITE_ROWS.get(team, 0)
	unit_visual.region_rect = Rect2(0, row_y, SPRITE_FRAME_W, SPRITE_FRAME_H)
	unit_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Scale sprite to roughly match the previous unit size (~40px tall)
	var sprite_scale = 0.35
	unit_visual.scale = Vector2(sprite_scale, sprite_scale)
	add_child(unit_visual)
	
	# Create health bar
	health_bar = Node2D.new()
	health_bar.set_script(_health_bar_script)
	add_child(health_bar)

func _physics_process(delta):
	# Skip if navigation agent isn't ready
	if not navigation_agent:
		return
	
	# Update attack cooldown timer
	if attack_timer > 0:
		attack_timer -= delta
	
	# Combat logic
	_process_combat(delta)
	
	# Movement logic
	_process_movement(delta)

func _process_combat(_delta):
	# Clean up invalid attack target
	if attack_target and not is_instance_valid(attack_target):
		attack_target = null
	
	# If we have a manual attack target, try to attack it
	if attack_target:
		var dist = global_position.distance_to(attack_target.global_position)
		if dist <= attack_range:
			# In range -- stop moving and attack
			_try_attack(attack_target)
		else:
			# Move toward attack target
			if navigation_agent:
				navigation_agent.target_position = attack_target.global_position
		return
	
	# Auto-attack: find nearest enemy in range
	var nearest_enemy = _find_nearest_enemy()
	if nearest_enemy:
		_try_attack(nearest_enemy)

func _try_attack(target_unit: Node2D):
	if attack_timer > 0:
		return
	if not is_instance_valid(target_unit):
		return
	
	var dist = global_position.distance_to(target_unit.global_position)
	if dist > attack_range:
		return
	
	throw_projectile(target_unit)
	attack_timer = attack_cooldown

func _find_nearest_enemy() -> Node2D:
	var enemy_group = "enemy_units" if team == 0 else "units"
	var enemies = get_tree().get_nodes_in_group(enemy_group)
	
	var nearest: Node2D = null
	var nearest_dist = attack_range
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy == self:
			continue
		# Make sure it's actually on the other team
		if enemy.has_method("get_team") and enemy.get_team() == team:
			continue
		
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	
	return nearest

func get_team() -> int:
	return team

func throw_projectile(target_unit: Node2D):
	var projectile = _projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.damage = attack_damage
	projectile.source_team = team
	projectile.target = target_unit
	projectile.target_position = target_unit.global_position
	
	# Add to the scene tree (parent's parent = Game node)
	get_tree().current_scene.add_child(projectile)

func take_damage(amount: float):
	health -= amount
	if health <= 0:
		health = 0
		die()
		return
	
	# Update health bar
	if health_bar and health_bar.has_method("update_health"):
		health_bar.update_health(health, max_health)

func die():
	# Remove from all groups
	if is_in_group("units"):
		remove_from_group("units")
	if is_in_group("enemy_units"):
		remove_from_group("enemy_units")
	
	# Deselect if selected
	if is_selected:
		set_selected(false)
	
	queue_free()

func _process_movement(delta):
	if navigation_agent.is_navigation_finished():
		# Still apply separation when stopped
		var separation = calculate_separation()
		if separation.length() > 0.1:
			position += separation * delta
		return
	
	# If we have an attack target in range, stop moving to attack
	if attack_target and is_instance_valid(attack_target):
		var dist = global_position.distance_to(attack_target.global_position)
		if dist <= attack_range:
			# Stop navigation -- we're in range
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
	# Check against all units (both teams)
	var all_units = get_tree().get_nodes_in_group("units") + get_tree().get_nodes_in_group("enemy_units")
	
	for unit in all_units:
		if unit == self:
			continue
		if not is_instance_valid(unit):
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
	if selection_indicator:
		selection_indicator.visible = is_selected
	if is_selected:
		selected.emit()
	else:
		deselected.emit()

func get_selection_bounds() -> Rect2:
	return Rect2(global_position - Vector2(25, 25), Vector2(50, 50))

func set_target_position(pos: Vector2):
	# Moving to a position clears the attack target
	attack_target = null
	if navigation_agent:
		navigation_agent.target_position = pos

func set_attack_target(target_unit: Node2D):
	attack_target = target_unit
	# Start moving toward the target
	if navigation_agent and is_instance_valid(target_unit):
		navigation_agent.target_position = target_unit.global_position
