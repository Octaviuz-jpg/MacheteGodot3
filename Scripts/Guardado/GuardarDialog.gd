extends AcceptDialog

onready var nombre_line_edit = $NombreLineEdit

func _ready():
	register_text_enter(nombre_line_edit)
	connect("confirmed", self, "_on_confirmed")

func obtener_nombre_proyecto() -> String:
	return nombre_line_edit.text.strip_edges()

func _on_confirmed():
	if obtener_nombre_proyecto().empty():
		nombre_line_edit.placeholder_text = "¡El nombre no puede estar vacío!"
		nombre_line_edit.text = ""
		popup_centered()
