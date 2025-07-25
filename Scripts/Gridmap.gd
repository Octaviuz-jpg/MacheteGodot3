extends Spatial # O el nodo donde tengas tu script principal y el GridMap

onready var mi_grid_map = $GridMap # Asegúrate de que la ruta a tu GridMap sea correcta

# Configuración del tamaño del GridMap a generar
# Estas representan la "extensión" total en cada dirección desde el centro
export var grid_width = 10  # Ancho total en celdas
export var grid_height = 1   # Alto total en celdas
export var grid_depth = 10  # Profundidad total en celdas

# El ID de la malla que queremos usar (conocemos que es 0)
var mesh_instance_id = 0 # ID del componente 'MeshInstance' en tu MeshLibrary

func _ready():
	# Asegurarse de que el GridMap tenga una MeshLibrary asignada
	if mi_grid_map.mesh_library == null:
		print("¡Advertencia! El GridMap no tiene una MeshLibrary asignada. No se puede generar la malla.")
		return

	# Llamar a la función para generar el GridMap al inicio
	# Pasamos las dimensiones completas. La función calculará los rangos centrados.
	generar_grid_map_centrado(grid_width, grid_height, grid_depth, mesh_instance_id)

func generar_grid_map_centrado(total_width: int, total_height: int, total_depth: int, mesh_id: int):
	"""
	Genera un GridMap completo con una malla específica, centrado en el origen (0,0,0).

	Args:
		total_width: El ancho TOTAL del GridMap en celdas (eje X).
		total_height: El alto TOTAL del GridMap en celdas (eje Y).
		total_depth: La profundidad TOTAL del GridMap en celdas (eje Z).
		mesh_id: El ID del componente de la MeshLibrary a utilizar para llenar el GridMap.
	"""
	print("Generando GridMap centrado de tamaño ", total_width, "x", total_height, "x", total_depth, " con mesh ID: ", mesh_id)

	# Limpiar el GridMap existente antes de generar uno nuevo
	mi_grid_map.clear()

	# Calcular los puntos de inicio para cada eje para centrar el GridMap
	# Usamos floor para asegurar que si el tamaño es impar, el centro esté bien distribuido.
	var start_x = floor(-total_width / 2.0)
	var end_x = floor(total_width / 2.0) # Ajustado para que el tamaño total sea correcto

	var start_y = floor(-total_height / 2.0)
	var end_y = floor(total_height / 2.0)

	var start_z = floor(-total_depth / 2.0)
	var end_z = floor(total_depth / 2.0)

	# Compensar para tamaños pares/impares para asegurar el número correcto de celdas
	# Si total_width es par (ej. 10), start_x = -5, end_x = 5. El rango for (start_x, end_x) dará 10 celdas.
	# Si total_width es impar (ej. 11), start_x = -5, end_x = 5. El rango for (start_x, end_x) dará 11 celdas.
	# El rango en Godot es inclusivo del inicio, exclusivo del fin. range(a, b) -> [a, b-1]
	# Queremos range(start, end + 1) para que 'end' sea inclusivo.

	for x in range(int(start_x), int(end_x) + 1):
		for y in range(int(start_y), int(end_y) + 1):
			for z in range(int(start_z), int(end_z) + 1):
				mi_grid_map.set_cell_item(x, y, z, mesh_id, 0)
	
	print("GridMap generado exitosamente y centrado en el origen.")



func _on_vistaAerea_pressed():
	pass # Replace with function body.


func _on_trancarCamara_pressed():
	pass # Replace with function body.
