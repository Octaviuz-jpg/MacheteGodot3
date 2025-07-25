extends Node

func process_input(camera, event):
    # if camera.is_aerial_view:
    #     return

    # Rotación con el ratón
    if camera.mouse_captured and event is InputEventMouseMotion:
        camera.camera_view_y -= event.relative.x * camera.camera_sensitivity
        camera.camera_view_x -= event.relative.y * camera.camera_sensitivity
        camera.camera_view_x = clamp(camera.camera_view_x, -90, 90)
        camera.rotation_degrees = Vector3(camera.camera_view_x, camera.camera_view_y, 0)

    if event is InputEventKey and event.scancode == KEY_ESCAPE and event.pressed:
        if camera.mouse_captured:
            camera.mouse_captured = false
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            camera.mouse_captured = true
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)