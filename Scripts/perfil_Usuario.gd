extends Control


onready var correo_usuario = $Panel/correo_usuario
onready var nombre_usuario = $Panel/nombre_usuario


onready var cambiar_contrase_a = $"Panel/Menu_opciones/Cambiar_contraseña"
onready var proyectos = $Panel/Menu_opciones/Proyectos
onready var salir = $Panel/Menu_opciones/salir 


func _ready():
	# una carga estatica de prueba
	_load_user_data_example("Mauricio Arismendi", "mauricio.arismendi@ejemplo.com")


# --- Función para cargar y mostrar datos del usuario PRUEBA
func _load_user_data_example(name: String, email: String):
	# Asigna los textos a los Labels pero de prueba 
	if nombre_usuario: 
		nombre_usuario.text = name
	if correo_usuario: 
		correo_usuario.text = email


func _on_Cambiar_contrasea_pressed():
	pass # Replace with function body.
