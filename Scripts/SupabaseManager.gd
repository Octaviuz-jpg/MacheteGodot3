extends Node

# Configuración de Supabase - REEMPLAZA CON TUS CREDENCIALES

const SUPABASE_URL = "https://yvimqxwsndyiyeshjyiv.supabase.co/"
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2aW1xeHdzbmR5aXllc2hqeWl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwOTMwMzgsImV4cCI6MjA2ODY2OTAzOH0.mZpGuMbCOU6Ptvh27i3OCErUlxfWCBx43k6I4ccxSaI"
const BUCKET_NAME = "spaces"

# Nodos HTTP
var load_request: HTTPRequest
var upload_request: HTTPRequest
var db_insert_request: HTTPRequest
var download_request: HTTPRequest
var signup_request: HTTPRequest
var signin_request: HTTPRequest
var signout_request: HTTPRequest
var link_request: HTTPRequest
var tairon_load_request: HTTPRequest # <-- NUEVO

# Señales para comunicarse con Main
signal scene_loaded(scene_data)
signal scene_saved(success)
signal error_occurred(message)
signal tairon_structure_loaded(data) # <-- NUEVO

# Señales de autenticación
signal login_succeeded(user_data)
signal login_failed(error_message)
signal signup_succeeded()
signal signup_failed(error_message)
signal signed_out()

# Datos del usuario actual
var current_user = null
var access_token = null

func _ready():
	# Crear nodos HTTPRequest
	load_request = HTTPRequest.new()
	upload_request = HTTPRequest.new()
	db_insert_request = HTTPRequest.new()
	download_request = HTTPRequest.new()
	signup_request = HTTPRequest.new()
	signin_request = HTTPRequest.new()
	signout_request = HTTPRequest.new()
	link_request = HTTPRequest.new()
	tairon_load_request = HTTPRequest.new() # <-- NUEVO
	
	add_child(load_request)
	add_child(upload_request)
	add_child(db_insert_request)
	add_child(download_request)
	add_child(signup_request)
	add_child(signin_request)
	add_child(signout_request)
	add_child(link_request)
	add_child(tairon_load_request) # <-- NUEVO
	
	# Conectar señales
	load_request.connect("request_completed", self, "_on_load_request_completed")
	upload_request.connect("request_completed", self, "_on_upload_completed")
	db_insert_request.connect("request_completed", self, "_on_db_insert_completed")
	download_request.connect("request_completed", self, "_on_download_completed")
	signup_request.connect("request_completed", self, "_on_signup_completed")
	signin_request.connect("request_completed", self, "_on_signin_completed")
	signout_request.connect("request_completed", self, "_on_signout_completed")
	link_request.connect("request_completed", self, "_on_link_request_completed")
	tairon_load_request.connect("request_completed", self, "_on_tairon_load_completed") # <-- NUEVO
	
	print("✅ SupabaseManager inicializado")

# --- LÓGICA PARA CARGAR ESTRUCTURA TAIRON ---

func load_tairon_structure():
	var user_id = get_user_id()
	if not user_id:
		print("Error: No se puede cargar la estructura Tairon sin un usuario logueado.")
		emit_signal("tairon_structure_loaded", null)
		return

	print("🧱 Cargando estructura Tairon para el usuario: ", user_id)
	# Asumo que la tabla se llama 'estructuras_tairon'. ¡Cámbialo si es necesario!
	var url = SUPABASE_URL + "/rest/v1/estructuras_tairon?select=pos_x,pos_y,pos_z&user_id=eq." + user_id
	var headers = [
		"Authorization: Bearer " + access_token,
		"apikey: " + SUPABASE_ANON_KEY
	]
	
	tairon_load_request.request(url, headers, true, HTTPClient.METHOD_GET)

func _on_tairon_load_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	print("🧱 Respuesta de carga Tairon - Código: ", response_code)
	
	if response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8())
		if json.error == OK:
			print("✅ Estructura Tairon recibida.")
			emit_signal("tairon_structure_loaded", json.result)
		else:
			print("❌ Error al parsear JSON de estructura Tairon: ", json.error_string)
			emit_signal("tairon_structure_loaded", null)
	else:
		var error_message = "Error al cargar estructura Tairon: " + str(response_code)
		if body.size() > 0:
			error_message += " - " + body.get_string_from_utf8()
		print("❌ ", error_message)
		emit_signal("tairon_structure_loaded", null)

