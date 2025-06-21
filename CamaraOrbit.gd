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

# ¡IMPORTANTE! Eliminar la línea onready var zoom_slider = get_parent().get_node("CanvasLayer/ZoomSlider")
# Usaremos esta variable para que Control.gd nos pase la referencia
var _ui_zoom_slider: HSlider = null # Usamos el tipo explícito para HSlider

func _ready():
	_camera = get_node("camara3D")
	if not _camera:
		push_error("No se encontró Camera3D como hijo");
	if _camera:
	 _camera.far = 500.0  # Aumenta el plano lejano de renderizado
	_camera.keep_aspect = Camera.KEEP_WIDTH  # Mantener relación de aspecto
	
	# Eliminamos la conexión y configuración inicial del slider aquí,
	# ya que Control.gd lo hará cuando instancie la escena 3D.
	
	# init_orbit(5.0) # Ya no es necesario llamar esto aquí, Control.gd lo hará.

# Nueva función para que Control.gd pase la referencia del slider y configure sus propiedades
func set_zoom_slider_properties(slider_node: HSlider):
	_ui_zoom_slider = slider_node
	if _ui_zoom_slider:
		_ui_zoom_slider.min_value = min_distance
		# El max_value del slider se ajustará también en init_orbit
		_ui_zoom_slider.value = _distance # Sincroniza el slider con la distancia actual de la cámara

# Función para que Control.gd actualice la distancia de la cámara desde el slider
func _set_distance_from_slider(value: float):
	_distance = clamp(value, min_distance, max_distance)
	_update_camera_position()
	
# Ajustada la lógica de init_orbit
func init_orbit(room_size: float):
	_distance = clamp(room_size * 2.5, min_distance, max_distance * 2) # Ajusta la distancia inicial
	max_distance = room_size * 4.0 # Asegura que pueda alejarse más en habitaciones grandes
	
	if _ui_zoom_slider: # Si el slider ha sido seteado, actualiza su max_value y su valor actual
		_ui_zoom_slider.max_value = max_distance
		_ui_zoom_slider.value = _distance
	
	_update_camera_position()

func _input(event):
	# Controles para PC
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
	_distance = clamp(_distance * factor, min_distance, max_distance) # Factor debe ser directo
	if _ui_zoom_slider: # Mantener el slider sincronizado
		_ui_zoom_slider.value = _distance
	_update_camera_position() # Mover _update_camera_position aquí para zoom

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
	
func _on_camita_pressed():
	ObjectSelector.objeto_seleccionado = "res://objetos/cama/source/cama.tscn"
	
	
