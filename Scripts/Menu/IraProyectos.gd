extends Button


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	print("Lo siento , esa vista aun no esta disponible, por el momento unicamente tenemos la vista Control.tscn")
	get_tree().change_scene("res://Control.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
