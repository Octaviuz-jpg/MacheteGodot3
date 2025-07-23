extends Button


var key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2aW1xeHdzbmR5aXllc2hqeWl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwOTMwMzgsImV4cCI6MjA2ODY2OTAzOH0.mZpGuMbCOU6Ptvh27i3OCErUlxfWCBx43k6I4ccxSaI" # Reemplaza esto con tu clave real
var estado_peticion = ""


func _on_Cambiar_contrasea_pressed():

	print("🔘 Botón presionado. Nodo HTTPRequestUpdate existe: ", has_node("HTTPRequestUpdate"))
	solicitar_reestablecer_contrasena("juliorbk.dev@gmail.com")


func solicitar_reestablecer_contrasena(email: String) -> void:
	var url = "https://yvimqxwsndyiyeshjyiv.supabase.co/auth/v1/recover"
	var headers = [
		"Content-Type: application/json",
		"apikey: " + key
	]
	var body = {"email": email}
	var json_body = JSON.print(body)
	
	var err = $HTTPRequestUpdate.request(url, headers, true, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		print("❌ Error al enviar solicitud de recuperación: ", err)
	else:
		print("🔄 Solicitud de recuperación enviada")
