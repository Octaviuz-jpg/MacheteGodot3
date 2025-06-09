extends Spatial

export var camera_speed: float = 0.01
export var zoom_speed: float = 0.1
export var min_distance: float = 2.0
export var max_distance: float = 10.0

var _camera: Camera
var _distance: float = 5.0
var _angle_x: float = 0.0
var _angle_y: float = 0.5
var _touch_start_pos: Vector2
var _is_touching: bool = false
var _mouse_pressed: bool = false

func _ready():
	_camera = get_node("camara3D")  # En Godot 3, usamos get_node en lugar de find_child
	if not _camera:
		push_error("No se encontró Camera3D como hijo")
	init_orbit(5.0)

func init_orbit(room_size: float):
	_distance = room_size * 1.5
	min_distance = room_size * 0.5
	max_distance = room_size * 3.0
	_update_camera_position()

func _input(event):
	# Controles para móvil
	if event is InputEventScreenTouch:
		_is_touching = event.pressed
		if _is_touching:
			_touch_start_pos = event.position
			
	if event is InputEventScreenDrag and _is_touching:
		_handle_rotation(event.relative)
		_update_camera_position()
	
	# Controles para PC
	if event is InputEventMouseButton:
		_mouse_pressed = event.pressed
		if event.button_index == BUTTON_WHEEL_UP:
			_handle_zoom(0.8)
			_update_camera_position()
		elif event.button_index == BUTTON_WHEEL_DOWN:
			_handle_zoom(1.2)
			_update_camera_position()
			
	if event is InputEventMouseMotion and _mouse_pressed:
		_handle_rotation(event.relative)
		_update_camera_position()

func _handle_rotation(relative: Vector2):
	_angle_x -= relative.x * camera_speed
	_angle_y = clamp(_angle_y - relative.y * camera_speed, 0.1, PI/2 - 0.1)

func _handle_zoom(factor: float):
	_distance = clamp(_distance * factor, min_distance, max_distance)

func _update_camera_position():
	var target = get_parent().get_node("DynamicRoom")  # Cambiado get_node
	if not target or not _camera:
		return
		
	var pos = Vector3(
		_distance * sin(_angle_x) * cos(_angle_y),
		_distance * sin(_angle_y),
		_distance * cos(_angle_x) * cos(_angle_y)
	)
	
	_camera.translation = target.translation + pos  # En Godot 3 usamos translation en lugar de global_position
	_camera.look_at(target.translation, Vector3.UP)

