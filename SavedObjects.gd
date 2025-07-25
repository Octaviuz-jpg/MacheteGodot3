class_name SaveObj
extends Resource 


const SAVE_PATH="res://proyectos_guardados/test.tres"

export var objects = [] 
export var height=0.0
export var width=0.0
export var depth=0.0

func write_save() -> void:
	ResourceSaver.save(SAVE_PATH, self)

func load_save()->Resource:
	return ResourceLoader.load(SAVE_PATH)
