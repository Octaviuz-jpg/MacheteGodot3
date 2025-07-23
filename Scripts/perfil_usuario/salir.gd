extends Button

func _on_salir_pressed():
	print("Botón 'Salir' presionado. Volviendo al menú principal.")

	get_tree().change_scene("res://Scenes/Menu.tscn")
