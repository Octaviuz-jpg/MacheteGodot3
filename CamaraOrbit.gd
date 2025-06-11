extends Spatial

export var camera_speed: float = 0.01
export var zoom_speed: float = 0.1
export var min_distance: float = 2.0
export var max_distance: float = 20.0

var _camera: Camera
var _distance: float = 5.0
var _angle_x: float = 0.0
var _angle_y: float = 0.5
var _mouse_pressed: bool = false

onready var zoom_slider = get_parent().get_node("CanvasLayer/ZoomSlider")


func _ready():
	_camera = get_node("camara3D")  
	if not _camera:
		push_error("No se encontró Camera3D como hijo")
	
	zoom_slider.min_value = min_distance
	zoom_slider.max_value = max_distance
	zoom_slider.value = _distance
	zoom_slider.connect("value_changed", self, "_on_zoom_changed")

	init_orbit(5.0)

func _on_zoom_changed(value):
	_distance = value
	_update_camera_position()

func init_orbit(room_size: float):
	_distance = clamp(room_size * 2.5, min_distance, max_distance * 2)  # Ajusta la distancia inicial
	max_distance = room_size * 2.0  # Asegura que pueda alejarse más en habitaciones grandes
	zoom_slider.max_value = max_distance  # Sincroniza el límite del slider
	_update_camera_position()

func _input(event):
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
	_distance = clamp(_distance * (factor*3), min_distance, max_distance)
	zoom_slider.value = _distance  # Mantener el slider sincronizado

func _update_camera_position():
	var target = get_parent()
	if not target or not _camera:
		return
	
	var pos = Vector3(
		_distance * sin(_angle_x) * cos(_angle_y),
		_distance * sin(_angle_y),
		_distance * cos(_angle_x) * cos(_angle_y)
	)
	
	_camera.translation = target.translation + pos
	_camera.look_at(target.translation, Vector3.UP)


func _on_ZoomSlider_value_changed(value):
	_distance = clamp(value, min_distance, max_distance)  # Aseguramos que esté dentro de los límites
	_update_camera_position()
