extends Button

onready var email_input: LineEdit = get_node("../VBoxContainer/VBoxContainer/Linename")
onready var password_input: LineEdit = get_node("../VBoxContainer/VBoxContainer2/Linename")
onready var error_label: Label = get_node("../VBoxContainer/VBoxContainer/ErrorUsuario") # Asumiendo que tienes un label para errores

func _ready():
    # Conectarse a las señales del AuthManager global
    AuthManager.connect("login_succeeded", self, "_on_login_succeeded")
    AuthManager.connect("login_failed", self, "_on_login_failed")
    
    # Ocultar el label de error al inicio
    error_label.visible = false

func _on_inicio_pressed():
    # Ocultar errores previos y deshabilitar el botón para evitar clics múltiples
    error_label.visible = false
    disabled = true
    
    var email = email_input.text
    var password = password_input.text
    
    # Validar que los campos no estén vacíos
    if email.empty() or password.empty():
        _on_login_failed("El correo y la contraseña no pueden estar vacíos.")
        return
        
    # Llamar al AuthManager para que maneje el login
    AuthManager.login(email, password)

func _on_login_succeeded():
    print("Login exitoso! Cambiando al menú principal.")
    # Habilitar el botón por si el usuario vuelve a esta escena
    disabled = false
    
    # Cambiar a la escena del menú
    get_tree().change_scene("res://Scenes/Menu.tscn")

func _on_login_failed(error_message):
    print("Error de login: ", error_message)
    # Habilitar el botón para que el usuario pueda intentarlo de nuevo
    disabled = false
    
    # Mostrar el mensaje de error en la UI
    error_label.text = error_message
    error_label.visible = true

# Es una buena práctica desconectar las señales cuando el nodo se libera
func _exit_tree():
    if AuthManager.is_connected("login_succeeded", self, "_on_login_succeeded"):
        AuthManager.disconnect("login_succeeded", self, "_on_login_succeeded")
    if AuthManager.is_connected("login_failed", self, "_on_login_failed"):
        AuthManager.disconnect("login_failed", self, "_on_login_failed")
