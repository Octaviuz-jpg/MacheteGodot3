extends Control
onready var errortext= "no hubo ningun error"

func PopAbrirE(error):
	#$PopupPanel/VBoxContainer/Label.text(error)
	print("popup")
	$PopupPanel.popup()
	errortext= error

func PopCerrarE():
	$PopupPanel/VBoxContainer/Label.text("Por favore revisa tu correo electronico")
	$PopupPanel.hide()

func PopAbrir():
	$PopupPanel.popup()

func PopCerrar():
	$PopupPanel.hide()



func _on_Button_pressed():
	PopCerrarE()