# --- FIN DE LÓGICA TAIRON ---

# --- NUEVO FLUJO DE GUARDADO ---

func save_scene_state(scene_data: Dictionary):
	print("💾 Iniciando nuevo flujo de guardado...")
	
	# 1. Guardar estado en archivo local temporal
	var local_path = "user://scene_state.json"
	var file = File.new()
	var err = file.open(local_path, File.WRITE)
	if err != OK:
		print("❌ Error al abrir archivo local para escritura: ", err)
		emit_signal("error_occurred", "No se pudo crear el archivo local")
		return
		
	file.store_string(JSON.print(scene_data, "	"))
	file.close()
	
	# 2. Subir el archivo a Supabase Storage
	var remote_file_name = "scene_" + str(OS.get_unix_time()) + ".json"
	upload_file(local_path, remote_file_name)

func upload_file(file_path: String, file_name: String):
	print("⬆️ Subiendo archivo: ", file_name)
	
	var file = File.new()
	if file.open(file_path, File.READ) != OK:
		print("❌ Error al abrir el archivo: ", file_path)
		emit_signal("error_occurred", "No se pudo abrir el archivo local")
		return
	
	var file_content_bytes = file.get_buffer(file.get_len())
	file.close()
	
	var request_body = file_content_bytes.get_string_from_utf8()
	
	var url = "%s/storage/v1/object/%s/%s" % [SUPABASE_URL, BUCKET_NAME, file_name]
	var headers = [
		"Authorization: Bearer " + access_token, # USAR TOKEN DE USUARIO
		"apikey: " + SUPABASE_ANON_KEY,
		"Content-Type: application/json"
	]
	
	upload_request.set_meta("file_name", file_name)
	upload_request.request(url, headers, true, HTTPClient.METHOD_POST, request_body)

func _on_upload_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	print("⬆️ Respuesta de subida - Código: ", response_code)
	
	var file_name = upload_request.get_meta("file_name")
	if file_name == null:
		emit_signal("error_occurred", "Error interno: no se encontró el nombre del archivo post-subida.")
		emit_signal("scene_saved", false)
		return

	if response_code == 200:
		print("✅ Archivo subido exitosamente: ", file_name)
		# Guardamos solo el nombre del archivo en la DB, no la URL completa.
		_insert_space_record(file_name, file_name)
	else:
		var error_message = "Error al subir archivo: " + str(response_code)
		if body.size() > 0:
			var response_text = body.get_string_from_utf8()
			print("❌ Error de subida: ", response_text)
			error_message += " - " + response_text
		
		emit_signal("error_occurred", error_message)
		emit_signal("scene_saved", false)

func _insert_space_record(file_name: String, file_route: String):
	print("✍️ Insertando registro en la tabla 'space'...")
	
	var user_id = get_current_user_id()
	if user_id == null:
		print("❌ No se puede insertar en 'space' sin un usuario logueado.")
		emit_signal("error_occurred", "No hay sesión activa para guardar.")
		emit_signal("scene_saved", false)
		return

	var url = SUPABASE_URL + "/rest/v1/space"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + access_token, # USAR TOKEN DE USUARIO
		"apikey: " + SUPABASE_ANON_KEY,
		"Prefer: return=representation" # Pedir que devuelva el objeto creado
	]
	
	var db_data = {
		"name": file_name,
		"route": file_route,
		"user_id": user_id
	}
	
	var json_data = JSON.print(db_data)
	db_insert_request.request(url, headers, true, HTTPClient.METHOD_POST, json_data)

