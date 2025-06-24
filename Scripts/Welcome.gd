extends Control # O Node2D, dependiendo de tu nodo raíz

# Referencia al AnimationPlayer. (Sigue siendo necesario para reproducir el fade visual)
onready var animation_player = $CanvasLayer/AnimationPlayer

# Referencia al ColorRect.
onready var fade_rect = $CanvasLayer/TextureRect

# REFERENCIA AL TIMER (¡Asegúrate de que la ruta sea correcta a tu nodo Timer!)
# Si tu Timer es hijo directo del nodo raíz, sería "$Timer"
# Si es hijo del CanvasLayer, sería "$CanvasLayer/Timer"
onready var change_scene_timer = $CanvasLayer/Timer # <-- Ajusta esta ruta si tu Timer está en otro lugar

func _ready():
	
	# Reproduce la animación de fade in.
	# Esta se ejecutará visualmente, pero no controlará el cambio de escena.
	animation_player.play("fadein")

	# Inicia el Timer para controlar el tiempo total de la splash screen.
	change_scene_timer.start() # <-- EL TIMER SE INICIA AQUÍ, AL PRINCIPIO.
	print("Animación 'fade_in' iniciada y Timer de cambio de escena iniciado.")



func _on_Timer_timeout():
	print("Timer de cambio de escena terminado. Cambiando a Login.tscn...")
	#get_tree().change_scene("res://Scenes/Login.tscn") # ¡CAMBIA ESTA RUTA SI ES DIFERENTE!
	var new_scene_path = "res://Scenes/Login.tscn"
	var new_scene_packed = load(new_scene_path)
	var new_scene_instance = new_scene_packed.instance()

	# 2. Obtener la escena actual (la que queremos liberar)
	var current_scene_node = get_tree().current_scene

	# 3. Eliminar la escena actual del árbol
	# Esto activará _exit_tree() en los nodos de la escena anterior
	current_scene_node.queue_free()

	# 4. Añadir la nueva escena al nodo raíz del árbol
	# get_tree().root es el Viewport global del juego.
	get_tree().root.add_child(new_scene_instance)

	# 5. Establecer la nueva escena como la escena principal del árbol
	get_tree().current_scene = new_scene_instance

	


