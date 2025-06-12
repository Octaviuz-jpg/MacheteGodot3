extends Node

onready var altura = $"%alturaText"
onready var profundidad = $"%profundidadText"
onready var anchura = $"%anchuraText"
onready var error_label = $"%ErrorLabel"  # Asegúrate de tener un Label para mostrar el error

func _on_Button_pressed():
	var altura_val = float(altura.text)
	var anchura_val = float(anchura.text)
	var profundidad_val = float(profundidad.text)

	if not _validar_medidas(altura_val, anchura_val, profundidad_val):
		error_label.text = "⚠️ERROR: Las medidas deben estar entre 1 y 50."
		return

	MedidasSingleton.altura = altura_val
	MedidasSingleton.anchura = anchura_val
	MedidasSingleton.profundidad = profundidad_val

	print("Valores almacenados:")
	print("Altura:", MedidasSingleton.altura)
	print("Anchura:", MedidasSingleton.anchura)
	print("Profundidad:", MedidasSingleton.profundidad)
	error_label.text = ""  # Oculta el mensaje de error al corregir los valores
	get_tree().change_scene("res://Node3D.tscn")

func _validar_medidas(altura_val, anchura_val, profundidad_val) -> bool:
	return altura_val > 0 and altura_val <= 50 and anchura_val > 0 and anchura_val <= 50 and profundidad_val > 0 and profundidad_val <= 50
