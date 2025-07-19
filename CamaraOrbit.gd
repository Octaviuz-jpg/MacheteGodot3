extends Spatial

export var camera_speed: float = 0.01
export var zoom_speed: float = 0.1
export var min_distance: float = 2.0
export var max_distance: float = 100.0

var _camera: Camera
var _distance: float = 5.0
var _angle_x: float = 0.0
var _angle_y: float = 0.5
var _mouse_pressed: bool = false
var modo_construccion := false
var vista_aerea_activa := false
var CamaraTrancada := false


onready var zoom_slider = get_parent().get_node("CanvasLayer/ZoomSlider")

func _ready():
	_camera = get_node("camara3D")
	if not _camera:
		push_error("No se encontró camara3D como hijo")

	zoom_slider.min_value = min_distance
	zoom_slider.max_value = max_distance
	zoom_slider.value = _distance
	zoom_slider.connect("value_changed", self, "_on_zoom_changed")

	init_orbit(5.0)

func init_orbit(room_size: float):
	_distance = clamp(room_size * 2.5, min_distance, max_distance * 2)
	max_distance = room_size * 2.0
	zoom_slider.max_value = max_distance
	_update_camera_position()

func _on_zoom_changed(value):
	_distance = value
	_update_camera_position()

func _on_ZoomSlider_value_changed(value):
	_distance = clamp(value, min_distance, max_distance)
	_update_camera_position()

func _input(event):
	if modo_construccion:
		return  # 🚫 Input bloqueado durante modo construcción

	if event is InputEventMouseButton:
		_mouse_pressed = event.pressed
		if event.button_index == BUTTON_WHEEL_UP:
			_handle_zoom(0.8)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			_handle_zoom(1.2)
		# No necesitas _update_camera_position() aquí, _handle_zoom ya lo llama
		# if _mouse_pressed:  # Asegura que solo se rote si el botón del ratón está presionado
		#     _handle_rotation(event.relative)

	if event is InputEventMouseMotion and _mouse_pressed:
		_handle_rotation(event.relative)
		# No necesitas _update_camera_position() aquí, _handle_rotation ya lo llama

	# Control de Zoom (Pinch-to-Zoom para Android)
	if event is InputEventMagnifyGesture:
		_distance = clamp(_distance / event.factor, min_distance, max_distance)
		if _ui_zoom_slider: # Sincroniza el slider con el zoom multitáctil
			_ui_zoom_slider.value = _distance
		_update_camera_position()
	
	


func _handle_rotation(relative: Vector2):
	_angle_x -= relative.x * camera_speed
	_angle_y = clamp(_angle_y - relative.y * camera_speed, 0.1, PI/2 - 0.1)
	_update_camera_position() # Mover _update_camera_position aquí para rotación

func _handle_zoom(factor: float):
	_distance = clamp(_distance * (factor * 3), min_distance, max_distance)
	zoom_slider.value = _distance

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

func set_modo_construccion(activo: bool):
	modo_construccion = activo

func activar_camara_construccion(activo: bool):
	var cam_construccion = get_tree().get_root().find_node("Camera", true, false)
	if cam_construccion and cam_construccion is Camera:
		cam_construccion.current = activo
		if _camera:
			_camera.current = not activo
	else:
		print("⚠️ Cámara de construcción no encontrada")

func _on_camita_pressed():
	ObjectSelector.objeto_seleccionado = "res://objetos/sofa blanco tipo1/sofa blanco.tscn"



	
	

func _on_vistaAerea_pressed():
	vista_aerea_activa = !vista_aerea_activa
	activar_camara_construccion(vista_aerea_activa)



func _on_trancarCamara_pressed():
	CamaraTrancada = !CamaraTrancada
	set_modo_construccion(CamaraTrancada)
