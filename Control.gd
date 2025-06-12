extends Node

onready var altura = $"%alturaText"
onready var profundidad = $"%profundidadText"
onready var anchura = $"%anchuraText"
onready var error_label = $"%ErrorLabel"  # Asegúrate de tener un Label para mostrar el error

# Referencias a los nodos del Viewport
onready var viewport_container = $"%ViewportContainer" # Asumiendo que has nombrado tu ViewportContainer
onready var viewport_3d = $"%Viewport" # Asumiendo que has nombrado tu Viewport

# Referencia al contenedor de la UI de entrada de parámetros
# Asegúrate que el VBoxContainer que tiene tus LineEdits y Button tiene el nombre único (%)
onready var input_ui_container = $"%VBoxContainer" 

# Referencia al CanvasLayer que contiene las barras de herramientas
onready var ui_bars_canvas_layer = $"%CanvasLayer_UI_Bars" 
onready var hslider_zoom = $"%CanvasLayer_UI_Bars/Zoom" # <--- RUTA CORREGIDA según tu imagen
onready var bottom_bar = $"%CanvasLayer_UI_Bars/BottomBar" # Nueva ruta

# Precargar tu escena 3D (la que contiene Spatial, CamaraOrbit, DynamicRoom)
# ¡CAMBIA ESTA RUTA SI TU ESCENA 3D TIENE OTRO NOMBRE!
var room_3d_scene_res = preload("res://Node3D.tscn")

var _camera_orbit_instance: Spatial = null

func _ready():
	# Asegurarse de que el ViewportContainer esté oculto al inicio
	viewport_container.visible = false
	error_label.text = "" # Limpiar el error label al inicio

func _on_Button_pressed():
	var altura_val = float(altura.text)
	var anchura_val = float(anchura.text)
	var profundidad_val = float(profundidad.text)
	

	if not _validar_medidas(altura_val, anchura_val, profundidad_val):
		error_label.text = "⚠️ Las medidas deben estar entre 1 y 50."
		return

	MedidasSingleton.altura = altura_val
	MedidasSingleton.anchura = anchura_val
	MedidasSingleton.profundidad = profundidad_val

	print("Valores almacenados:")
	print("Altura:", MedidasSingleton.altura)
	print("Anchura:", MedidasSingleton.anchura)
	print("Profundidad:", MedidasSingleton.profundidad)
	error_label.text = ""  # Oculta el mensaje de error al corregir los valores
	#get_tree().change_scene("res://Node3D.tscn")
		# --- LÓGICA PARA CARGAR EL MUNDO 3D Y OCULTAR LA UI DE ENTRADA ---
	
	# 1. Limpiar cualquier instancia 3D previa en el Viewport
	# Esto evita que se acumulen múltiples habitaciones si el usuario presiona "generar" varias veces
	for child in viewport_3d.get_children():
		child.queue_free() # Libera el nodo anterior de la escena 3D

	# 2. Instanciar la escena 3D y añadirla al Viewport
	var room_instance = room_3d_scene_res.instance()
	viewport_3d.add_child(room_instance)
	
		# 3. Almacenar la referencia a CamaraOrbit desde la instancia de la escena 3D
	_camera_orbit_instance = room_instance.get_node("CamaraOrbit")
	if _camera_orbit_instance:
		print("CamaraOrbit obtenida exitosamente.")
		# PASAR LA REFERENCIA DEL SLIDER A CAMARAORBIT
		if hslider_zoom:
			_camera_orbit_instance.set_zoom_slider_properties(hslider_zoom)
		# Llamar a init_orbit para posicionar la cámara inicialmente
		_camera_orbit_instance.init_orbit(max(MedidasSingleton.anchura, MedidasSingleton.anchura)) # Usé anchura dos veces, ¿quizás querías profundidad aquí?
	else:
		push_error("No se encontró CamaraOrbit en la escena 3D instanciada.")
	
	# 3. Ocultar la UI de entrada de parámetros
	# Asumo que tu VBoxContainer es el padre directo de tus campos de entrada y botón.
	input_ui_container.visible = false 

	# 4. Mostrar el ViewportContainer con la vista 3D
	viewport_container.visible = true
	
	  # 6. Mostrar las barras de herramientas y el slider (todo el CanvasLayer)
	ui_bars_canvas_layer.visible = true


func _validar_medidas(altura_val, anchura_val, profundidad_val) -> bool:
	return altura_val > 0 and altura_val <= 50 and anchura_val > 0 and anchura_val <= 50 and profundidad_val > 0 and profundidad_val <= 50
	
	
# --- FUNCIONES PARA LOS BOTONES DE LA BARRA DE HERRAMIENTAS Y EL SLIDER ---

func _on_Button_ZoomIn_pressed():
	if _camera_orbit_instance:
		_camera_orbit_instance._handle_zoom(0.8)

func _on_Button_ZoomOut_pressed():
	if _camera_orbit_instance:
		_camera_orbit_instance._handle_zoom(1.2)

func _on_HSlider_Zoom_value_changed(value):
	if _camera_orbit_instance:
		_camera_orbit_instance._set_distance_from_slider(value)

