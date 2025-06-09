extends Node
func _on_Button_pressed():
	MedidasSingleton.altura = float($altura.text.strip_edges())
	MedidasSingleton.anchura = float($anchura.text.strip_edges())
	MedidasSingleton.profundidad = float($profundidad.text.strip_edges())

	print("Valores almacenados:")
	print("Altura:", MedidasSingleton.altura)
	print("Anchura:", MedidasSingleton.anchura)
	print("Profundidad:", MedidasSingleton.profundidad)

	get_tree().change_scene("res://Node3D.tscn")
