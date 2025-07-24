# ModelCatalog.gd
extends GridContainer

# Ruta a la carpeta que contiene tus escenas o PackedScenes (pueden ser .tscn o .res)
export var scenes_folder_path: String = "res://Assets/assets3D/" # ¡Ajusta esta ruta!
# Tamaño mínimo deseado para los botones
export var button_min_size: Vector2 = Vector2(200, 64) # Ancho, Alto - Se mantuvo el valor de HEAD (200) por ser más grande

onready var root_spatial_node: Spatial = $"../../../../.." # ¡Asegúrate de que esta ruta sea correcta para tu jerarquía!

func _ready():
	# Asegurarse de que la ruta de la carpeta termina con una barra
	print("----------Cargando modelos de la carpeta Assets3D en el catalogo-------------")
	if not scenes_folder_path.ends_with("/"):
		scenes_folder_path += "/"

	# Limpiar el GridContainer por si hay elementos previos
	for child in get_children():
		child.queue_free()

	load_scene_buttons()

func load_scene_buttons():
	var dir = Directory.new()
	if dir.open(scenes_folder_path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if not dir.current_is_dir() and not file_name.begins_with("."):
				var file_extension = file_name.get_extension().to_lower()
				# Filtra por extensiones de escenas Godot (.tscn) o recursos de escena (.res)
				if file_extension in ["tscn", "res"]:
					var scene_path = scenes_folder_path + file_name
					_create_scene_button(scene_path)
				# else:
					# print("Archivo no .tscn/.res en la carpeta de escenas: ", file_name)

			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Error: No se pudo abrir el directorio de escenas: ", scenes_folder_path)


# Función para crear y añadir un botón al GridContainer
func _create_scene_button(scene_path: String):
	var scene_button = Button.new()
	# Obtiene solo el nombre del archivo (ej. "mi_silla.tscn" -> "mi_silla")
	scene_button.text = scene_path.get_file().get_basename()
	scene_button.rect_min_size = button_min_size # Establece el tamaño mínimo del botón
	scene_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_button.size_flags_vertical = Control.SIZE_EXPAND_FILL

#--------------ICONO DEL BOTON----------------------
	# Define la ruta a tu archivo de icono (reemplaza "res://ruta/a/tu/icono.png")
	var icon_path = "res://icon.png" # Ruta de ejemplo - ¡REEMPLAZA ESTO!
	# Carga la textura del icono
	var button_icon: Texture = load(icon_path)
	# Si el icono se cargó correctamente, asígnalo al botón
	if button_icon:
		scene_button.icon = button_icon
		# Opcional: Ajustar la escala del icono si es necesario
		# scene_button.icon_scale = Vector2(0.5, 0.5) # Ejemplo: reducir a la mitad
		scene_button.align = Button.ALIGN_LEFT # Alinear texto a la derecha del icono (opcional)
		scene_button.clip_text = true # Recortar texto que se desborda (opcional)
	else:
		print("Advertencia: No se pudo cargar el icono para el botón:", icon_path)
#--------------ESTILOS DEL BOTON----------------------
	# Estilo Normal
	var style_normal = StyleBoxFlat.new()
	style_normal.set_border_width_all(1)
	style_normal.set_border_color(Color(1, 1, 1, 1))
	style_normal.bg_color = Color(50, 112, 114) # Color de fondo más claro (se mantuvo el de HEAD)
	# style_normal.set_corner_radius_all(int(button_min_size.y / 2)) # Esta línea estaba comentada en HEAD y presente en el otro branch

	style_normal.set_shadow_color(Color(0, 0, 0, 0.3)) # Sombra oscura
	style_normal.set_shadow_offset(Vector2(2, 2)) # Desplazamiento de la sombra
	style_normal.set_shadow_size(4) # Suavidad de la sombra


	# Estilo Hover (cuando el mouse está encima)
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.9, 0.9, 0.9, 0.8) # Un poco más claro
	style_hover.set_border_width_all(1)
	style_hover.set_border_color(Color(0.7, 0.7, 0.7, 0.9))
	# style_hover.set_corner_radius_all(int(button_min_size.y / 2)) # Esta línea estaba comentada en HEAD y presente en el otro branch

	style_hover.set_shadow_color(Color(0, 0, 0, 0.4))
	style_hover.set_shadow_offset(Vector2(3, 3)) # Sombra más pronunciada al pasar el mouse
	style_hover.set_shadow_size(6)

	# Estilo Pressed (cuando se hace clic)
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.6, 0.6, 0.6, 0.7) # Más oscuro
	style_pressed.set_border_width_all(1)
	style_pressed.set_border_color(Color(0.5, 0.5, 0.5, 0.8))
	style_pressed.set_corner_radius_all(int(button_min_size.y / 2))
	style_pressed.set_shadow_color(Color(0, 0, 0, 0.2)) # Sombra más tenue (como si se "hundiera")
	style_pressed.set_shadow_offset(Vector2(1, 1))
	style_pressed.set_shadow_size(2)

	# Asignar los estilos al botón
	scene_button.add_stylebox_override("normal", style_normal)
	scene_button.add_stylebox_override("hover", style_hover)
	scene_button.add_stylebox_override("pressed", style_pressed)

	# Opcional: Ajustar el color del texto para que contraste
	scene_button.add_color_override("font_color", Color(0, 0, 0)) # Se mantuvo el color de HEAD (negro)
	scene_button.add_color_override("font_color_hover", Color(0, 0, 0)) # Negro al pasar el mouse
	scene_button.add_color_override("font_color_pressed", Color(0.2, 0.2, 0.2)) # Gris un poco más claro al presionar

	# Conectar la señal 'pressed' del botón a una función.
	# Le pasamos la ruta completa de la escena como argumento.
	scene_button.connect("pressed", self, "_on_scene_button_clicked", [scene_path])

	# Añadir el botón al GridContainer
	add_child(scene_button)

