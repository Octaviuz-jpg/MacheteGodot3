extends Node
class_name SistemaGuardado

const RUTA_GUARDADO = "res://proyectos_guardados/"
const EXTENSION = ".tres"

# Estructura para guardar los datos del proyecto
class DatosProyecto extends Resource:
	var nombre: String = ""
	var anchura: float = 0.0
	var altura: float = 0.0
	var profundidad: float = 0.0
	var objetos_colocados: Array = [] # Array de Diccionarios con datos de objetos

# Guardar un proyecto
static func guardar_proyecto(nombre_proyecto: String, room_node: Node) -> bool:
	# Validar nombre
	if nombre_proyecto.strip_edges().empty():
		push_error("El nombre del proyecto no puede estar vacío")
		return false
	
	# Crear directorio si no existe
	var dir = Directory.new()
	if not dir.dir_exists(RUTA_GUARDADO):
		dir.make_dir_recursive(RUTA_GUARDADO)
	
	# Crear datos del proyecto
	var datos = DatosProyecto.new()
	datos.nombre = nombre_proyecto
	datos.anchura = MedidasSingleton.anchura
	datos.altura = MedidasSingleton.altura
	datos.profundidad = MedidasSingleton.profundidad
	
	# Recolectar objetos colocados
	for objeto in room_node.get_tree().get_nodes_in_group("colocados"):
		var datos_objeto = {
			"ruta": objeto.filename if objeto.filename else objeto.get_meta("ruta_original", ""),
			"posicion": objeto.translation,
			"rotacion": objeto.rotation,
			"escala": objeto.scale,
			"propiedades": _obtener_propiedades_objeto(objeto)
		}
		datos.objetos_colocados.append(datos_objeto)
	
	# Guardar archivo
	var ruta_completa = RUTA_GUARDADO + nombre_proyecto + EXTENSION
	return ResourceSaver.save(ruta_completa, datos) == OK

# Cargar un proyecto
static func cargar_proyecto(nombre_proyecto: String, room_node: Node) -> bool:
	var ruta_completa = RUTA_GUARDADO + nombre_proyecto + EXTENSION
	
	if not ResourceLoader.exists(ruta_completa):
		push_error("El archivo no existe: " + ruta_completa)
		return false
	
	var datos = ResourceLoader.load(ruta_completa, "", true) as DatosProyecto
	if not datos:
		push_error("Error al cargar el proyecto")
		return false
	
	# Limpiar objetos existentes
	_limpiar_objetos_colocados(room_node)
	
	# Aplicar medidas
	MedidasSingleton.anchura = datos.anchura
	MedidasSingleton.altura = datos.altura
	MedidasSingleton.profundidad = datos.profundidad
	
	# Reconstruir habitación
	if room_node.has_method("build_room"):
		room_node.build_room()
	
	# Colocar objetos
	for datos_objeto in datos.objetos_colocados:
		if not ResourceLoader.exists(datos_objeto.ruta):
			push_warning("Objeto no encontrado: " + datos_objeto.ruta)
			continue
		
		var obj = load(datos_objeto.ruta).instance()
		room_node.get_node("Container").add_child(obj)
		obj.add_to_group("colocados")
		
		obj.translation = datos_objeto.posicion
		obj.rotation = datos_objeto.rotacion
		obj.scale = datos_objeto.escala
		
		_aplicar_propiedades_objeto(obj, datos_objeto.propiedades)
	
	return true

# Obtener lista de proyectos guardados
static func listar_proyectos() -> Array:
	var proyectos = []
	var dir = Directory.new()
	
	if dir.open(RUTA_GUARDADO) == OK:
		dir.list_dir_begin()
		var nombre_archivo = dir.get_next()
		while nombre_archivo != "":
			if not dir.current_is_dir() and nombre_archivo.ends_with(EXTENSION):
				proyectos.append(nombre_archivo.replace(EXTENSION, ""))
			nombre_archivo = dir.get_next()
	
	return proyectos

# Métodos auxiliares
static func _limpiar_objetos_colocados(room_node: Node):
	for objeto in room_node.get_tree().get_nodes_in_group("colocados"):
		objeto.queue_free()

static func _obtener_propiedades_objeto(objeto: Node) -> Dictionary:
	var propiedades = {}
	
	# Propiedades específicas para SofaBlanco
	if objeto.has_method("obtener_datos_guardado"):
		propiedades = objeto.obtener_datos_guardado()
	
	return propiedades

static func _aplicar_propiedades_objeto(objeto: Node, propiedades: Dictionary):
	if objeto.has_method("aplicar_datos_guardado"):
		objeto.aplicar_datos_guardado(propiedades)
