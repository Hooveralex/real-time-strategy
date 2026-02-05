extends Control

var world_start_pos: Vector2
var world_end_pos: Vector2
var screen_start_pos: Vector2
var screen_end_pos: Vector2
var is_dragging = false

func _ready():
	mouse_filter = MOUSE_FILTER_IGNORE  # Let clicks pass through to units
	z_index = 100  # Draw on top

func _draw():
	if is_dragging:
		# Draw using screen coordinates (Control is in screen space)
		var rect = Rect2(
			min(screen_start_pos.x, screen_end_pos.x),
			min(screen_start_pos.y, screen_end_pos.y),
			abs(screen_end_pos.x - screen_start_pos.x),
			abs(screen_end_pos.y - screen_start_pos.y)
		)
		
		# Draw filled rectangle (semi-transparent)
		draw_rect(rect, Color(0.2, 0.6, 1.0, 0.2))
		
		# Draw border
		draw_rect(rect, Color(0.2, 0.6, 1.0, 0.8), false, 2.0)

func start_selection(world_pos: Vector2):
	world_start_pos = world_pos
	world_end_pos = world_pos
	var viewport = get_viewport()
	screen_start_pos = viewport.get_mouse_position()
	screen_end_pos = screen_start_pos
	is_dragging = true
	queue_redraw()

func update_selection(world_pos: Vector2):
	if is_dragging:
		world_end_pos = world_pos
		var viewport = get_viewport()
		screen_end_pos = viewport.get_mouse_position()
		queue_redraw()

func end_selection() -> Rect2:
	is_dragging = false
	queue_redraw()
	
	# Return world coordinates rect for unit selection
	var rect = Rect2(
		min(world_start_pos.x, world_end_pos.x),
		min(world_start_pos.y, world_end_pos.y),
		abs(world_end_pos.x - world_start_pos.x),
		abs(world_end_pos.y - world_start_pos.y)
	)
	
	return rect