func _on_db_insert_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	print("✍️ Respuesta de inserción en DB 'space' - Código: ", response_code)
	
	if response_code == 201:
		print("✅ Registro en 'space' creado exitosamente")
		var json = JSON.parse(body.get_string_from_utf8())
		if json.error == OK and json.result is Array and json.result.size() > 0:
			var new_space_id = json.result[0].id
			var user_id = get_current_user_id()
			if user_id:
				_link_user_to_space(user_id, new_space_id)
			else:
				emit_signal("error_occurred", "Error crítico: ID de usuario no encontrado después de crear espacio.")
				emit_signal("scene_saved", false)
		else:
			var error_msg = "No se pudo obtener el ID del nuevo espacio."
			if json.error != OK:
				error_msg += " Error de parseo: " + json.error_string
			print("❌ ", error_msg)
			emit_signal("error_occurred", error_msg)
			emit_signal("scene_saved", false)
	else:
		var error_message = "Error al insertar en 'space': " + str(response_code)
		if body.size() > 0:
			var response_text = body.get_string_from_utf8()
			print("❌ Error de inserción en 'space': ", response_text)
			error_message += " - " + response_text
		
		emit_signal("error_occurred", error_message)
		emit_signal("scene_saved", false)

func _link_user_to_space(user_id, space_id):
	print("🔗 Vinculando usuario ", user_id, " con espacio ", space_id)
	var url = SUPABASE_URL + "/rest/v1/user_space"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + access_token,
		"apikey: " + SUPABASE_ANON_KEY,
		"Prefer: return=minimal"
	]
	var body_data = {
		"user_id": user_id,
		"space_id": space_id
	}
	link_request.request(url, headers, true, HTTPClient.METHOD_POST, JSON.print(body_data))

func _on_link_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	print("🔗 Respuesta de vinculación 'user_space' - Código: ", response_code)
	if response_code == 201 or response_code == 204: # 201: Created, 204: No Content
		print("✅ Vinculación completada. Escena guardada.")
		emit_signal("scene_saved", true)
	else:
		var error_message = "Error al vincular usuario y espacio: " + str(response_code)
		if body.size() > 0:
			var response_text = body.get_string_from_utf8()
			print("❌ Error de vinculación: ", response_text)
			error_message += " - " + response_text
		emit_signal("error_occurred", error_message)
		emit_signal("scene_saved", false)


# --- NUEVO FLUJO DE CARGA ---

func load_scene_state():
	var user_id = get_current_user_id()
	if user_id == null:
		print("⚠️ No hay usuario logueado, no se puede cargar la escena.")
		emit_signal("scene_loaded", {}) # Emitir señal con datos vacíos
		return

	print("📥 Iniciando carga para el usuario: ", user_id)
	
	# Query corregida: selecciona la ruta del espacio del usuario actual (user_id=eq.{user_id}), ordenado por fecha de creación descendente y limitado a 1.
	var url = SUPABASE_URL + "/rest/v1/space?select=route&user_id=eq." + user_id + "&order=created_at.desc&limit=1"
	var headers = [
		"Authorization: Bearer " + access_token,
		"apikey: " + SUPABASE_ANON_KEY
	]
	
	load_request.request(url, headers, true, HTTPClient.METHOD_GET)

func _on_load_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	print("📥 Respuesta de carga de DB - Código: ", response_code)
	
	if response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8())
		if json.error == OK:
			var data = json.result
			if data is Array and data.size() > 0:
				var file_name = data[0].route # La columna 'route' ahora contiene solo el nombre del archivo
				print("✅ Nombre de archivo obtenido: ", file_name)
				download_scene_file(file_name)
			else:
				print("ℹ️ No se encontró estado guardado para este usuario.")
				emit_signal("scene_loaded", {})
		else:
			print("❌ Error al parsear JSON de 'space': ", json.error_string)
			emit_signal("error_occurred", "Error al procesar datos de 'space'")
	else:
		var error_message = "Error al cargar desde 'space': " + str(response_code)
		if body.size() > 0:
			error_message += " - " + body.get_string_from_utf8()
		print("❌ ", error_message)
		emit_signal("error_occurred", error_message)

func download_scene_file(file_name: String):
	# Construimos la URL de la API para la descarga aquí, para asegurar que sea correcta.
	var url = "%s/storage/v1/object/%s/%s" % [SUPABASE_URL, BUCKET_NAME, file_name]
	print("⬇️ Descargando archivo de escena desde: ", url)
	var headers = [
		"Authorization: Bearer " + access_token,
		"apikey: " + SUPABASE_ANON_KEY
	]
	download_request.request(url, headers, true, HTTPClient.METHOD_GET)

