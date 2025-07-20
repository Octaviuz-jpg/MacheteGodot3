extends Control

onready var lista_proyectos = $CanvasLayer/ItemList
onready var boton_cargar = $CanvasLayer/Cargar
onready var boton_eliminar = $CanvasLayer/Eliminar
onready var boton_volver = $CanvasLayer/Volver

var sistema_guardado_script = load("res://SistemaGuardado.gd")

func _ready():
	# Conexiones seguras de señales
	if not boton_cargar.is_connected("pressed", self, "_on_Cargar_pressed"):
		boton_cargar.connect("pressed", self, "_on_Cargar_pressed")
	if not boton_eliminar.is_connected("pressed", self, "_on_Eliminar_pressed"):
		boton_eliminar.connect("pressed", self, "_on_Eliminar_pressed")
	if not boton_volver.is_connected("pressed", self, "_on_Volver_pressed"):
		boton_volver.connect("pressed", self, "_on_Volver_pressed")
	if not lista_proyectos.is_connected("item_selected", self, "_on_proyecto_seleccionado"):
		lista_proyectos.connect("item_selected", self, "_on_proyecto_seleccionado")
	
	boton_cargar.disabled = true
	boton_eliminar.disabled = true
	actualizar_lista()

func actualizar_lista():
	lista_proyectos.clear()
	var proyectos = sistema_guardado_script.listar_proyectos()
	for proyecto in proyectos:
		lista_proyectos.add_item(proyecto)

func _on_proyecto_seleccionado(_index: int):
	boton_cargar.disabled = false
	boton_eliminar.disabled = false

func _on_Cargar_pressed():
	var seleccionado = lista_proyectos.get_selected_items()
	if seleccionado.size() > 0:
		var nombre_proyecto = lista_proyectos.get_item_text(seleccionado[0])
		cargar_y_transicionar(nombre_proyecto)

func cargar_y_transicionar(nombre_proyecto: String):
	MedidasSingleton.proyecto_actual = nombre_proyecto
	
	if ResourceLoader.exists("res://DynamicRoom.tscn"):
		var scene = load("res://DynamicRoom.tscn")
		if scene:
			var instance = scene.instance()
			# Transición suave
			get_tree().current_scene.queue_free()
			get_tree().root.add_child(instance)
			get_tree().current_scene = instance
		else:
			print("Error cargando DynamicRoom.tscn")
			get_tree().change_scene("res://Scenes/Menu.tscn")  # Fallback
	else:
		print("DynamicRoom.tscn no encontrado")
		get_tree().change_scene("res://Scenes/Menu.tscn")  # Fallback

func _on_Eliminar_pressed():
	var seleccionado = lista_proyectos.get_selected_items()
	if seleccionado.size() > 0:
		var nombre_proyecto = lista_proyectos.get_item_text(seleccionado[0])
		var dir = Directory.new()
		if dir.remove(sistema_guardado_script.RUTA_GUARDADO + nombre_proyecto + sistema_guardado_script.EXTENSION) == OK:
			actualizar_lista()
			boton_cargar.disabled = true
			boton_eliminar.disabled = true

func _on_Volver_pressed():
	get_tree().change_scene("res://Scenes/Menu.tscn")
