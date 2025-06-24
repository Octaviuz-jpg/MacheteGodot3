extends Button

func _on_Proyectos_pressed():
	print("Lo siento , esa vista aun no esta disponible, por el momento unicamente tenemos la vista Control.tscn")
	get_tree().change_scene("res://Control.tscn")
