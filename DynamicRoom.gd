extends Spatial

onready var _wall_texture = preload("res://materials/pared_blanca.jpg")
onready var _floor_texture = preload("res://materials/suelo_granito.jpg")

onready var camera_orbit: Node = $"../CamaraOrbit" # Asegúrate de que esta ruta sea correcta


func _ready():
	self.translation = Vector3.ZERO
	build_room()
	_setup_camera()
	
	# Cargar proyecto si hay uno seleccionado
	if MedidasSingleton.proyecto_actual != "":
		SistemaGuardado.cargar_proyecto(MedidasSingleton.proyecto_actual, self)
		MedidasSingleton.proyecto_actual = ""  # Resetear después de cargar

func _setup_camera():
	if camera_orbit:
		var room_size = max(MedidasSingleton.anchura, MedidasSingleton.profundidad)
		camera_orbit.init_orbit(room_size)

func build_room():
	var wall_material = SpatialMaterial.new()
	wall_material.albedo_texture = _wall_texture

	var floor_material = SpatialMaterial.new()
	floor_material.albedo_texture = _floor_texture

	for child in get_children():
		if child.name != "Container":
			child.queue_free()

	var container = get_node_or_null("Container")
	if not container:
		container = Spatial.new()
		container.name = "Container"
		add_child(container)

	var width = MedidasSingleton.anchura
	var height = MedidasSingleton.altura
	var depth = MedidasSingleton.profundidad

	var floor_mesh = MeshInstance.new()
	var floor_box = CubeMesh.new()
	floor_box.size = Vector3(width, 0.1, depth)
	floor_mesh.mesh = floor_box
	floor_mesh.translation.y = -0.05
	floor_mesh.material_override = floor_material
	floor_mesh.name = "Floor"
	floor_mesh.add_to_group("suelo")

	var static_body = StaticBody.new()
	static_body.add_to_group("suelo")
	var collision = CollisionShape.new()
	collision.shape = BoxShape.new()
	collision.shape.extents = floor_box.size * 0.5
	static_body.add_child(collision)
	floor_mesh.add_child(static_body)

	add_child(floor_mesh)

	_create_wall(Vector3(0, height / 2, -depth / 2), Vector3(width, height, 0.1), 0, wall_material)
	_create_wall(Vector3(0, height / 2, depth / 2), Vector3(width, height, 0.1), 180, wall_material)
	_create_wall(Vector3(-width / 2, height / 2, 0), Vector3(depth, height, 0.1), 90, wall_material)
	_create_wall(Vector3(width / 2, height / 2, 0), Vector3(depth, height, 0.1), -90, wall_material)

func _create_wall(pos: Vector3, size: Vector3, rot_y: float, material: SpatialMaterial):
	var wall = MeshInstance.new()
	var box = CubeMesh.new()
	box.size = size
	wall.mesh = box
	wall.material_override = material
	wall.translation = pos
	wall.rotation.y = deg2rad(rot_y)
	wall.name = "Wall_%s" % str(pos)

	var static_body = StaticBody.new()
	var collision = CollisionShape.new()
	collision.shape = BoxShape.new()
	collision.shape.extents = size * 0.5
	static_body.add_child(collision)
	wall.add_child(static_body)
	wall.add_to_group("paredes")
	static_body.add_to_group("paredes")

	add_child(wall)

# En el script de tu Room/SceneRoot:


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

func colocar_objeto_en_suelo(ruta: String, punto: Vector3):
	if ruta == "" or not ResourceLoader.exists(ruta):
		push_error("❌ Ruta inválida: " + ruta)
		return

	var obj = load(ruta).instance()
	obj.set_meta("ruta_original", ruta)
	$Container.add_child(obj)
	obj.add_to_group("colocados")

	var mesh_node = encontrar_nodo_con_malla(obj)
	if mesh_node:
		var escala = calcular_escala_normalizada(mesh_node, 0.4)
		# ⬅ Aquí colocas la impresión para depurar el asset
		print("🔍 Asset:", obj.name)
		print("📦 AABB Position:", mesh_node.get_aabb().position)
		print("📏 AABB Size:", mesh_node.get_aabb().size)
		print("📍 Global Translation:", mesh_node.global_transform.origin)
		obj.scale = Vector3.ONE * escala

		var aabb = mesh_node.get_aabb()
		var offset = aabb.position.y * obj.scale.y
		var y_final = punto.y - offset
		obj.translation = Vector3(punto.x, y_final, punto.z)
		if ObjectSelector.vista_previa:
		 obj.rotation = ObjectSelector.vista_previa.rotation

		# 🚫 Validación volumétrica real
		if hay_colision_volumetrica(obj):
			print("⛔ No se puede colocar, colisión volumétrica detectada")
			obj.queue_free()
			return
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
		var escala = calcular_escala_normalizada(mesh_node, 0.2)
		obj.scale = Vector3.ONE 
		aplicar_transparencia(obj)

	desactivar_colisiones(obj)
	$Container.add_child(obj)
	return obj

func encontrar_nodo_con_malla(nodo: Node) -> MeshInstance:
	for hijo in nodo.get_children():
		if hijo is MeshInstance:
			return hijo
		var encontrado = encontrar_nodo_con_malla(hijo)
		if encontrado:
			return encontrado
	return null

func calcular_escala_normalizada(mesh: MeshInstance, porcentaje: float = 0.2) -> float:
	var aabb = mesh.get_aabb()
	var max_dim = max(aabb.size.x, aabb.size.z)
	var max_ocupable = MedidasSingleton.anchura * porcentaje
	return clamp(max_ocupable / max_dim, 0.05, 1.0)

