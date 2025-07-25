#ESCENE PRINCIPAL TAIRON
extends Spatial

var block_scene = preload("res://Scenes/tairon/Scenes/Block.tscn")

export (NodePath) var raycast_path : NodePath
onready var raycast = get_node(raycast_path) as RayCast

export (NodePath) var camera_path : NodePath
onready var camera = get_node(camera_path) as Camera

onready var blocks_container = $BlocksContainer

# Variables para selección
var selected_block = null
var normal_material = null
var selected_material = null

# Variables para arrastre
var is_dragging = false
var drag_offset = Vector3.ZERO
var original_position = Vector3.ZERO

# Variables para doble clic
var click_count = 0
var last_click_time = 0.0
var last_clicked_block = null
var double_click_threshold = 0.3 # 300ms para doble clic

# Variables de UI
onready var delete_button = $CanvasLayer/DeleteButton
onready var scale_slider = $CanvasLayer/ScaleSlider
onready var create_button = $CanvasLayer/CreateButton
onready var rotate_button = $CanvasLayer/RotateButton

# Managers
onready var scene_state_manager = $SceneStateManager

# Variables de guardado/carga
var auto_save_timer: Timer
var last_save_time = 0.0
var save_interval = 30.0 # Auto-guardar cada 30 segundos

func _ready():
	# 1. VERIFICAR AUTENTICACIÓN
	if not AuthManager.is_authenticated():
		print("Usuario no autenticado. Redirigiendo a Login.")
		get_tree().change_scene("res://Scenes/Login.tscn")
		return # Detener la ejecución de _ready() aquí

	# 2. SI ESTÁ AUTENTICADO, CONTINUAR CON LA LÓGICA DE LA ESCENA
	print("Usuario autenticado. Cargando escena de Tairon.")

	if raycast == null:
		print("❌ RayCast no encontrado.")
	else:
		print("✅ RayCast listo.")


	# Conectar controles de UI
	delete_button.connect("pressed", self, "_on_delete_button_pressed")
	scale_slider.connect("value_changed", self, "_on_scale_slider_changed")
	create_button.connect("pressed", self, "_on_create_button_pressed")
	rotate_button.connect("pressed", self, "_on_rotate_button_pressed")

	# Crear bloque de prueba automáticamente
	var test_position = Vector3(0, 1, 0) # Posición en el centro
	var test_block = block_scene.instance()
	test_block.translation = test_position
	test_block.scale = Vector3(4.0, 3.5, 0.25) # Dimensiones de pared
	blocks_container.add_child(test_block)
	# Seleccionar automáticamente el bloque de prueba
	select_block(test_block)

	# Conectar señales de Supabase para guardado/carga
	SupabaseManager.connect("scene_saved", self, "_on_scene_saved")
	SupabaseManager.connect("scene_loaded", self, "_on_scene_loaded")
	SupabaseManager.connect("error_occurred", self, "_on_supabase_error")

	# Iniciar la carga de datos y el auto-guardado
	load_scene_from_database()
	setup_auto_save()


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				# Verificar si el clic fue en un elemento de UI
				if get_node_or_null("AuthUI") != null or is_click_on_ui(event.position):
					return # No procesar interacción 3D si la UI de Auth está visible

				# En PC, no pasar posición para usar el raycast tradicional
				if OS.get_name() == "Android":
					handle_left_click(event.position) # Touch en móvil
				else:
					handle_left_click() # Mouse en PC
			else:
				if is_dragging:
					finish_drag()

	elif event is InputEventMouseMotion:
		if is_dragging:
			# Similar lógica para drag
			if OS.get_name() == "Android":
				update_drag_position(event.position)
			else:
				update_drag_position()


func is_click_on_ui(click_position: Vector2) -> bool:
	# Verificar si el clic está sobre algún botón visible
	var ui_elements = [delete_button, create_button, rotate_button]

	for element in ui_elements:
		if element.visible and element.get_global_rect().has_point(click_position):
			return true

	# Comprobar si la UI de autenticación está activa
	var auth_ui = get_node_or_null("AuthUI")
	if auth_ui and auth_ui.visible:
		if auth_ui.get_global_rect().has_point(click_position):
			return true

	return false


func handle_left_click(touch_position = null):
	if touch_position != null:
		var from = camera.project_ray_origin(touch_position)
		var to = from + camera.project_ray_normal(touch_position) * 100
		print("Raycast desde posición táctil: ", from, " a ", to)
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(from, to)

		if result:
			var collider = result.collider
			var collision_point = result.position
			process_collision(collider, collision_point)
	# Si no hay colisión, no hacer nada (permitir movimiento de cámara)
	else:
		# Usar el raycast tradicional del crosshair
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			var collision_point = raycast.get_collision_point()
			process_collision(collider, collision_point)


