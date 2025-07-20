extends Control # O Node2D, dependiendo de tu nodo raíz

# Referencia al AnimationPlayer. (Sigue siendo necesario para reproducir el fade visual)
onready var animation_player = $CanvasLayer/AnimationPlayer

# Referencia al ColorRect.
#onready var fade_rect = $CanvasLayer/TextureRect

# REFERENCIA AL TIMER (¡Asegúrate de que la ruta sea correcta a tu nodo Timer!)
# Si tu Timer es hijo directo del nodo raíz, sería "$Timer"
# Si es hijo del CanvasLayer, sería "$CanvasLayer/Timer"
#onready var change_scene_timer = $CanvasLayer/Timer # <-- Ajusta esta ruta si tu Timer está en otro lugar

func _ready():
	
	# Reproduce la animación de fade in.
	# Esta se ejecutará visualmente, pero no controlará el cambio de escena.
	animation_player.play("fadein")

	# Inicia el Timer para controlar el tiempo total de la splash screen.
	#change_scene_timer.start() # <-- EL TIMER SE INICIA AQUÍ, AL PRINCIPIO.
	#print("Animación 'fade_in' iniciada y Timer de cambio de escena iniciado.")



func _on_Timer_timeout():
	print("Hola soy el timer del login")
	#get_tree().change_scene("res://Control.tscn") # ¡CAMBIA ESTA RUTA SI ES DIFERENTE!


