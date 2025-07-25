extends Spatial

# --- NODOS DE LA ESCENA ---
onready var blocks_container: Spatial = $BlocksContainer
onready var objects_container: Spatial = $ObjectsContainer
onready var back_button: Button = $CanvasLayer/BackButton
onready var add_object_button: Button = $CanvasLayer/AddObjectButton
onready var delete_object_button: Button = $CanvasLayer/DeleteObjectButton
onready var camera: Camera = $Camera
onready var floor_node: StaticBody = $Floor

# --- LÓGICA DE OBJETOS ---
const BlockScene = preload("res://Scenes/tairon/Scenes/Block.tscn")
var selected_object = null
var original_materials = {} # Para restaurar el color original al deseleccionar

func _ready():
	# --- VALIDACIÓN DE NODOS ---
	if not blocks_container: push_error("ERROR: No se encontró 'BlocksContainer'")
	if not objects_container: push_error("ERROR: No se encontró 'ObjectsContainer'")
	if not back_button: push_error("ERROR: No se encontró 'BackButton'")
	if not add_object_button: push_error("ERROR: No se encontró 'AddObjectButton'")
	if not delete_object_button: push_error("ERROR: No se encontró 'DeleteObjectButton'")
	
	# --- CONEXIONES DE SEÑALES ---
	back_button.connect("pressed", self, "_on_back_button_pressed")
	add_object_button.connect("pressed", self, "_on_add_object_button_pressed")
	delete_object_button.connect("pressed", self, "_on_delete_object_button_pressed")

	# --- INICIALIZACIÓN ---
	load_tairon_structure()
	ObjectSelector.objeto_seleccionado = ""
	ObjectSelector.vista_previa = null
	delete_object_button.visible = false


func load_tairon_structure():
	print("Iniciando carga de estructura Tairon...")
	for child in blocks_container.get_children(): child.queue_free()

	SupabaseManager.load_scene_state()
	var scene_data = yield(SupabaseManager, "scene_loaded")

	if scene_data and scene_data.has("blocks"):
		var bloques = scene_data.blocks
		for bloque_data in bloques:
			if "position" in bloque_data and "scale" in bloque_data:
				var block_instance = BlockScene.instance()
				var pos_dict = bloque_data.position
				block_instance.translation = Vector3(pos_dict.x, pos_dict.y, pos_dict.z)
				var scale_dict = bloque_data.scale
				block_instance.scale = Vector3(scale_dict.x, scale_dict.y, scale_dict.z)
				if "rotation" in bloque_data:
					var rot_dict = bloque_data.rotation
					block_instance.rotation_degrees = Vector3(rot_dict.x, rot_dict.y, rot_dict.z)
				blocks_container.add_child(block_instance)
		print("¡Estructura Tairon cargada exitosamente!")
	else:
		print("Error al cargar la estructura Tairon o no se encontraron datos.")

# --- MANEJO DE BOTONES ---

func _on_back_button_pressed():
	if ObjectSelector.vista_previa:
		ObjectSelector.vista_previa.queue_free()
		ObjectSelector.vista_previa = null
		
	deselect_object()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene("res://Node3D.tscn")

func _on_add_object_button_pressed():
	deselect_object()
	ObjectSelector.objeto_seleccionado = "res://Objeto2/nevera_ejecutiva.tscn"
	print("Objeto seleccionado: ", ObjectSelector.objeto_seleccionado)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_delete_object_button_pressed():
	if selected_object:
		selected_object.queue_free()
		selected_object = null
		original_materials.clear()
		delete_object_button.visible = false


# --- LÓGICA DE COLOCACIÓN Y SELECCIÓN DE OBJETOS ---

