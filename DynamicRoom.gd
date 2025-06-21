extends Spatial  # En Godot 3, usamos Spatial en lugar de Node3D

# Precarga de texturas
onready var _wall_texture = preload("res://materials/pared_blanca.jpg")
onready var _floor_texture = preload("res://materials/suelo_granito.jpg")
var objeto_escena = preload("res://objetos/cama/source/cama.tscn")

func _ready():
	self.translation = Vector3.ZERO  # En Godot 3, usamos `translation`
	build_room()
	_setup_camera()
	

func _setup_camera():
	var camera_orbit = get_parent().get_node("CamaraOrbit")  
	if camera_orbit:
		var room_size = max(MedidasSingleton.anchura, MedidasSingleton.profundidad)
		camera_orbit.init_orbit(room_size)

func build_room():
	var wall_material = SpatialMaterial.new()
	wall_material.albedo_texture = _wall_texture

	var floor_material = SpatialMaterial.new()
	floor_material.albedo_texture = _floor_texture

	# Limpiar habitación existente excepto Container
	for child in get_children():
		if child.name != "Container":
			child.queue_free()

	# Asegurar existencia del Container
	var container = get_node_or_null("Container")
	if not container:
		container = Spatial.new()
		container.name = "Container"
		add_child(container)

	var width = MedidasSingleton.anchura
	var height = MedidasSingleton.altura
	var depth = MedidasSingleton.profundidad

	# Crear piso con colisión
	var floor_mesh = MeshInstance.new()
	var floor_box = CubeMesh.new()
	floor_box.size = Vector3(width, 0.1, depth)
	floor_mesh.mesh = floor_box
	floor_mesh.translation.y = -0.05
	floor_mesh.material_override = floor_material
	floor_mesh.name = "Floor"
	floor_mesh.add_to_group("suelo")  # Grupo para detección selectiva

	var static_body = StaticBody.new()
	static_body.add_to_group("suelo")
	var collision = CollisionShape.new()
	collision.shape = BoxShape.new()
	collision.shape.extents = floor_box.size * 0.5
	static_body.add_child(collision)
	floor_mesh.add_child(static_body)

	add_child(floor_mesh)

	# Crear paredes
	_create_wall(Vector3(0, height / 2, -depth / 2), Vector3(width, height, 0.1), 0, wall_material)
	_create_wall(Vector3(0, height / 2, depth / 2), Vector3(width, height, 0.1), 180, wall_material)
	_create_wall(Vector3(-width / 2, height / 2, 0), Vector3(depth, height, 0.1), 90, wall_material)
	_create_wall(Vector3(width / 2, height / 2, 0), Vector3(depth, height, 0.1), -90, wall_material)


func _create_wall(wall_position: Vector3, size: Vector3, rotation_y: float, material: SpatialMaterial):
	var wall = MeshInstance.new()
	var box = CubeMesh.new()
	box.size = size  # Cambio `extents` → `size`
	wall.mesh = box
	wall.material_override = material
	wall.translation = wall_position
	wall.rotation.y = deg2rad(rotation_y) 
	wall.name = "Wall_%s" % str(wall_position)
	
	# Añadir colisión
	var static_body = StaticBody.new()
	var collision = CollisionShape.new()
	collision.shape = BoxShape.new()
	collision.shape.extents = size * 0.5   # Cambio `extents` → `size`
	static_body.add_child(collision)
	wall.add_child(static_body)
	
	add_child(wall)
	print("Pared creada:", wall.name, "en", wall_position, "tamaño", size)
	print("Valores en DynamicRoom:", MedidasSingleton.altura, MedidasSingleton.anchura, MedidasSingleton.profundidad)
	

#func agregar_objeto(posicion: Vector3):
#	var objeto = objeto_escena.instance()
#	var contenedor = get_node("Container")
#	contenedor.add_child(objeto)
#	objeto.translation = Vector3(0, 0.01, 0)
#	objeto.scale = Vector3(0.1, 0.1, 0.1) 

func _input(event):
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		if ObjectSelector.vista_previa:
			var mouse_pos = get_viewport().get_mouse_position()
			var camera = get_viewport().get_camera()
			var desde = camera.project_ray_origin(mouse_pos)
			var hacia = desde + camera.project_ray_normal(mouse_pos) * 1000
			var result = get_world().direct_space_state.intersect_ray(desde, hacia, [], 1)

			if result and result.collider.is_in_group("suelo"):
				colocar_objeto_en_suelo(ObjectSelector.objeto_seleccionado, result.position)
				ObjectSelector.vista_previa.queue_free()
				ObjectSelector.vista_previa = null




func colocar_objeto_desde_input(screen_pos):
	var camera = get_viewport().get_camera()
	var desde = camera.project_ray_origin(screen_pos)
	var hacia = desde + camera.project_ray_normal(screen_pos) * 1000

	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(desde, hacia)
	if result and result.collider.is_in_group("suelo"):
		colocar_objeto_en_suelo(ObjectSelector.objeto_seleccionado, result.position)
	else:
		print("Ignorando clic: no se detectó el suelo")




