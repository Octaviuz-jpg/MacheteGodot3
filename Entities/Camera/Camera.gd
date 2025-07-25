extends Camera

# Carga la funcionalidad de movimiento
var camera_movement = load("res://Entities/Camera/CameraController.gd").new()

# Velocidad de movimiento de la cámara
export var camera_speed := 10.0

# Aceleración de la cámara durante el movimiento
export var camera_acceleration := 0.15

# Multiplicador de velocidad al presionar Shift
export var camera_speed_multiplier := 2.5

# Sensibilidad del mouse para la cámara
export var camera_sensitivity := 0.1

# Altura a la que la camara se ubica en el eje vertical tras cambiar a modo contruccion
export var camera_height_for_build_mode := 10.0

# Duracion de la transición al cambiar a vista aérea
export var aerial_view_transition_duration := 1.0

# Variables para almacenar la posición de la cámara
var camera_view_x := 0.0
var camera_view_y := 0.0

# Variables para almacenar ultima posición posicion y rotación de la cámara
var last_translation := Vector3()
var last_rotation := Vector3()
var velocity := Vector3()

# Variables para almacenar el estado del mouse (DEBUG)
var mouse_captured := true

# Indica si la cámara está en modo vista aérea
export var is_aerial_view := false setget set_is_aerial_view

# Signal para cambiar el modo de vista entre aérea y normal
signal aerial_view_changed(is_aerial_view)

onready var tween := Tween.new()

func _ready():
	connect("aerial_view_changed", self, "_on_aerial_view_changed")

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	mouse_captured = true

	add_child(tween)


func _unhandled_input(event):
	camera_movement.process_input(self, event)

	if event is InputEventKey and event.scancode == KEY_SPACE and event.pressed:
		set_is_aerial_view(!is_aerial_view)


func _process(delta):
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	var direction = Vector3.ZERO
	var current_speed = camera_speed

	# Movimiento adelante/atrás (W/S)
	if Input.is_action_pressed("ui_up"):
		direction -= transform.basis.z
	if Input.is_action_pressed("ui_down"):
		direction += transform.basis.z
	
	# Movimiento izquierda/derecha (A/D)
	if Input.is_action_pressed("ui_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("ui_right"):
		direction += transform.basis.x
		
	# Movimiento arriba/abajo (Espacio/Ctrl)
	if Input.is_key_pressed(KEY_SPACE):
		direction += Vector3.UP
	if Input.is_key_pressed(KEY_CONTROL):
		direction -= Vector3.UP

	# Multiplicador de velocidad con Shift
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed *= camera_speed_multiplier

	# Movimiento con aceleración y desaceleración
	var target_velocity = direction.normalized() * current_speed
	velocity = velocity.linear_interpolate(target_velocity, camera_acceleration)
	translation += velocity * delta

func _on_aerial_view_changed(is_aerial):
	if is_aerial:
		if not tween.is_active():
			last_rotation = rotation_degrees
			last_translation = translation

		var target_translation = Vector3(translation.x, camera_height_for_build_mode, translation.z)
		var target_rotation = Vector3(-90, rotation_degrees.y, rotation_degrees.z)

		tween.interpolate_property(self, "translation", translation, target_translation, aerial_view_transition_duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		tween.interpolate_property(self, "rotation_degrees", rotation_degrees, target_rotation, aerial_view_transition_duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

		tween.connect("tween_all_completed", self, "_sync_mouse_rotation_vars", [], CONNECT_ONESHOT)
		tween.start()
	else:
		tween.interpolate_property(self, "translation", translation, last_translation, aerial_view_transition_duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		tween.interpolate_property(self, "rotation_degrees", rotation_degrees, last_rotation, aerial_view_transition_duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

		tween.connect("tween_all_completed", self, "_sync_mouse_rotation_vars", [], CONNECT_ONESHOT)
		tween.start()

func _sync_mouse_rotation_vars():
	camera_view_x = rotation_degrees.x
	camera_view_y = rotation_degrees.y

func set_is_aerial_view(value):
	is_aerial_view = value
	emit_signal("aerial_view_changed", is_aerial_view)