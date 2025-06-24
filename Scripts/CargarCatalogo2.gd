extends GridContainer

# Ruta a la carpeta que contiene tus modelos GLB
export var models_folder_path: String = "res://Assets/assets3D/"
# Tamaño mínimo deseado para los botones
export var button_min_size: Vector2 = Vector2(128, 64) # Ancho, Alto

func _ready():
	# Asegurarse de que la ruta de la carpeta termina con una barra
	if not models_folder_path.ends_with("/"):
		models_folder_path += "/"

	# Limpiar el GridContainer por si hay elementos previos
	for child in get_children():
		child.queue_free()

	load_model_buttons()


func load_model_buttons():
	var dir = Directory.new() # Objeto para interactuar con directorios
	if dir.open(models_folder_path) == OK: # Intentar abrir la carpeta
		dir.list_dir_begin() # Iniciar el listado de archivos
		var file_name = dir.get_next() # Obtener el primer nombre de archivo

		while file_name != "": # Iterar mientras haya archivos
			# Ignorar directorios y archivos ocultos/meta (como .import)
			if not dir.current_is_dir() and not file_name.begins_with("."):
				var file_extension = file_name.get_extension().to_lower()
				# Filtra solo por la extensión GLB
				if file_extension == "glb": # Si quieres otros formatos, añádelos aquí: "glb", "gltf", "dae"
					var model_path = models_folder_path + file_name
					_create_model_button(model_path)
				# else:
					# print("Archivo no GLB en la carpeta de modelos: ", file_name)

			file_name = dir.get_next() # Moverse al siguiente archivo
		dir.list_dir_end() # Finalizar el listado
	else:
		print("Error: No se pudo abrir el directorio de modelos 3D: ", models_folder_path)


# Función para crear y añadir el boton (ignoralo por favor , es casi como una plantilla , la funcion del boton se declara más abajo)
func _create_model_button(model_path: String):
	var model_button = Button.new()
	# Obtiene solo el nombre del archivo (ej. "mesa_cafe.glb" -> "mesa_cafe")
	model_button.text = model_path.get_file().get_basename()
	model_button.rect_min_size = button_min_size # Establece el tamaño mínimo del botón
	model_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Para que llene el espacio disponible en la celda
	model_button.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Estilo Normal
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.8, 0.8, 0.8, 0.7) # Un gris claro semi-transparente
	style_normal.set_border_width_all(1)
	style_normal.set_border_color(Color(0.6, 0.6, 0.6, 0.8))
	style_normal.set_corner_radius_all(int(button_min_size.y / 2)) # Redondea las esquinas a la mitad de la altura
	style_normal.set_shadow_color(Color(0, 0, 0, 0.3)) # Sombra oscura
	style_normal.set_shadow_offset(Vector2(2, 2)) # Desplazamiento de la sombra
	style_normal.set_shadow_size(4) # Suavidad de la sombra
	

	# Estilo Hover (cuando el mouse está encima)
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.9, 0.9, 0.9, 0.8) # Un poco más claro
	style_hover.set_border_width_all(1)
	style_hover.set_border_color(Color(0.7, 0.7, 0.7, 0.9))
	style_hover.set_corner_radius_all(int(button_min_size.y / 2))
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
	model_button.add_stylebox_override("normal", style_normal)
	model_button.add_stylebox_override("hover", style_hover)
	model_button.add_stylebox_override("pressed", style_pressed)

	# Opcional: Ajustar el color del texto para que contraste
	model_button.add_color_override("font_color", Color(0.1, 0.1, 0.1)) # Gris muy oscuro
	model_button.add_color_override("font_color_hover", Color(0, 0, 0)) # Negro al pasar el mouse
	model_button.add_color_override("font_color_pressed", Color(0.2, 0.2, 0.2)) # Gris un poco más claro al presionar

	# Si quieres que el botón haga algo al clickearlo, puedes conectar una señal aquí:
	model_button.connect("pressed", self, "_on_model_button_clicked", [model_path])

	# Añadir el botón al GridContainer
	add_child(model_button)

#    _             _                  
#   /_\  __ _ _  _(_)  ___ ___        
#  / _ \/ _` | || | | / -_|_-<        
# /_/ \_\__, |\_,_|_| \___/__/        
#  __| |___|_|_  __| |___             
# / _` / _ \ ' \/ _` / -_)            
# \__,_\___/_||_\__,_\___|            
# __ ____ _ _ _    __ _               
# \ V / _` | ' \  / _` |              
#  \_/\__,_|_||_| \__,_|       _      
#  __ ___| |___  __ __ _ _ _  | |__ _ 
# / _/ _ \ / _ \/ _/ _` | '_| | / _` |
# \__\___/_\___/\__\__,_|_|   |_\__,_|
#  / _|_  _ _ _  __(_)/_/ _ _         
# |  _| || | ' \/ _| / _ \ ' \        
# |_|_ \_,_|_||_\__|_\___/_||_|       
# | _ ) ___| |_ ___ _ _               
# | _ \/ _ \  _/ _ \ ' \              
# |___/\___/\__\___/_||_|   

func _on_model_button_clicked(model_path: String):
	print("El botón ", model_path.get_file().get_basename(), " para el modelo ", model_path, " ha sido clickeado.")
#    # Aquí podrías instanciar el modelo 3D o hacer otra cosa.
