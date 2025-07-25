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

func _ready():
	_camera = get_node("camara3D")
	if not _camera:
		push_error("No se encontró Camera3D como hijo")
	else:
		_camera.far = 500.0
		_camera.keep_aspect = Camera.KEEP_WIDTH
		_camera.current = true  # Asegurar que esta cámara está activa
	init_orbit(5.0)

func init_orbit(room_size: float):
	_distance = clamp(room_size * 2.5, min_distance, max_distance * 2)
	max_distance = room_size * 4.0
	_update_camera_position()

func _input(event):
	if modo_construccion:
		return  # 🚫 Input bloqueado durante modo construcción

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
	# Control de Zoom (Pinch-to-Zoom para Android)
	if event is InputEventMagnifyGesture:
		_distance = clamp(_distance / event.factor, min_distance, max_distance)
		_update_camera_position()

func _handle_rotation(relative: Vector2):
	_angle_x -= relative.x * camera_speed
	_angle_y = clamp(_angle_y - relative.y * camera_speed, 0.1, PI/2 - 0.1)
	_update_camera_position()

func _handle_zoom(factor: float):
	_distance = clamp(_distance * factor, min_distance, max_distance)
	_update_camera_position()

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

func _on_vistaAerea_pressed():
	vista_aerea_activa = !vista_aerea_activa
	activar_camara_construccion(vista_aerea_activa)

func _on_trancarCamara_pressed():
	CamaraTrancada = !CamaraTrancada
	set_modo_construccion(CamaraTrancada)

func _on_camita_pressed():
	ObjectSelector.objeto_seleccionado = "res://Objeto2/nevera_ejecutiva.tscn"
func _on_ButtonModoCons_pressed():
	pass # Replace with function body.


func _on_RotarIzquierda_pressed():
	if ObjectSelector.vista_previa:
		ObjectSelector.vista_previa.rotate_y(deg2rad(-15))


func _on_RotarDerecha_pressed():
	if ObjectSelector.vista_previa:
		ObjectSelector.vista_previa.rotate_y(deg2rad(15))


func _on_Reload_pressed() -> void:
	get_tree().reload_current_scene()
	ObjectSelector.objeto_seleccionado = "res://Objeto2/nevera_ejecutiva.tscn"
	ObjectSelector.vista_previa=null
	ObjectSelector._save.objects.clear()
	print("reload")

func find_container():
	var root = get_parent()
	return root.get_node("DynamicRoom/Container")


func _on_Load_pressed() -> void:
	print("load")
	var test=ObjectSelector._save.load_save()
	var container = find_container()
	print(test.height)
	print(test.width)
	print(test.depth)
	for i in test.objects:
		# print(i.res_path)
		var obj = load(i.res_path).instance()
		container.add_child(obj)
		obj.translation=i.position


func _on_Save_pressed() -> void:
	ObjectSelector._save.height=MedidasSingleton.altura
	ObjectSelector._save.depth=MedidasSingleton.profundidad
	ObjectSelector._save.width=MedidasSingleton.anchura
	ObjectSelector._save.write_save()
	ObjectSelector._save.objects.clear()
	pass # Replace with function body.