func desactivar_colisiones(nodo):
	for hijo in nodo.get_children():
		if hijo is CollisionShape:
			hijo.disabled = true
		else:
			desactivar_colisiones(hijo)

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

func detectar_objeto_colocado_en(punto: Vector3) -> bool:
	var desde = punto + Vector3(0, 1.5, 0)
	var hasta = punto - Vector3(0, 0.1, 0)
	var exclude = []
	if ObjectSelector.vista_previa:
		exclude.append(ObjectSelector.vista_previa)
	var result = get_world().direct_space_state.intersect_ray(desde, hasta, exclude)
	if result:
		var nodo = result.collider
		while nodo:
			if nodo.is_in_group("colocados"):
				return true
			nodo = nodo.get_parent()
	return false

func _process(delta):
	# 🧩 Mostrar u ocultar botones táctiles de rotación
	var botonera := get_node_or_null("UIConstruction/BotoneraRotacion")
	if botonera:
		botonera.visible = ObjectSelector.vista_previa != null
	else:
		print("⚠️ BotoneraRotacion no encontrada bajo UIConstruction")

	# 🧪 Generar vista previa si hay objeto seleccionado
	if ObjectSelector.objeto_seleccionado != "" and not ObjectSelector.vista_previa:
		ObjectSelector.vista_previa = crear_vista_previa(ObjectSelector.objeto_seleccionado)

	if ObjectSelector.vista_previa:
		var obj = ObjectSelector.vista_previa

		# 🎮 Rotación por teclado
		if Input.is_action_just_pressed("rotar_izquierda"):
			obj.rotate_y(deg2rad(-15))
		elif Input.is_action_just_pressed("rotar_derecha"):
			obj.rotate_y(deg2rad(15))

		# 🖱️ Movimiento con el mouse
		var mouse_pos = get_viewport().get_mouse_position()
		var camera = get_viewport().get_camera()
		var desde = camera.project_ray_origin(mouse_pos)
		var hacia = desde + camera.project_ray_normal(mouse_pos) * 1000

		var excluidos = []
		for nodo in get_tree().get_nodes_in_group("colocados"):
			if nodo.has_method("get_rid"):
				excluidos.append(nodo.get_rid())

		var result = get_world().direct_space_state.intersect_ray(desde, hacia, excluidos, 1)
		var destino : Vector3

		if result and result.collider and result.collider.is_in_group("suelo") and tap_libre_para_preview():
		 destino = result.position

		else:
			var altura_suelo := 0.0
			var t : float = (altura_suelo - desde.y) / (hacia.y - desde.y)
			destino = desde.linear_interpolate(hacia, t)

		var mesh = encontrar_nodo_con_malla(obj)
		if mesh:
			var aabb = mesh.get_aabb()
			var altura = aabb.size.y * obj.scale.y
			var y_final = destino.y + altura / 2.0

			var ancho := float(MedidasSingleton.anchura) * 0.5
			var largo := float(MedidasSingleton.profundidad) * 0.5
			var margen := 0.15

			var limite_x := clamp(destino.x, -ancho + margen, ancho - margen)
			var limite_z := clamp(destino.z, -largo + margen, largo - margen)

			var objetivo = Vector3(limite_x, y_final, limite_z)
			obj.translation = obj.translation.linear_interpolate(objetivo, 0.10)

# 🔍 Recolectar todos los RIDs del objeto y sus hijos
func recolectar_rids(nodo: Node) -> Array:
		var rids = []
		if nodo.has_method("get_rid"):
			rids.append(nodo.get_rid())
		for hijo in nodo.get_children():
			rids += recolectar_rids(hijo)
		return rids
		
func hay_colision_volumetrica(objeto: Node) -> bool:
	var space = get_world().direct_space_state

	

	var excludes = recolectar_rids(objeto)

	for shape_node in objeto.get_children():
		if shape_node is CollisionShape and shape_node.shape:
			var shape = shape_node.shape
			var transform = shape_node.global_transform

			var params = PhysicsShapeQueryParameters.new()

			if shape is ConcavePolygonShape:
				var mesh = encontrar_nodo_con_malla(objeto)
				if mesh:
					var aabb = mesh.get_aabb()
					var box_shape = BoxShape.new()
					box_shape.set_extents(aabb.size * 0.5 * objeto.scale)

					var offset = aabb.position * objeto.scale
					var box_transform = Transform(transform.basis, transform.origin + offset)

					params.set_shape(box_shape)
					params.set_transform(box_transform)
				else:
					continue
			else:
				params.set_shape(shape)
				params.set_transform(transform)

			params.set_collide_with_bodies(true)
			params.set_exclude(excludes)

			var result = space.intersect_shape(params, 10)
			for res in result:
				var col = res.collider
				if col and not col.is_in_group("suelo"):
					return true

		elif shape_node.get_child_count() > 0:
			if hay_colision_volumetrica(shape_node):
				return true

	return false
	
func tap_libre_para_preview() -> bool:
	var mouse_pos = get_viewport().get_mouse_position()

	var controles := [
	get_node_or_null("UIConstruction/BotoneraRotacion"),
	get_node_or_null("UIConstruction/trancarCamara"),
	get_node_or_null("UIConstruction/BotonCatalogo"),
	get_node_or_null("UIConstruction/vistaAerea"),
	# Puedes añadir más nodos si los tienes
	]

	for control in controles:
		if control and control.get_global_rect().has_point(mouse_pos):
			return false

	return true

	



