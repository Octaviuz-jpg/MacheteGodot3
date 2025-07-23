extends Spatial

# Propiedades guardables
var color_tapiz: Color = Color.white
var material_actual: String = "tela"

func obtener_datos_guardado() -> Dictionary:
	return {
		"color_tapiz": color_tapiz,
		"material_actual": material_actual
	}

func aplicar_datos_guardado(datos: Dictionary):
	if datos.has("color_tapiz"):
		color_tapiz = datos["color_tapiz"]
	if datos.has("material_actual"):
		material_actual = datos["material_actual"]
	
	# Aplicar cambios visuales
	actualizar_apariencia()

func actualizar_apariencia():
	# Implementa cómo se aplican los cambios visuales
	# Por ejemplo, cambiar materiales/texturas
	pass
