extends Node3D


@onready var camera = $Camera3D
@export var sensitivity: float = 0.5
@export var move_speed: float = 5.0


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta):
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	global_position += \
		(camera.global_basis.z * input.y +
		camera.global_basis.x * input.x) * move_speed * delta
		 

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x/100.0*sensitivity)
		camera.rotate_x(-event.relative.y/100.0*sensitivity)
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -80, 80)
		