func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		if ObjectSelector.vista_previa:
			if hay_colision_con_pared(ObjectSelector.vista_previa):
				print("Colisión con pared, no se puede colocar.")
				return

			var mouse_pos = get_viewport().get_mouse_position()
			var desde = camera.project_ray_origin(mouse_pos)
			var hacia = desde + camera.project_ray_normal(mouse_pos) * 1000
			
			var exclude_array = [ObjectSelector.vista_previa]
			var result = get_world().direct_space_state.intersect_ray(desde, hacia, exclude_array, 1)

			var placement_position = null
			if result:
				if result.collider.is_in_group("suelo"):
					placement_position = result.position
				elif result.collider.is_in_group("blocks"):
					# Si golpea un bloque, no se coloca el objeto
					return
			else:
				var plane = Plane(Vector3.UP, floor_node.translation.y)
				var intersection = plane.intersects_ray(desde, hacia)
				if intersection:
					placement_position = intersection

			if placement_position != null:
				colocar_objeto_en_suelo(ObjectSelector.objeto_seleccionado, placement_position)
				ObjectSelector.vista_previa.queue_free()
				ObjectSelector.vista_previa = null
				ObjectSelector.objeto_seleccionado = ""

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		if not ObjectSelector.vista_previa:
			# Handle object selection for deletion
			var mouse_pos = get_viewport().get_mouse_position()
			var from = camera.project_ray_origin(mouse_pos)
			var to = from + camera.project_ray_normal(mouse_pos) * 1000
			var space_state = get_world().direct_space_state
			var result = space_state.intersect_ray(from, to, [self])

			if result:
				var node = result.collider
				var object_root = null
				
				var current = node
				while current != null:
					if current.get_parent() == objects_container:
						object_root = current
						break
					current = current.get_parent()

				if object_root:
					if selected_object == object_root:
						deselect_object()
					else:
						select_object(object_root)
				else:
					deselect_object()
			else:
				deselect_object()


func _process(delta):
	if ObjectSelector.objeto_seleccionado != "" and not ObjectSelector.vista_previa:
		ObjectSelector.vista_previa = crear_vista_previa(ObjectSelector.objeto_seleccionado)

	if ObjectSelector.vista_previa:
		var target_position = null
		var mouse_pos = get_viewport().get_mouse_position()
		var desde = camera.project_ray_origin(mouse_pos)
		var hacia = desde + camera.project_ray_normal(mouse_pos) * 1000
		var exclude_array = [ObjectSelector.vista_previa]
		var result = get_world().direct_space_state.intersect_ray(desde, hacia, exclude_array, 1)

		if result:
			if result.collider.is_in_group("suelo") or result.collider.is_in_group("blocks"):
				target_position = result.position
			else:
				var plane = Plane(Vector3.UP, floor_node.translation.y)
				var intersection = plane.intersects_ray(desde, hacia)
				if intersection:
					target_position = intersection
		else:
			var plane = Plane(Vector3.UP, floor_node.translation.y)
			var intersection = plane.intersects_ray(desde, hacia)
			if intersection:
				target_position = intersection
		
		if target_position:
			var mesh_node = _encontrar_nodo_con_malla(ObjectSelector.vista_previa)
			if mesh_node:
				var aabb = mesh_node.get_aabb()
				var offset_y = aabb.size.y * ObjectSelector.vista_previa.scale.y / 2.0
				ObjectSelector.vista_previa.translation = Vector3(target_position.x, target_position.y + offset_y, target_position.z)
			else:
				ObjectSelector.vista_previa.translation = target_position
		
		if hay_colision_con_pared(ObjectSelector.vista_previa):
			set_vista_previa_color(Color(1,0,0,0.5)) # Rojo si hay colisión
		else:
			set_vista_previa_color(Color(1,1,1,0.5)) # Blanco si no hay colisión


func colocar_objeto_en_suelo(ruta: String, punto: Vector3):
	if ruta == "" or not ResourceLoader.exists(ruta):
		push_error("❌ Ruta inválida: " + ruta)
		return

	var obj = load(ruta).instance()
	obj.set_meta("ruta_original", ruta)
	objects_container.add_child(obj)
	obj.add_to_group("colocados")
	
	var mesh_node = _encontrar_nodo_con_malla(obj)
	if mesh_node:
		var aabb = mesh_node.get_aabb()
		var offset_y = aabb.size.y * obj.scale.y / 2.0
		obj.translation = Vector3(punto.x, punto.y + offset_y, punto.z)
	else:
		obj.translation = punto
	
	if ObjectSelector.vista_previa:
		obj.rotation = ObjectSelector.vista_previa.rotation

func crear_vista_previa(ruta: String) -> Node:
	if not ResourceLoader.exists(ruta):
		push_error("❌ Recurso no encontrado: " + ruta)
		return null

	var obj = load(ruta).instance()
	obj.visible = true
	
	_apply_modifications_recursively(obj)
			
	add_child(obj)
	return obj

