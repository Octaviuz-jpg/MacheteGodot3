extends Button


onready var email: LineEdit=$"../VBoxContainer/VBoxContainer/Linename"
onready var password: LineEdit=$"../VBoxContainer/VBoxContainer2/Linename"
onready var errorUsuario: Label=$"../VBoxContainer/VBoxContainer/ErrorUsuario"
onready var errorCont: Label=$"../VBoxContainer/VBoxContainer2/ErrorCont"
var sign_in_status= false


func _ready():
	# Conectarse a las señales del AuthManager global
	AuthManager.connect("login_succeeded", self, "_on_login_succeeded")
	AuthManager.connect("login_failed", self, "_on_login_failed")




func _on_inicio_pressed():
	print("Login button pressed!")
	var entered_email
	var entered_password 
	
	
	
	#Validación para mandar contenido del correo
	if email.text.length() ==0:
		Popups.PopAbrirE("ERROR: Ingrese su correo electronico, antes de continuar por favor")
		errorUsuario.text="Ingrese su correo"
		errorUsuario.visible=true
		
	else:
		errorUsuario.visible=false
		
	#Validación para mandar contenido del password
	if password.text.length() ==0:
		Popups.PopAbrirE("ERROR: Ingrese su contraseña, antes de continuar por favor")
		errorCont.text="Ingrese su contraseña"
		errorCont.visible=true
	else:
		errorCont.visible=false
	
	
	if email.text.length()>0 and password.text.length()>0:
		entered_email = email.text
		entered_password = password.text
		print("Attempting sign-in with email: " + entered_email)
		#Supabase.auth.sign_in(entered_email, entered_password)
		# Llamar al AuthManager para que maneje el login
		AuthManager.login(email.text, password.text)
	else:
		print("Campo vacio, enviar información de usuario solicitada")

# Al fallar el inicio de sesión
func _on_auth_error(error : SupabaseAuthError):
	print("Supabase Auth Error: ", error.type)


func guardar_token(token: String) -> void:
	var file = File.new()
	if file.open("user://token.jwt", File.WRITE) == OK:
		file.store_line(token)
		file.close()
		print("📂 Ruta real: ", ProjectSettings.globalize_path("user://token.jwt"))

		print("💾 Token guardado en user://token.jwt")
	else:
		print("❌ No se pudo guardar el token.")

func obtener_token_jwt() -> String:
	var bearer_header = Supabase.auth.get("_bearer")
	if bearer_header and bearer_header.size() > 0:
		# bearer_header es un array con el string "Authorization: Bearer <token>"
		var bearer_string = bearer_header[0]
		# Extraer solo el token (quitar "Authorization: Bearer ")
		return bearer_string.replace("Authorization: Bearer ", "")
	return ""
	

func _on_login_succeeded():
	print("Login exitoso! Cambiando al menú principal.")
	var jwt = obtener_token_jwt()
	if jwt != "":
		guardar_token(jwt)
	else:
		print("No se pudo obtener token JWT")
	# Habilitar el botón por si el usuario vuelve a esta escena
	disabled = false
	
	# Cambiar a la escena del menú
	get_tree().change_scene("res://Scenes/Menu.tscn")
	

func _on_login_failed(error_message):
	print("Error de login: ", error_message)
	# Habilitar el botón para que el usuario pueda intentarlo de nuevo
	disabled = false

# Es una buena práctica desconectar las señales cuando el nodo se libera
func _exit_tree():
	if AuthManager.is_connected("login_succeeded", self, "_on_login_succeeded"):
		AuthManager.disconnect("login_succeeded", self, "_on_login_succeeded")
	if AuthManager.is_connected("login_failed", self, "_on_login_failed"):
		AuthManager.disconnect("login_failed", self, "_on_login_failed")
