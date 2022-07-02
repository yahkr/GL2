extends Control


@onready var player := get_parent()
@onready var options := get_node("Options")
@onready var pause_controls := get_node("PauseControls")
@onready var tab_bar := options.get_node("TabBar")
@onready var tabs := options.get_node("Tabs")
@onready var input_mapping := tabs.get_node("InputMapping")

const FSR = [0.77, 0.67, 0.59, 0.5]


func _ready():
	for tab in tabs.get_children():
		initialize_tab(tab)


func _input(event):
	if event.is_pressed():
		if (event is InputEventKey and event.keycode == KEY_ESCAPE and not event.is_echo()
				or event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START):
			if pause_controls.visible:
				toggle_pause()
			elif options.visible:
				options.visible = false
				pause_controls.visible = true


func apply_option(new_value: Variant, option: StringName):
	match option:
		# Mouse
		&"MouseSensitivity":
			player.mouse_look_sensitivity = new_value
		&"MouseHorizontalInverted":
			player.mouse_look_inverted_x = new_value
		&"MouseVerticalInverted":
			player.mouse_look_inverted_y = new_value
		
		# Controller
		&"ControllerHorizontalSensitivity":
			player.joypad_look_sensitivity_x = new_value
		&"ControllerVerticalSensitivity":
			player.joypad_look_sensitivity_y = new_value
		&"ControllerHorizontalInverted":
			player.joypad_look_inverted_x = new_value
		&"ControllerVerticalInverted":
			player.joypad_look_inverted_y = new_value
		&"ControllerResponseCurve":
			player.joypad_look_curve = new_value
		&"ControllerDeadzone":
			for action in ["look_up", "look_down", "look_left", "look_right"]:
				InputMap.action_set_deadzone(action, new_value)
		&"ControllerOuterThreshold":
			player.joypad_look_outer_threshold = new_value
		
		# Video
		&"3DScale":
			get_viewport().scaling_3d_scale = new_value
		&"AntiAliasing":
			match new_value:
				0:
					get_viewport().msaa = Viewport.MSAA_DISABLED
					get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
				1:
					get_viewport().msaa = Viewport.MSAA_DISABLED
					get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
				2:
					get_viewport().msaa = Viewport.MSAA_2X
					get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		&"Bloom":
			player.get_world_3d().environment.glow_enabled = new_value
		&"Brightness":
			player.get_world_3d().environment.adjustment_brightness = new_value
		&"FOV":
			get_viewport().get_camera_3d().fov = new_value
		&"FSR":
			var setter := tabs.get_node("Video/3DScale/Setter")
			if new_value == 0:
				get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
				get_viewport().scaling_3d_scale = setter.value
				setter.editable = true
			else:
				get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
				get_viewport().scaling_3d_scale = FSR[new_value - 1]
				setter.editable = false
		&"Fullscreen":
			if new_value:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		&"MaxFPS":
			Engine.target_fps = new_value
		&"ShowFPS":
			player.get_node("FPS").visible = new_value
		&"VSync":
			if new_value:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		
		# Audio
		&"VolumeMaster":
			new_value /= 4
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(new_value))
		&"VolumeSFX":
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear2db(new_value))
		&"VolumeMusic":
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear2db(new_value))
		&"VolumeDialog":
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Dialog"), linear2db(new_value))

func initialize_tab(tab: Control):
	for option in tab.get_children():
		if not option.is_in_group("Option"):
			continue
		
		var name_label := option.get_node("Name")
		name_label.text = tr(option.name)
		
		var setter := option.get_node("Setter")
		var default_value: Variant = setter.get_meta("default_value")
		var set_func: Callable
		var change_signal: Signal
		
		if setter is Slider:
			set_func = setter.set_value
			change_signal = setter.value_changed
		elif setter is CheckBox:
			set_func = setter.set_pressed
			change_signal = setter.toggled
		elif setter is OptionButton:
			set_func = setter._select_int
			change_signal = setter.item_selected
		else:
			continue
		
		var config_value = SaveManager.get_config_value(tab.name, option.name, default_value)
		set_func.call(config_value)
		
		update_value_label(config_value, setter)
		apply_option(config_value, option.name)
		
		if change_signal.get_connections().size() == 0:
			change_signal.connect(update_value_label.bind(setter))
			change_signal.connect(SaveManager.set_config_value.bind(tab.name, option.name))
			change_signal.connect(apply_option.bind(option.name))
	
	SaveManager.save_config_file()


func toggle_pause():
	visible = !visible
	get_tree().paused = visible
	
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func update_value_label(new_value: Variant, setter: Control):
	if new_value is float:
		var value_label := setter.get_parent().get_node("Value")
		if floor(setter.step) == setter.step:
			value_label.text = str(new_value)
		else:
			value_label.text = "%.2f" % new_value
	elif new_value is bool:
		if new_value:
			setter.text = "Enabled"
		else:
			setter.text = "Disabled"


func _on_restore_defaults_button_pressed():
	var tab_title: String = tab_bar.get_tab_title(tab_bar.current_tab)
	
	SaveManager.restore_defaults(tab_title)
	if input_mapping.visible:
		SaveManager.save_config_file()
		input_mapping.restore_defaults()
	else:
		initialize_tab(tabs.get_child(tab_bar.current_tab))


func _on_tab_bar_tab_changed(index):
	for tab in tabs.get_children():
		tab.visible = tab.get_index() == index


func _on_resume_button_pressed():
	%SoundClick.play()
	toggle_pause()


func _on_options_button_pressed():
	%SoundClick.play()
	options.visible = !options.visible
	pause_controls.visible = !pause_controls.visible


func _on_quit_button_pressed():
	%SoundClick.play()
	get_tree().quit()


func _on_button_mouse_entered():
	%SoundHover.play()