func process_collision(collider, collision_point):
	var current_time = OS.get_ticks_msec() / 1000.0

	if collider.get_parent().has_method("is_block"):
		var block = collider.get_parent()
		if selected_block == block:
			# Verificar doble clic
			if last_clicked_block == block and (current_time - last_click_time) < double_click_threshold:
				deselect_block()
			else:
				start_drag(collision_point)
		else:
			select_block(block)

		# Actualizar variables de doble clic
		last_clicked_block = block
		last_click_time = current_time


# FUNCIONES PARA SELECCIONAR BLOQUE
func select_block(block):
	# Deseleccionar bloque anterior
	if selected_block != null:
		var mesh_instance = selected_block.get_node("StaticBody/MeshInstance")
		mesh_instance.material_override = normal_material

	# Seleccionar nuevo bloque
	selected_block = block
	var mesh_instance = block.get_node("StaticBody/MeshInstance")
	mesh_instance.material_override = selected_material
	
	# Mostrar controles de UI
	delete_button.visible = true
	scale_slider.visible = true
	scale_slider.value = selected_block.scale.x # Sincronizar con escala actual
	rotate_button.visible = true # Mostrar botón de rotación


func deselect_block():
	if selected_block != null:
		var mesh_instance = selected_block.get_node("StaticBody/MeshInstance")
		mesh_instance.material_override = normal_material
		selected_block = null

		# Ocultar controles de UI
		delete_button.visible = false
		scale_slider.visible = false
		rotate_button.visible = false # Ocultar botón de rotación


func _on_scale_slider_changed(value):
	if selected_block != null:
		selected_block.scale.x = value


func _on_delete_button_pressed():
	if selected_block != null:
		delete_block(selected_block)
		delete_button.visible = false


func _on_create_button_pressed():
	print("Raycast activo: ", raycast.is_enabled())
	var crosshair = $CanvasLayer/Label # El crosshair "+"
	# Verificar si el raycast está detectando algo
	if not raycast.is_colliding():
		# Cambiar color del crosshair a rojo por 1 segundo
		print("❌ No hay colisión detectada")
		crosshair.modulate = Color.red
		yield(get_tree().create_timer(1.0), "timeout")
		crosshair.modulate = Color.white
		return # No hacer nada si no hay colisión

	var collider = raycast.get_collider()
	var collision_point = raycast.get_collision_point()

	# Verificar si es el suelo usando diferentes métodos
	var is_floor = false

	# Método 1: Por nombre del padre
	# DEBUG ALL IF
	print("Collider padre: ", collider.get_parent().name)
	print("Collider en posición Y: ", collision_point.y <= 1.0)
	print("Collider en grupo 'floor': ", collider.get_parent().is_in_group("floor"))

	if collider.get_parent().name == "Floor":
		is_floor = true
		crosshair.modulate = Color.green
		yield(get_tree().create_timer(1.0), "timeout")
		crosshair.modulate = Color.white
	# Método 2: Por posición Y (el suelo debería estar en Y=0 o cerca)
	elif collision_point.y <= 1.0:
		is_floor = true
	# Método 3: Por grupo (si agregas el suelo a un grupo)
	elif collider.get_parent().is_in_group("floor"):
		is_floor = true

	print("Colisión detectada con: ", collider.name)
	if is_floor:
		place_new_block(collision_point)


func _on_rotate_button_pressed():
	if selected_block != null:
		selected_block.rotation_degrees.y += 90


func place_new_block(position):
	var point = position.snapped(Vector3.ONE)
	# Colocar el bloque directamente en el suelo (Y=0)
	point.y = 1.0 # Altura para que la base del bloque toque el suelo
	var block = block_scene.instance()
	block.translation = point

	# Establecer dimensiones de pared
	block.scale = Vector3(5.0, 3.5, 0.25)

	$BlocksContainer.add_child(block)

	var mesh_instance = block.get_node("StaticBody/MeshInstance")
	mesh_instance.material_override = normal_material


func delete_block(block):
	if block == null:
		return

	# Si es el bloque seleccionado, deseleccionarlo primero
	if selected_block == block:
		deselect_block()

	# Eliminar el bloque del contenedor
	if block.get_parent() == $BlocksContainer:
		block.queue_free()

	# Resetear variables de clic
	click_count = 0
	last_clicked_block = null


# FUNCIONES DE ARRASTRE
func start_drag(collision_point):
	is_dragging = true
	original_position = selected_block.translation

	# Calcular offset solo en X y Z, ignorar Y completamente
	var snapped_point = collision_point.snapped(Vector3.ONE)
	snapped_point.y = selected_block.translation.y # Forzar misma altura
	drag_offset = selected_block.translation - snapped_point
	drag_offset.y = 0 # Eliminar cualquier componente Y del offset

	# Cambiar material para indicar arrastre
	var drag_material = preload("res://materials/selectedBlock.tres")
	drag_material.albedo_color = Color.bisque
	drag_material.flags_transparent = true
	drag_material.albedo_color.a = 0.7

	var mesh_instance = selected_block.get_node("StaticBody/MeshInstance")
	mesh_instance.material_override = drag_material