func _on_download_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	print("⬇️ Respuesta de descarga - Código: ", response_code)
	
	if response_code == 200:
		var scene_json = body.get_string_from_utf8()
		var json = JSON.parse(scene_json)
		if json.error == OK:
			print("✅ Escena descargada y parseada exitosamente")
			emit_signal("scene_loaded", json.result)
		else:
			print("❌ Error al parsear JSON de la escena descargada: ", json.error_string)
			emit_signal("error_occurred", "El archivo de escena está corrupto")
	else:
		var error_message = "Error al descargar escena: " + str(response_code)
		if body.size() > 0:
			var response_text = body.get_string_from_utf8()
			print("❌ Detalle del error de descarga: ", response_text)
			error_message += " - " + response_text
		
		print("❌ ", error_message)
		emit_signal("error_occurred", error_message)


# --- FUNCIONES DE AUTENTICACIÓN ---

func sign_up(email, password):
	print("✍️ Intentando registrar nuevo usuario...")
	var url = SUPABASE_URL + "/auth/v1/signup"
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_ANON_KEY
	]
	var body = {
		"email": email,
		"password": password
	}
	var json_body = JSON.print(body)
	signup_request.request(url, headers, true, HTTPClient.METHOD_POST, json_body)

func _on_signup_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	print("✍️ Respuesta de registro - Código: ", response_code)
	if response_code == 200 or response_code == 201:
		print("✅ Registro exitoso. Revisa tu email para confirmación.")
		emit_signal("signup_succeeded")
	else:
		var error_message = "Error en el registro: " + str(response_code)
		var json = JSON.parse(body.get_string_from_utf8())
		if json.error == OK and json.result.has("msg"):
			error_message = json.result.msg
		elif json.error == OK and json.result.has("message"):
			error_message = json.result.message
		print("❌ ", error_message)
		emit_signal("signup_failed", error_message)

func sign_in(email, password):
	print("🔑 Intentando iniciar sesión...")
	var url = SUPABASE_URL + "/auth/v1/token?grant_type=password"
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_ANON_KEY
	]
	var body = {
		"email": email,
		"password": password
	}
	var json_body = JSON.print(body)
	signin_request.request(url, headers, true, HTTPClient.METHOD_POST, json_body)

func _on_signin_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	print("🔑 Respuesta de inicio de sesión - Código: ", response_code)
	if response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8())
		if json.error == OK:
			var data = json.result
			current_user = data.user
			access_token = data.access_token
			print("✅ Login exitoso para: ", current_user.email)
			emit_signal("login_succeeded", data)
		else:
			emit_signal("login_failed", "Respuesta de servidor inválida.")
	else:
		var error_message = "Email o contraseña incorrectos."
		var json = JSON.parse(body.get_string_from_utf8())
		if json.error == OK and json.result.has("error_description"):
			error_message = json.result.error_description
		print("❌ Error de login: ", error_message)
		emit_signal("login_failed", error_message)

func sign_out():
	if access_token == null:
		return

	print("🚪 Cerrando sesión...")
	var url = SUPABASE_URL + "/auth/v1/logout"
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + access_token
	]
	signout_request.request(url, headers, true, HTTPClient.METHOD_POST, "")

func _on_signout_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	if response_code == 204: # No Content, éxito
		print("✅ Sesión cerrada exitosamente.")
	else:
		print("❌ Error al cerrar sesión: ", response_code)
	
	current_user = null
	access_token = null
	emit_signal("signed_out")

func get_current_user_id():
	if current_user != null and current_user.has("id"):
		return current_user.id
	return null

# --- FUNCIÓN AÑADIDA ---
# Devuelve el ID del usuario actual si está logueado.
func get_user_id():
	if current_user and current_user.has("id"):
		return current_user.id
	return null
# --- FIN DE FUNCIÓN AÑADIDA ---


# --- FUNCIONES DE GESTIÓN DE ESPACIOS (A IMPLEMENTAR) ---

func get_spaces_for_user(user_id):
	# TODO: Implementar lógica para obtener espacios de un usuario
	pass

func create_new_space(user_id, space_name):
	# TODO: Implementar lógica para crear un nuevo espacio
	pass
