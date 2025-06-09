extends Node

onready var altura = $"%alturaText"
onready var profundidad = $"%profundidadText"
onready var anchura = $"%anchuraText"

func _on_Button_pressed():
	MedidasSingleton.altura = float(altura.text)
	MedidasSingleton.anchura = float(anchura.text)
	MedidasSingleton.profundidad = float(profundidad.text)

	print("Valores almacenados:")
	print("Altura:", MedidasSingleton.altura)
	print("Anchura:", MedidasSingleton.anchura)
	print("Profundidad:", MedidasSingleton.profundidad)

	get_tree().change_scene("res://Node3D.tscn")