func update_drag_position(touch_position = null):
	var new_position

	if touch_position != null:
		var from = camera.project_ray_origin(touch_position)
		var to = from + camera.project_ray_normal(touch_position) * 100

		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(from, to)

		if result:
			new_position = result.position.snapped(Vector3.ONE) + drag_offset
		else:
			return # No hacer nada si no hay colisión
	else:
		if raycast.is_colliding():
			new_position = raycast.get_collision_point().snapped(Vector3.ONE) + drag_offset
		else:
			return

	# Mantener SIEMPRE la altura original, sin excepciones
	new_position.y = original_position.y
	selected_block.translation = new_position


func finish_drag():
	is_dragging = false

	# Verificar si la posición final es válida
	if is_valid_position(selected_block.translation):
		# Restaurar material de selección
		var mesh_instance = selected_block.get_node("StaticBody/MeshInstance")
		mesh_instance.material_override = selected_material
	else:
		# Revertir a posición original si no es válida
		selected_block.translation = original_position
		var mesh_instance = selected_block.get_node("StaticBody/MeshInstance")
		mesh_instance.material_override = selected_material


func is_valid_position(position):
	# Verificar que no haya otro bloque en esa posición
	for child in $BlocksContainer.get_children():
		if child != selected_block and child.translation.distance_to(position) < 0.5:
			return false
	return true


# Botones de movimiento de cámara
func _on_TextureButton_button_up():
	Input.action_release("ui_up")


func _on_TextureButton_button_down():
	Input.action_press("ui_up")


# Botones Derecha
func _on_right_button_down():
	Input.action_press("ui_right")


func _on_right_button_up():
	Input.action_release("ui_right")


# Botones Izquierda
func _on_left_button_down():
	Input.action_press("ui_left")


func _on_left_button_up():
	Input.action_release("ui_left")


# Botones Atras
func _on_down_button_down():
	Input.action_press("ui_down")


func _on_down_button_up():
	Input.action_release("ui_down")

# ===== FUNCIONES DE SUPABASE (SIN AUTENTICACIÓN) =====

func setup_auto_save():
	# Crear timer para auto-guardado
	auto_save_timer = Timer.new()
	auto_save_timer.connect("timeout", self, "_on_auto_save_timeout")
	auto_save_timer.wait_time = save_interval
	auto_save_timer.autostart = true
	add_child(auto_save_timer)
	print("⏰ Auto-guardado configurado cada ", save_interval, " segundos")


# Guardar estado actual en Supabase
func save_scene_to_database():
	print("💾 Guardando escena en base de datos...")
	var scene_data = scene_state_manager.capture_scene_state()
	SupabaseManager.save_scene_state(scene_data)


func load_scene_from_database():
	print("📥 Cargando escena desde base de datos...")
	SupabaseManager.load_scene_state()


# Callbacks de Supabase
func _on_scene_saved(success: bool):
	if success:
		print("✅ Escena guardada exitosamente")
		last_save_time = OS.get_ticks_msec() / 1000.0
		# Aquí podrías mostrar una notificación en la UI
	else:
		print("❌ Error al guardar escena")


func _on_scene_loaded(scene_data: Dictionary):
	if not scene_data.empty():
		print("📦 Datos cargados, restaurando escena...")
		# Primero limpiar el bloque de prueba si existe
		clear_test_blocks()
		# Restaurar escena desde datos
		scene_state_manager.restore_scene_state(scene_data)
	else:
		print("ℹ️ No hay datos guardados, iniciando con escena por defecto")


func _on_supabase_error(error_message: String):
	print("❌ Error de Supabase: ", error_message)
	# Aquí podrías mostrar el error en la UI


func _on_auto_save_timeout():
	# Guardar automáticamente si han pasado algunos segundos desde el último cambio
	var current_time = OS.get_ticks_msec() / 1000.0
	if current_time - last_save_time > 5.0: # Si han pasado 5+ segundos sin guardar
		save_scene_to_database()


func _on_scene_restored():
	# Callback llamado cuando se restaura la escena
	print("🎯 Escena restaurada completamente")
	# Deseleccionar cualquier bloque seleccionado
	deselect_block()


func clear_test_blocks():
	# Limpiar bloques de prueba antes de cargar datos guardados
	for child in blocks_container.get_children():
		if child.has_method("is_block"):
			child.queue_free()


# Funciones manuales de guardado/carga (para botones)
func manual_save():
	print("🖱️ Guardado manual iniciado")
	save_scene_to_database()


func manual_load():
	print("🖱️ Carga manual iniciada")
	load_scene_from_database()


# Función para obtener estadísticas
func get_project_stats():
	var stats = scene_state_manager.get_scene_stats()
	print("📊 Estadísticas del proyecto:")
	print("   Bloques totales: ", stats.total_blocks)
	print("   Volumen total: ", stats.total_volume)
