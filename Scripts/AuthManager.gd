extends Node

# Señales para que otras partes del juego reaccionen al estado del login
signal login_succeeded
signal login_failed(error_message)
signal logout_succeeded

# Variables para guardar el estado de la sesión
var current_user = null
var access_token = null

# Referencia a SupabaseManager (que también debería ser un Autoload)
onready var supabase_manager = get_node("/root/SupabaseManager")

func _ready():
	# Conectar las señales de SupabaseManager a este gestor
	supabase_manager.connect("login_succeeded", self, "_on_login_succeeded")
	supabase_manager.connect("login_failed", self, "_on_login_failed")
	supabase_manager.connect("signed_out", self, "_on_logout_succeeded")

# --- Funciones Públicas ---

# Función para iniciar el proceso de login
func login(email, password):
	supabase_manager.sign_in(email, password)

# Función para cerrar sesión
func logout():
	supabase_manager.sign_out()

# Función para comprobar si el usuario está autenticado
func is_authenticated() -> bool:
	return current_user != null and access_token != null

# Función para obtener el ID del usuario actual
func get_user_id():
	if is_authenticated():
		return current_user.id
	return null

# --- Manejadores de Señales de Supabase ---

func _on_login_succeeded(data):
	print("AuthManager: Login exitoso. Guardando sesión.")
	current_user = data.user
	access_token = data.access_token
	# Notificar al resto del juego que el login fue exitoso
	emit_signal("login_succeeded")

func _on_login_failed(error_message):
	print("AuthManager: Falló el login.")
	current_user = null
	access_token = null
	# Notificar al resto del juego que el login falló
	emit_signal("login_failed", error_message)

func _on_logout_succeeded():
	print("AuthManager: Sesión cerrada.")
	current_user = null
	access_token = null
	emit_signal("logout_succeeded")
