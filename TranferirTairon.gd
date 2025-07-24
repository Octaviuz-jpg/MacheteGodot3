extends Spatial

# Contenedor para las instancias de los bloques
onready var blocks_container: Spatial = $BlocksContainer
onready var back_button: Button = $CanvasLayer/BackButton

# Precargamos la escena del bloque para poder instanciarla
const BlockScene = preload("res://Scenes/tairon/Scenes/Block.tscn")

func _ready():
	if not blocks_container:
		push_error("ERROR: No se encontró el nodo 'BlocksContainer' en TranferirTairon.tscn")
		return
		
	if not back_button:
		push_error("ERROR: No se encontró el botón 'BackButton' en TranferirTairon.tscn")
	else:
		back_button.connect("pressed", self, "_on_back_button_pressed")

	load_tairon_structure()

func load_tairon_structure():
	print("Iniciando carga de estructura Tairon en la escena de transferencia...")
	# Limpiar cualquier bloque anterior
	for child in blocks_container.get_children():
		child.queue_free()

	SupabaseManager.load_scene_state()
	var scene_data = yield(SupabaseManager, "scene_loaded")

	if scene_data and scene_data.has("blocks"):
		var bloques = scene_data.blocks
		print("Se encontraron %d bloques para construir." % bloques.size())
		for bloque_data in bloques:
			if "position" in bloque_data and "scale" in bloque_data:
				# Instanciar la escena del bloque original
				var block_instance = BlockScene.instance()

				# Aplicar posición
				var pos_dict = bloque_data.position
				block_instance.translation = Vector3(pos_dict.x, pos_dict.y, pos_dict.z)
				
				# Aplicar escala
				var scale_dict = bloque_data.scale
				block_instance.scale = Vector3(scale_dict.x, scale_dict.y, scale_dict.z)
				
				# Aplicar rotación (si existe en los datos)
				if "rotation" in bloque_data:
					var rot_dict = bloque_data.rotation
					block_instance.rotation_degrees = Vector3(rot_dict.x, rot_dict.y, rot_dict.z)

				# Añadir la instancia a la escena
				blocks_container.add_child(block_instance)
			else:
				print("Advertencia: Dato de bloque incompleto (sin posición o escala), omitiendo.")
		print("¡Estructura Tairon cargada exitosamente en la escena de transferencia!")
	else:
		print("Error al cargar la estructura Tairon o no se encontraron datos.")

func _on_back_button_pressed():
	get_tree().change_scene("res://Node3D.tscn")