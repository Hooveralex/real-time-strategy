extends Camera2D

# Camera movement settings
var pan_speed = 500.0  # Pixels per second
var edge_scroll_margin = 50.0  # Pixels from edge to trigger scrolling
var edge_scroll_speed = 400.0  # Speed of edge scrolling

# Zoom settings
var min_zoom = 0.5
var max_zoom = 2.0
var zoom_speed = 0.1
var current_zoom = 1.0

# Smooth camera movement
var target_position: Vector2
var smooth_speed = 10.0

var _frame_count = 0

func _ready():
	# Set initial zoom
	zoom = Vector2(current_zoom, current_zoom)
	target_position = position
	# Make camera current
	enabled = true
	make_current()
	print("Camera initialized at position: ", position, " enabled: ", enabled, " current: ", is_current())

func _process(delta):
	_frame_count += 1
	if _frame_count == 1:
		print("Camera _process running!")
	
	handle_keyboard_panning(delta)
	handle_edge_scrolling(delta)
	handle_keyboard_zoom()
	
	# Smooth camera movement
	position = position.lerp(target_position, smooth_speed * delta)

func handle_keyboard_panning(delta):
	var movement = Vector2.ZERO
	
	# WASD or Arrow keys
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		movement.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		movement.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		movement.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		movement.x += 1
	
	# Normalize diagonal movement
	if movement.length() > 0:
		movement = movement.normalized()
		target_position += movement * pan_speed * delta

func handle_edge_scrolling(delta):
	var viewport = get_viewport()
	var mouse_pos = viewport.get_mouse_position()
	var viewport_size = viewport.get_visible_rect().size
	
	var movement = Vector2.ZERO
	var scroll_strength = 0.0
	
	# Check if mouse is near screen edges and calculate scroll strength
	if mouse_pos.x < edge_scroll_margin:
		var edge_distance = mouse_pos.x
		scroll_strength = max(scroll_strength, (edge_scroll_margin - edge_distance) / edge_scroll_margin)
		movement.x -= 1
	elif mouse_pos.x > viewport_size.x - edge_scroll_margin:
		var edge_distance = viewport_size.x - mouse_pos.x
		scroll_strength = max(scroll_strength, (edge_scroll_margin - edge_distance) / edge_scroll_margin)
		movement.x += 1
	
	if mouse_pos.y < edge_scroll_margin:
		var edge_distance = mouse_pos.y
		scroll_strength = max(scroll_strength, (edge_scroll_margin - edge_distance) / edge_scroll_margin)
		movement.y -= 1
	elif mouse_pos.y > viewport_size.y - edge_scroll_margin:
		var edge_distance = viewport_size.y - mouse_pos.y
		scroll_strength = max(scroll_strength, (edge_scroll_margin - edge_distance) / edge_scroll_margin)
		movement.y += 1
	
	# Apply edge scrolling
	if movement.length() > 0:
		movement = movement.normalized()
		target_position += movement * edge_scroll_speed * scroll_strength * delta

func handle_keyboard_zoom():
	# Optional: Keyboard zoom with Ctrl+Up/Down (mouse wheel is handled in _input)
	if Input.is_key_pressed(KEY_CTRL):
		if Input.is_action_just_pressed("ui_up"):
			current_zoom = clamp(current_zoom + zoom_speed, min_zoom, max_zoom)
			zoom = Vector2(current_zoom, current_zoom)
		elif Input.is_action_just_pressed("ui_down"):
			current_zoom = clamp(current_zoom - zoom_speed, min_zoom, max_zoom)
			zoom = Vector2(current_zoom, current_zoom)

func _input(event):
	# Handle mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_zoom = clamp(current_zoom + zoom_speed, min_zoom, max_zoom)
			zoom = Vector2(current_zoom, current_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_zoom = clamp(current_zoom - zoom_speed, min_zoom, max_zoom)
			zoom = Vector2(current_zoom, current_zoom)
	
	# Handle trackpad pinch/expand gesture
	elif event is InputEventMagnifyGesture:
		# factor > 1.0 means pinch out (zoom in), factor < 1.0 means pinch in (zoom out)
		# The factor is relative to the previous event, so we multiply the current zoom
		var new_zoom = current_zoom * event.factor
		current_zoom = clamp(new_zoom, min_zoom, max_zoom)
		zoom = Vector2(current_zoom, current_zoom)

func focus_on_position(pos: Vector2):
	# Smoothly move camera to focus on a position
	target_position = pos

func focus_on_selected_units():
	# Focus camera on selected units
	var selected = SelectionManager.get_selected_units()
	if selected.size() > 0:
		var center = Vector2.ZERO
		for unit in selected:
			center += unit.global_position
		center /= selected.size()
		focus_on_position(center)