#--------------FUNCION BOTON A ASIGNAR------------

func _on_scene_button_clicked(scene_path: String):
	print("El botón para la escena/recurso '", scene_path.get_file().get_basename(), "' ha sido clickeado, proseguimos a seguir la ruta = " , scene_path)
	#ObjectSelector.objeto_seleccionado = "res://objetos/sofa blanco tipo1/"+scene_path
	
	# Se combinaron ambas lógicas, priorizando la verificación del singleton de HEAD
	#if Engine.has_singleton("ObjectSelector"):
	ObjectSelector.objeto_seleccionado = scene_path
		# Si ObjectSelector.vista_previa es algo que debe limpiarse o actualizarse, hazlo aquí.
		#ObjectSelector.vista_previa = null
	#else:
		#print("Advertencia: Singleton 'ObjectSelector' no encontrado. No se pudo asignar objeto.")

	#var scene_name = scene_path.get_file().get_basename()
	#print("El botón para la escena/recurso '", scene_name, "' ha sido clickeado.")
	# Aquí podrías añadir la lógica para instanciar la escena 3D, por ejemplo:
	#_instance_scene_in_world(scene_path)


# Función para cargar e instanciar la escena 3D en el nodo raíz
func _instance_scene_in_world(path: String):
	# Primero, verifica que la referencia al nodo raíz sea válida
	if root_spatial_node == null:
		print("ERROR: El nodo raíz Spatial (root_spatial_node) no está asignado o no se encontró.")
		return

	# Carga la PackedScene del archivo especificado por la ruta
	var scene_resource = load(path)
	if scene_resource == null:
		print("Error al cargar la PackedScene desde: ", path)
		return

	var scene_instance: Spatial = null

	# Asegúrate de que el recurso cargado sea realmente una PackedScene
	if scene_resource is PackedScene:
		# Instancia la PackedScene para crear una copia del nodo y sus hijos
		scene_instance = scene_resource.instance() as Spatial # 'instance()' para Godot 3
	else:
		print("El recurso cargado (", path, ") no es una PackedScene. No se puede instanciar.")
		return # <-- Añadido para evitar errores si no es PackedScene

	if scene_instance:
		# Añade la instancia de la escena como hijo del nodo raíz Spatial
		root_spatial_node.add_child(scene_instance)

		# Puedes establecer una posición inicial para la escena instanciada
		# Ajusta estos valores (X, Y, Z) según la ubicación de tu cámara y el tamaño de tus escenas.
		scene_instance.translation = Vector3(0, 0, -5) # Ejemplo: 5 unidades delante del origen

		print("Escena 3D '", scene_instance.name if scene_instance.name else path.get_file().get_basename(), "' instanciada en el nodo raíz.")
	else:
		print("La instancia de la escena es nula después de instanciar: ", path)
