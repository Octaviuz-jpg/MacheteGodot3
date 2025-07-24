extends Control # O Node2D, dependiendo de tu nodo raíz

# Referencia al AnimationPlayer. (Sigue siendo necesario para reproducir el fade visual)
onready var animation_player = $CanvasLayer/AnimationPlayer

func _ready():
	animation_player.play("fadein")
