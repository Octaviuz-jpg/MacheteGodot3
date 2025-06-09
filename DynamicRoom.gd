extends Spatial  # En Godot 3, usamos Spatial en lugar de Node3D

# Precarga de texturas
onready var _wall_texture = preload("res://materials/pared_blanca.jpg")
onready var _floor_texture = preload("res://materials/suelo_granito.jpg")

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
	# Crear materiales con las texturas
	var wall_material = SpatialMaterial.new()
	wall_material.albedo_texture = _wall_texture
	
	var floor_material = SpatialMaterial.new()
	floor_material.albedo_texture = _floor_texture
	
	# Limpiar habitación existente
	for child in get_children():
		if child != self:
			child.queue_free()
	
	# Obtener medidas
	var width = MedidasSingleton.anchura
	var height = MedidasSingleton.altura
	var depth = MedidasSingleton.profundidad
	
	
	# Crear piso con CubeMesh
	var floor_mesh = MeshInstance.new()
	var floor_box = CubeMesh.new()
	floor_box.size = Vector3(width, 0.1, depth)  # Cambio `extents` → `size`
	floor_mesh.mesh = floor_box
	floor_mesh.translation.y = -0.05  
	floor_mesh.material_override = floor_material
	floor_mesh.name = "Floor"
	add_child(floor_mesh)
	
	# Crear paredes
	_create_wall(Vector3(0, height/2, -depth/2), Vector3(width, height, 0.1), 0, wall_material)
	_create_wall(Vector3(0, height/2, depth/2), Vector3(width, height, 0.1), 180, wall_material)
	_create_wall(Vector3(-width/2, height/2, 0), Vector3(depth, height, 0.1), 90, wall_material)
	_create_wall(Vector3(width/2, height/2, 0), Vector3(depth, height, 0.1), -90, wall_material)

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
	
