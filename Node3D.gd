extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


func mostrar_ui_construccion(activo: bool):
	
	get_node("UIConstruction").visible = activo
	
	
	get_node("CanvasLayer").visible = not activo

	



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_ButtonModoConstruction_pressed():
	 mostrar_ui_construccion(true)
