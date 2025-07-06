extends Button

export (NodePath) var panel_path
onready var panel = get_node(panel_path) if panel_path else null

# Define las dos posiciones a las que el panel se alternará
# Posición 1 (ej. fuera de la pantalla a la derecha)
var position_1 = Vector2(725, 150) 
# Posición 2 (ej. dentro de la pantalla a la izquierda)
var position_2 = Vector2(475, 150) 

# Variable de estado para saber en qué posición está o a cuál se dirige
var _is_at_position_1 = true # Asumimos que inicialmente el panel está en position_1

func _ready():
	connect("pressed", self, "_on_Button_pressed")

	# Opcional: Asegurarse de que el panel comience en la posición 1 al iniciar el juego
	# Esto es útil si la posición inicial en el editor es diferente
	if panel:
		panel.rect_position = position_1
		print("Panel inicializado en Position 1: ", position_1)

func _on_Button_pressed():
	if panel:
		var tween = Tween.new()
		add_child(tween)

		var target_position = Vector2.ZERO # Variable temporal para el destino

		if _is_at_position_1:
			# Si actualmente está en posición 1, el destino es posición 2
			target_position = position_2
			_is_at_position_1 = false # Actualiza el estado para el próximo clic
			print("Moviendo a Position 2: ", target_position)
		else:
			# Si actualmente está en posición 2, el destino es posición 1
			target_position = position_1
			_is_at_position_1 = true # Actualiza el estado para el próximo clic
			print("Moviendo a Position 1: ", target_position)

		tween.interpolate_property(panel, "rect_position",
								   panel.rect_position, # Siempre comienza desde donde esté actualmente
								   target_position,     # El destino que acabamos de definir
								   0.5,                 # Duración de la animación en segundos
								   Tween.TRANS_SINE, Tween.EASE_OUT)
		
		tween.start()
	else:
		print("Error: El Panel no está asignado en el Inspector del botón.")


