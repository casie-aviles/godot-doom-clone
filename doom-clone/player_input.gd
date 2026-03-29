extends Node

signal look_input(delta_x: float, delta_y: float)
signal action_triggered(action: String)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		emit_signal("look_input", event.relative.x, event.relative.y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	for action in ["shoot", "kick", "slide", "exit", "restart"]:
		if Input.is_action_just_pressed(action):
			emit_signal("action_triggered", action)
