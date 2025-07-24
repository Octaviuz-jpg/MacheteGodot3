extends Node

onready var altura = $"%alturaText"
onready var profundidad = $"%profundidadText"
onready var anchura = $"%anchuraText"
onready var error_label = $"%ErrorLabel"

onready var viewport_container = $"%ViewportContainer"
onready var viewport_3d = $"%Viewport"
#onready var input_ui_container = $"%Panel"
onready var ui_bars_canvas_layer = $"%CanvasLayer_UI_Bars"
onready var Accept = $"%CanvasLayer_UI_Bars/AcceptDialog"
onready var nombre_input = $"CanvasLayer_UI_Bars/AcceptDialog/LineEdit"

var room_3d_scene_res = preload("res://Node3D.tscn")
var _camera_orbit_instance: Spatial = null
onready var mi_panel = get_node("Panel")

func _ready():
	viewport_container.visible = false
	ui_bars_canvas_layer.visible = false  # Ocultar al inicio
	error_label.text = ""
	viewport_3d.render_target_update_mode = Viewport.UPDATE_ALWAYS

func _on_Button_pressed():
	# Validación de campos vacíos
	if altura.text.empty() or profundidad.text.empty() or anchura.text.empty():
		error_label.text = "⚠️ ERROR: Todos los campos son obligatorios"
		return
	
	# Conversión a números
	var altura_val = float(altura.text) if altura.text.is_valid_float() else 0.0
	var anchura_val = float(anchura.text) if anchura.text.is_valid_float() else 0.0
	var profundidad_val = float(profundidad.text) if profundidad.text.is_valid_float() else 0.0

	if not _validar_medidas(altura_val, anchura_val, profundidad_val):
		error_label.text = "⚠️ ERROR: Las medidas deben estar entre 1 y 50"
		return

	# Almacenar medidas
	MedidasSingleton.altura = altura_val
	MedidasSingleton.anchura = anchura_val
	MedidasSingleton.profundidad = profundidad_val

	# Limpiar instancia previa
	for child in viewport_3d.get_children():
		child.queue_free()

	# Forzar fondo blanco
	viewport_3d.set_clear_mode(Viewport.CLEAR_MODE_ALWAYS)
	viewport_3d.set_transparent_background(false)

	# Instanciar nueva habitación
	var room_instance = room_3d_scene_res.instance()
	viewport_3d.add_child(room_instance)
	
	# Configurar cámara orbital
	_camera_orbit_instance = room_instance.get_node("CamaraOrbit")
	if _camera_orbit_instance:
		print("Cámara orbital configurada")
		_camera_orbit_instance.init_orbit(max(MedidasSingleton.anchura, MedidasSingleton.profundidad))
		
		# Asegurar que la cámara está activa
		var cam = _camera_orbit_instance.get_node("camara3D")
		if cam:
			cam.current = true
			print("Cámara activada")
	else:
		push_error("No se encontró CamaraOrbit en la escena 3D")
		return
	
	# Cambiar visibilidad de elementos UI
	#input_ui_container.visible = false
	mi_panel.visible = false
	viewport_container.visible = true
	ui_bars_canvas_layer.visible = true  # Mostrar barras de herramientas
	
	# Debug importante
	print("Elementos visibles:")
	print("ViewportContainer visible:", viewport_container.visible)
	print("UI Bars visible:", ui_bars_canvas_layer.visible)
	print("Número de hijos en viewport_3d:", viewport_3d.get_child_count())

func _validar_medidas(altura_val, anchura_val, profundidad_val) -> bool:
	return altura_val > 0 and altura_val <= 50 and anchura_val > 0 and anchura_val <= 50 and profundidad_val > 0 and profundidad_val <= 50


func _on_ZoomOut_pressed():
	if _camera_orbit_instance:
		# Llama a la función de zoom del script de la cámara
		# Factor 1.2 significa alejar (120% de la distancia actual)
		_camera_orbit_instance._handle_zoom(1.2)
	else:
		print("Error: _camera_orbit_instance no está asignado. La cámmara 3D no está lista.")


func _on_ZoomIn_pressed():
	if _camera_orbit_instance:
		# Llama a la función de zoom del script de la cámara
		# Factor 0.8 significa acercar (80% de la distancia actual)
		_camera_orbit_instance._handle_zoom(0.8)
	else:
		print("Error: _camera_orbit_instance no está asignado. La cámara 3D no está lista.")



func _on_Save_pressed():
	nombre_input.text = ""  # Limpiar texto anterior
	Accept.popup_centered()
	

func _on_AcceptDialog_confirmed():
	var nombre = nombre_input.text.strip_edges()
	if nombre.empty():
		nombre_input.placeholder_text = "¡Nombre requerido!"
		Accept.popup_centered()  # Mostrar nuevamente
		return
	
	if SistemaGuardado.guardar_proyecto(nombre, viewport_3d.get_child(0)):
		print("Proyecto guardado: ", nombre)
