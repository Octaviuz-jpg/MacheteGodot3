extends Camera

# Velocidad de movimiento de la cámara
export var speed = 10.0
# Multiplicador de velocidad al presionar Shift
export var shift_speed_multiplier = 2.5
# Sensibilidad del ratón
export var mouse_sensitivity = 0.1

var _rotation_x = 0.0
var _rotation_y = 0.0

func _ready():
	# Capturar el cursor del ratón para controlar la cámara
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Guardar la rotación inicial de la cámara
	_rotation_x = rotation_degrees.x
	_rotation_y = rotation_degrees.y

func _unhandled_input(event):
	# Rotación con el ratón
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_rotation_y -= event.relative.x * mouse_sensitivity
		_rotation_x -= event.relative.y * mouse_sensitivity
		# Limitar la rotación vertical para no dar la vuelta
		_rotation_x = clamp(_rotation_x, -90, 90)
		rotation_degrees = Vector3(_rotation_x, _rotation_y, 0)

	# Liberar/Capturar el cursor con la tecla Escape
	if event is InputEventKey and event.scancode == KEY_ESCAPE and event.pressed:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	# No mover la cámara si el cursor no está capturado
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	var direction = Vector3.ZERO
	var current_speed = speed

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
		current_speed *= shift_speed_multiplier

	# Aplicar el movimiento
	translation += direction.normalized() * current_speed * delta