# --- FUNCIONES AUXILIARES Y DE SELECCIÓN ---

func select_object(object):
	if selected_object:
		deselect_object()

	selected_object = object
	delete_object_button.visible = true
	_set_object_color(selected_object, Color(1, 0.5, 0.5)) # Highlight in light red

func deselect_object():
	if not selected_object:
		return
		
	_restore_object_color(selected_object)
	
	selected_object = null
	original_materials.clear()
	delete_object_button.visible = false

func _set_object_color(node, color):
	if node is MeshInstance:
		if not original_materials.has(node):
			original_materials[node] = []
			for i in range(node.get_surface_material_count()):
				original_materials[node].append(node.get_surface_material(i))

		for i in range(node.get_surface_material_count()):
			var mat = node.get_surface_material(i)
			if mat and mat is SpatialMaterial:
				var new_mat = mat.duplicate()
				new_mat.albedo_color = color
				node.set_surface_material(i, new_mat)

	for child in node.get_children():
		_set_object_color(child, color)

func _restore_object_color(node):
	if node is MeshInstance:
		if original_materials.has(node):
			var materials = original_materials[node]
			for i in range(node.get_surface_material_count()):
				if i < materials.size():
					node.set_surface_material(i, materials[i])
			original_materials.erase(node)

	for child in node.get_children():
		_restore_object_color(child)

func hay_colision_con_pared(objeto: Node) -> bool:
	var space_state = get_world().direct_space_state
	var mesh_instance = _encontrar_nodo_con_malla(objeto)
	if not mesh_instance:
		return false

	var shape = BoxShape.new()
	shape.extents = mesh_instance.get_aabb().size / 2
	
	var params = PhysicsShapeQueryParameters.new()
	params.set_shape(shape)
	params.transform = mesh_instance.global_transform
	params.collide_with_bodies = true
	params.collide_with_areas = false
	
	var result = space_state.intersect_shape(params)
	for res in result:
		if res.collider.is_in_group("blocks"):
			return true
			
	return false

func set_vista_previa_color(color: Color):
	if ObjectSelector.vista_previa:
		var mesh_instance = _encontrar_nodo_con_malla(ObjectSelector.vista_previa)
		if mesh_instance:
			for i in range(mesh_instance.get_surface_material_count()):
				var mat = mesh_instance.get_surface_material(i)
				if mat and mat is SpatialMaterial:
					var new_mat = mat.duplicate()
					new_mat.flags_transparent = true
					new_mat.albedo_color = color
					mesh_instance.set_surface_material(i, new_mat)

func _encontrar_nodo_con_malla(nodo: Node):
	if nodo is MeshInstance:
		return nodo
	for hijo in nodo.get_children():
		var encontrado = _encontrar_nodo_con_malla(hijo)
		if encontrado:
			return encontrado
	return null

func _apply_modifications_recursively(node: Node):
	if node is MeshInstance:
		for i in range(node.get_surface_material_count()):
			var mat = node.get_surface_material(i)
			if mat and mat is SpatialMaterial:
				var new_mat = mat.duplicate()
				new_mat.flags_transparent = true
				new_mat.albedo_color.a = 0.5
				node.set_surface_material(i, new_mat)

	if node is CollisionShape:
		node.set_deferred("disabled", true)

	for child in node.get_children():
		_apply_modifications_recursively(child)

# FIX: Obtener los StaticBody de los bloques para excluirlos del raycast
func _get_all_block_bodies() -> Array:
	var bodies = []
	for block in blocks_container.get_children():
		if block.has_node("StaticBody"):
			bodies.append(block.get_node("StaticBody"))
	return bodies



func _on_derecha_button_up():
	Input.action_release("ui_right")
	
func _on_derecha_button_down():
	Input.action_press("ui_right")

func _on_izquierda_button_up():
	Input.action_release("ui_left")
	
func _on_izquierda_button_down():
	Input.action_press("ui_left")

func _on_delante_button_up():
	Input.action_release("ui_up")
	
func _on_delante_button_down():
	Input.action_press("ui_up")

func _on_atras_button_up():
	Input.action_release("ui_down")
	
func _on_atras_button_down():
	Input.action_press("ui_down")
