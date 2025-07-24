extends Button

onready var email: LineEdit=$"../VBoxContainer/VBoxContainer/Linename"
onready var password: LineEdit=$"../VBoxContainer/VBoxContainer2/Linename"
onready var errorUsuario: Label=$"../VBoxContainer/VBoxContainer/ErrorUsuario"
onready var errorCont: Label=$"../VBoxContainer/VBoxContainer2/ErrorCont"
var sign_in_status= false



func _ready():
	if Supabase:
		Supabase.auth.connect("signed_in", self, "_on_auth_success")
		Supabase.auth.connect("error", self, "_on_auth_error")
		print("Supabase auth error and signed_in signals connected.")
	else:
		push_error("Supabase AutoLoad not found. Please check Project Settings -> AutoLoad.")

#	self.connect("pressed", self, "_on_inicio_pressed")
	print("Button pressed signal connected.")

func _on_inicio_pressed():
	print("Login button pressed!")
	var entered_email
	var entered_password 
	
	#Validación para mandar contenido del correo
	if email.text.length() ==0:
		errorUsuario.text="Ingrese su usuario"
		errorUsuario.visible=true
	else:
		errorUsuario.visible=false
		
	#Validación para mandar contenido del password
	if password.text.length() ==0:
		errorCont.text="Ingrese su contraseña"
		errorCont.visible=true
	else:
		errorCont.visible=false
	
	#Si se ingresan datos en los campos de email y passworod  se mandará a Supabase 
	# para realizar la autenticacion de usuario
	
	if email.text.length()>0 and password.text.length()>0:
		entered_email = email.text
		entered_password = password.text
		print("Attempting sign-in with email: " + entered_email)
		Supabase.auth.sign_in(entered_email, entered_password)
	else:
		print("Campo vacio, enviar información de usuario solicitada")


# Al lograrse el inicio de sesión
func _on_auth_success(user: SupabaseUser): 
	print("Supabase Auth Success! User: ", user)
	var new_scene_path = "res://Scenes/Menu.tscn"
	var new_scene_packed = load(new_scene_path)
	var new_scene_instance = new_scene_packed.instance()

	# 2. Obtener la escena actual (la que queremos liberar)
	var current_scene_node = get_tree().current_scene

	# 3. Eliminar la escena actual del árbol
	# Esto activará _exit_tree() en los nodos de la escena anterior
	current_scene_node.queue_free()

	# 4. Añadir la nueva escena al nodo raíz del árbol
	# get_tree().root es el Viewport global del juego.
	get_tree().root.add_child(new_scene_instance)

	# 5. Establecer la nueva escena como la escena principal del árbol
	get_tree().current_scene = new_scene_instance


# Al fallar el inicio de sesión
func _on_auth_error(error : SupabaseAuthError):
	print("Supabase Auth Error: ", error.type)
