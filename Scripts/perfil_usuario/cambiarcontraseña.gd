extends Button


var key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2aW1xeHdzbmR5aXllc2hqeWl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwOTMwMzgsImV4cCI6MjA2ODY2OTAzOH0.mZpGuMbCOU6Ptvh27i3OCErUlxfWCBx43k6I4ccxSaI" # Reemplaza esto con tu clave real
var estado_peticion = ""


func _on_Cambiar_contrasea_pressed():
	print("🔘 Botón presionado. Nodo HTTPRequestUpdate existe: ", has_node("HTTPRequestUpdate")) 
	var nueva_contrasena := "1234567"  # Cambia por la contraseña que desees
	cambiar_contrasena(nueva_contrasena)

func cambiar_contrasena(nueva_contrasena: String) -> void:
	var url := "https://yvimqxwsndyiyeshjyiv.supabase.co/auth/v1/user"
	var token := obtener_token_guardado()

	if token == "":
		print("❌ No se encontró token JWT, no se puede autenticar la petición")
		return

	var headers := [
		"Content-Type: application/json",
		"Authorization: Bearer " + token,
		"apikey: " + key
	]

	var body := { "password": nueva_contrasena }
	var json_body := JSON.print(body)

	print("🔄 Enviando solicitud para cambiar contraseña...")

	var err: int = $HTTPRequestUpdate.request(url, headers, true, HTTPClient.METHOD_PUT, json_body)
	if err != OK:
		print("❌ Error al enviar la solicitud de actualización: ", err)

func _on_HTTPRequestUpdate_request_completed(result, response_code, headers, body):
	print("📥 Respuesta del cambio de contraseña recibida")
	print("Código HTTP:", response_code)
	print("Cuerpo:", body.get_string_from_utf8())

	if response_code == 200:
		print("✅ Contraseña actualizada correctamente")
	else:
		print("❌ Error al actualizar contraseña")

func obtener_token_guardado() -> String:
	var file := File.new()
	if file.file_exists("user://token.jwt"):
		file.open("user://token.jwt", File.READ)
		var token := file.get_line()
		file.close()
		return token.strip_edges()
	return ""

#var new_scene_path = "res://Scenes/CambiarContr.tscn"
#var new_scene_packed = load(new_scene_path)
#var new_scene_instance = new_scene_packed.instance()

	# 2. Obtener la escena actual (la que queremos liberar)
#var current_scene_node = get_tree().current_scene

	# 3. Eliminar la escena actual del árbol
	# Esto activará _exit_tree() en los nodos de la escena anterior
#current_scene_node.queue_free()

	# 4. Añadir la nueva escena al nodo raíz del árbol
	# get_tree().root es el Viewport global del juego.
#get_tree().root.add_child(new_scene_instance)

	# 5. Establecer la nueva escena como la escena principal del árbol
#get_tree().current_scene = new_scene_instance

