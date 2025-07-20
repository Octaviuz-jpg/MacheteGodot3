extends Camera

func _ready():
	var altura = max(MedidasSingleton.altura, 3) + 2
	var ancho = MedidasSingleton.anchura
	var largo = MedidasSingleton.profundidad
	var margen = 1.1  # 10% extra de espacio

	global_transform.origin = Vector3(0, altura, 0)
	rotation_degrees = Vector3(-90, 0, 0)

	# Asegurarnos de ver el lado más largo de la habitación en horizontal
	var viewport = get_viewport()
	var aspect_ratio = float(viewport.size.x) / float(viewport.size.y)
	var lado_visible = max(ancho, largo) * margen

	# Conversión de lado horizontal a FOV vertical
	var fov_rads = 2.0 * atan((lado_visible * 0.5) / (altura * aspect_ratio))
	fov = rad2deg(fov_rads)

	print("🛰️ Altura:", altura, " | Aspect:", aspect_ratio, " | FOV calculado:", fov)