func encontrar_nodo_con_malla(nodo: Node) -> MeshInstance:
	for hijo in nodo.get_children():
		if hijo is MeshInstance:
			return hijo
		var encontrado = encontrar_nodo_con_malla(hijo)
		if encontrado:
			return encontrado
	return null
	
func colocar_objeto(ruta_escena: String, punto: Vector3):
	if ruta_escena == "" or not ResourceLoader.exists(ruta_escena):
		push_error("❌ Ruta inválida: " + ruta_escena)
		return

	var obj = load(ruta_escena).instance()
	var contenedor = $Container
	contenedor.add_child(obj)

	# Escala adaptativa básica
	var factor = clamp(MedidasSingleton.anchura / 20.0, 0.2, 1.0)
	obj.scale = Vector3.ONE * factor

	# Ajuste de altura según su malla escalada
	var mesh = encontrar_nodo_con_malla(obj)
	if mesh:
		var aabb = mesh.get_aabb()
		var altura_escalada = aabb.size.y * obj.scale.y
		obj.translation = punto + Vector3(0, altura_escalada / 2.0, 0)
	else:
		obj.translation = punto

func crear_vista_previa(ruta: String) -> Node:
	if not ResourceLoader.exists(ruta):
		push_error("❌ Recurso no encontrado: " + ruta)
		return null

	var obj = load(ruta).instance()
	obj.visible = true
	obj.set_physics_process(false)

	var mesh_node = encontrar_nodo_con_malla(obj)
	if mesh_node:
		var factor_escala = calcular_escala_normalizada(mesh_node, 0.2)
		obj.scale = Vector3.ONE * factor_escala
		aplicar_transparencia(obj)

	desactivar_colisiones(obj)
	$Container.add_child(obj)
	return obj

func colocar_objeto_en_suelo(ruta_escena: String, punto: Vector3):
	if ruta_escena == "" or not ResourceLoader.exists(ruta_escena):
		push_error("❌ Ruta inválida: " + ruta_escena)
		return

	# Verificar si ya hay un objeto justo ahí
	if hay_objeto_exactamente_abajo(punto):
		print("⛔ Ya hay un objeto en esta posición")
		return

	var obj = load(ruta_escena).instance()
	$Container.add_child(obj)
	obj.add_to_group("colocados")

	var mesh_node = encontrar_nodo_con_malla(obj)
	if mesh_node:
		var factor_escala = calcular_escala_normalizada(mesh_node, 0.4)
		obj.scale = Vector3.ONE * factor_escala

		var aabb = mesh_node.get_aabb()
		var offset_base = aabb.position.y * obj.scale.y
		var y_final = punto.y - offset_base
		obj.translation = Vector3(punto.x, y_final, punto.z)
	else:
		obj.translation = punto  # fallback si no encuentra malla

func aplicar_transparencia(nodo):
	if nodo is MeshInstance:
		for i in range(nodo.get_surface_material_count()):
			var mat = nodo.get_surface_material(i)
			if mat and mat is SpatialMaterial:
				var new_mat = mat.duplicate()
				new_mat.flags_transparent = true
				new_mat.albedo_color.a = 0.3
				nodo.set_surface_material(i, new_mat)
	for hijo in nodo.get_children():
		aplicar_transparencia(hijo)



func desactivar_colisiones(nodo):
	for hijo in nodo.get_children():
		if hijo is CollisionShape:
			hijo.disabled = true
		else:
			desactivar_colisiones(hijo)



func _process(delta):
	if ObjectSelector.objeto_seleccionado != "" and not ObjectSelector.vista_previa:
		ObjectSelector.vista_previa = crear_vista_previa(ObjectSelector.objeto_seleccionado)

	if ObjectSelector.vista_previa:
		var mouse_pos = get_viewport().get_mouse_position()
		var camera = get_viewport().get_camera()
		var desde = camera.project_ray_origin(mouse_pos)
		var hacia = desde + camera.project_ray_normal(mouse_pos) * 1000

		var result = get_world().direct_space_state.intersect_ray(desde, hacia, [], 1)

		if result and result.collider.is_in_group("suelo"):
			var obj = ObjectSelector.vista_previa
			var mesh = encontrar_nodo_con_malla(obj)
			if mesh:
				var aabb = mesh.get_aabb()
				var offset = aabb.position.y * obj.scale.y
				var altura = aabb.size.y * obj.scale.y
				var y_final = result.position.y - offset + altura / 2.0
				obj.translation = Vector3(result.position.x, y_final, result.position.z)

func calcular_escala_normalizada(mesh_node: MeshInstance, porcentaje_ocupable := 0.2) -> float:
	var aabb = mesh_node.get_aabb()
	var max_dim = max(aabb.size.x, aabb.size.z)
	var max_ocupable = MedidasSingleton.anchura * porcentaje_ocupable
	return clamp(max_ocupable / max_dim, 0.05, 1.0)

func hay_objeto_exactamente_abajo(punto: Vector3) -> bool:
	var arriba = punto + Vector3(0, 2.0, 0)
	var abajo = punto - Vector3(0, 0.1, 0)
	var exclude = []
	if ObjectSelector.vista_previa:
		exclude.append(ObjectSelector.vista_previa)

	var result = get_world().direct_space_state.intersect_ray(arriba, abajo, exclude, 1)
	return result and result.collider.is_in_group("colocados")
