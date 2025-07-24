extends Control

func _on_Timer_timeout():
	# This timer seems to be a leftover from a fade-in effect.
	# The timeout signal is connected, but there's no action to perform.
	# This empty function prevents the game from crashing.
	print("Login timer timeout - doing nothing.")
	pass
