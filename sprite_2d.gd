extends Node2D

var target_position = position
var speed = 1000

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		target_position = event.position

func _process(delta):
	position = position.move_toward(target_position, speed * delta)
