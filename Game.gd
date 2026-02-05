extends Node2D

@onready var selection_box: Control = $SelectionLayer/SelectionBox
@onready var camera: Camera2D = $Camera2D
@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D
@onready var obstacle_manager: Node2D = $ObstacleManager
@onready var navigation_manager: Node = $NavigationManager

var units: Array[Node] = []

# Navigation bounds - area where units can move
var nav_bounds = Rect2(-1000, -800, 2000, 1600)

func _ready():
	print("Game _ready called")
	
	# Setup navigation system
	setup_navigation()
	
	# Wait a frame for obstacles to be generated, then bake navigation
	await get_tree().process_frame
	bake_navigation()
	
	# Create units after navigation is ready
	create_test_units()
	
	print("Game initialization complete")

func setup_navigation():
	print("Setting up navigation...")
	navigation_manager.setup_navigation(navigation_region)
	
	# Connect to obstacle changes for automatic rebaking
	obstacle_manager.obstacles_changed.connect(_on_obstacles_changed)

func _on_obstacles_changed():
	# Rebake navigation mesh when obstacles are added/removed
	print("Obstacles changed, rebaking navigation...")
	bake_navigation()

func bake_navigation():
	print("Baking navigation mesh...")
	var obstacles = obstacle_manager.get_all_obstacles()
	navigation_manager.bake_navigation_mesh(nav_bounds, obstacles)
	print("Navigation mesh baked with ", obstacles.size(), " obstacles")

func get_world_mouse_position() -> Vector2:
	if camera:
		return camera.get_global_mouse_position()
	return get_global_mouse_position()

func create_test_units():
	print("Creating units...")
	
	for i in range(5):
		var unit = preload("res://Unit.tscn").instantiate()
		
		# Scatter units around origin (where camera is)
		var angle = randf() * TAU
		var distance = randf() * 150.0
		unit.position = Vector2(cos(angle), sin(angle)) * distance
		
		print("Unit ", i, " position: ", unit.position)
		
		unit.add_to_group("units")
		add_child(unit)
		units.append(unit)
	
	print("Created ", units.size(), " units")

func _input(event):
	# Keyboard controls
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			# Reload game
			print("Reloading...")
			get_tree().reload_current_scene()
			return
		elif event.keycode == KEY_F:
			# Focus camera on selected units
			if camera and camera.has_method("focus_on_selected_units"):
				camera.focus_on_selected_units()
			return
		elif event.keycode == KEY_O:
			# Add obstacle at mouse position
			var pos = get_world_mouse_position()
			var size = Vector2(randf_range(60, 120), randf_range(60, 120))
			obstacle_manager.add_obstacle(pos, size)
			print("Added obstacle at ", pos)
			return
		elif event.keycode == KEY_X:
			# Remove obstacle at mouse position
			var pos = get_world_mouse_position()
			var obstacle = obstacle_manager.get_obstacle_at_position(pos)
			if obstacle:
				obstacle_manager.remove_obstacle(obstacle)
				print("Removed obstacle at ", pos)
			else:
				print("No obstacle at ", pos)
			return
		elif event.keycode == KEY_C:
			# Clear all obstacles (with Shift held to prevent accidents)
			if event.shift_pressed:
				obstacle_manager.clear_all_obstacles()
				print("Cleared all obstacles")
			else:
				print("Press Shift+C to clear all obstacles")
			return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_world_pos = get_world_mouse_position()
			
			if event.pressed:
				selection_box.start_selection(mouse_world_pos)
			else:
				var box_rect = selection_box.end_selection()
				
				if box_rect.size.length() > 10:
					SelectionManager.select_units_in_box(box_rect, not event.shift_pressed)
				else:
					var clicked_unit = null
					
					for unit in units:
						if unit.has_method("is_point_inside") and unit.is_point_inside(mouse_world_pos):
							clicked_unit = unit
							break
					
					if clicked_unit:
						SelectionManager.select_unit(clicked_unit, not event.shift_pressed)
					else:
						if not event.shift_pressed:
							SelectionManager.deselect_all()
	
	elif event is InputEventMouseMotion:
		if selection_box.is_dragging:
			var mouse_world_pos = get_world_mouse_position()
			selection_box.update_selection(mouse_world_pos)
	
	# Handle right-click movement
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var target = get_world_mouse_position()
		var selected = SelectionManager.get_selected_units()
		
		for unit in selected:
			if unit and unit.has_method("set_target_position"):
				unit.set_target_position(target)
