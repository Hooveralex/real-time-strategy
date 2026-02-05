extends Node

# Singleton/Autoload for managing unit selection
signal selection_changed(selected_units: Array)

var selected_units: Array[Node] = []
var selection_box_start: Vector2
var is_dragging_selection = false

func _ready():
	pass

func select_unit(unit: Node, clear_existing: bool = true):
	# Check if unit is valid
	if not is_instance_valid(unit):
		return
	
	if clear_existing:
		deselect_all()
	
	# Clean up any freed instances before checking
	selected_units = selected_units.filter(func(u): return is_instance_valid(u))
	
	if unit in selected_units:
		# Deselect if already selected
		deselect_unit(unit)
	else:
		# Select the unit
		selected_units.append(unit)
		if unit.has_method("set_selected"):
			unit.set_selected(true)
	
	selection_changed.emit(selected_units)

func deselect_unit(unit: Node):
	if not is_instance_valid(unit):
		# Clean up freed instances
		selected_units = selected_units.filter(func(u): return is_instance_valid(u))
		selection_changed.emit(selected_units)
		return
	
	var index = selected_units.find(unit)
	if index != -1:
		selected_units.remove_at(index)
		if unit.has_method("set_selected"):
			unit.set_selected(false)
	
	selection_changed.emit(selected_units)

func deselect_all():
	# Clean up any freed instances first
	selected_units = selected_units.filter(func(unit): return is_instance_valid(unit))
	
	for unit in selected_units:
		if is_instance_valid(unit) and unit.has_method("set_selected"):
			unit.set_selected(false)
	selected_units.clear()
	selection_changed.emit(selected_units)

func select_units_in_box(box_rect: Rect2, clear_existing: bool = true):
	if clear_existing:
		deselect_all()
	
	# Clean up any freed instances first
	selected_units = selected_units.filter(func(unit): return is_instance_valid(unit))
	
	# Get all units in the scene
	var units = get_tree().get_nodes_in_group("units")
	
	for unit in units:
		if not is_instance_valid(unit):
			continue
		
		if unit.has_method("get_selection_bounds"):
			var unit_bounds = unit.get_selection_bounds()
			if box_rect.intersects(unit_bounds):
				if unit not in selected_units:
					selected_units.append(unit)
					if unit.has_method("set_selected"):
						unit.set_selected(true)
	
	selection_changed.emit(selected_units)

func get_selected_units() -> Array[Node]:
	# Clean up freed instances before returning
	selected_units = selected_units.filter(func(unit): return is_instance_valid(unit))
	return selected_units.duplicate()
