extends Node

var objeto_seleccionado: Node = null

func seleccionar_objeto(nodo: Node):
	if nodo and nodo.is_in_group("colocados"):
		objeto_seleccionado = nodo
		objeto_seleccionado.modulate = Color(1, 0.5, 0.5)  # rosa claro: seleccionado
		print("🔍 Seleccionado:", nodo.name)
	else:
		print("⚠️ Nodo no válido para selección")

func eliminar_objeto_seleccionado():
	if objeto_seleccionado and objeto_seleccionado.is_inside_tree():
		print("🗑️ Eliminando:", objeto_seleccionado.name)
		objeto_seleccionado.queue_free()
	else:
		print("⚠️ Nada que eliminar o nodo ya destruido")
	objeto_seleccionado = null
