extends Control


enum { KBM, JOYPAD }

const axis_deadzone = 0.5
const prompts_prefix = "res://options_menu/input_mapping/prompts/"
const prompts_suffix = ".png"

var joy_name: String
var selected_mapping_button: Button


func _ready():
	if Input.get_connected_joypads().size() > 0:
		joy_name = Input.get_joy_name(0)
	else:
		joy_name = "Joypad"
	
	initialize_actions()



func _input(event):
	if not selected_mapping_button:
		return
	
	if event.is_pressed():
		accept_event()
		
		var action = selected_mapping_button.get_parent().get_parent().name
		
		if selected_mapping_button.name == "ControllerMappingButton":
			if is_joypad_event(event):
				update_mapping_button(event)
				update_input_map(action, event, JOYPAD)
			else:
				update_mapping_button(get_input_map(action)[JOYPAD])
		else:
			if event is InputEventKey and event.keycode == KEY_ESCAPE or is_joypad_event(event):
				update_mapping_button(get_input_map(action)[KBM])
			else:
				update_mapping_button(event)
				update_input_map(action, event, KBM)
		
		selected_mapping_button.button_pressed = false
		selected_mapping_button = null


func connect_selected_mapping_button():
	if selected_mapping_button.toggled.get_connections().size() == 0:
		selected_mapping_button.toggled.connect(toggle_action_mapping.bind(selected_mapping_button))


func get_axis_str(axis: int, axis_value: float) -> String:
	var axis_str = "axis/" + str(axis)
	if axis_value > 0:
		axis_str += "+"
	elif axis_value < 0:
		axis_str += "-"
	return axis_str


func get_input_map(action: String) -> Array:
	var input_map = [null, null]
	
	var events := InputMap.action_get_events(action)
	
	for i in events.size():
		var event: InputEvent = events[-i-1]
		
		if not input_map[KBM]:
			if not is_joypad_event(event):
				input_map[KBM] = event
		
		if not input_map[JOYPAD]:
			if is_joypad_event(event):
				input_map[JOYPAD] = event
		
		if input_map[KBM] and input_map[JOYPAD]:
			break
	return input_map


func initialize_actions():
	for action in get_children():
		if not action.is_in_group("Action"):
			continue
		
		var events: Variant = SaveManager.get_config_value("InputMapping", action.name, null)
		
		if events:
			for event in events:
				InputMap.action_add_event(action.name, event)
		
		var hbox := action.get_node("HBoxContainer")
		
		var action_label := hbox.get_node("Action")
		action_label.text = tr(action.name)
		
		## If multiple inputs are bound to an input type (KBM or Joypad),
		## then the last input mapping of that input type will be used.
		var input_map = get_input_map(action.name)
		
		selected_mapping_button = hbox.get_node("KBMMappingButton")
		connect_selected_mapping_button()
		if input_map[KBM]:
			input_map[KBM].set_meta("customizable", true)
			update_mapping_button(input_map[KBM])
		
		selected_mapping_button = hbox.get_node("ControllerMappingButton")
		connect_selected_mapping_button()
		if input_map[JOYPAD]:
			input_map[JOYPAD].set_meta("customizable", true)
			update_mapping_button(input_map[JOYPAD])
		
		selected_mapping_button = null


func is_joypad_event(event: InputEvent):
	return event is InputEventJoypadButton or event is InputEventJoypadMotion


func restore_defaults():
	InputMap.load_from_project_settings()
	for button in get_tree().get_nodes_in_group("MappingButton"):
		button.icon = null
		button.text = ""
	initialize_actions()


func toggle_action_mapping(button_pressed: bool, mapping_button: Button):
	for button in get_tree().get_nodes_in_group("MappingButton"):
		button.disabled = button_pressed and button != mapping_button
	
	if button_pressed:
		selected_mapping_button = mapping_button
		
		mapping_button.icon = null
		mapping_button.text = "Press any button..."
		mapping_button.disabled = false


func update_input_map(action: String, event: InputEvent, input_type: int):
	var input_map = get_input_map(action)
	
	if input_map[input_type] and input_map[input_type].get_meta("customizable"):
		InputMap.action_erase_event(action, input_map[input_type])
	
	if not InputMap.action_has_event(action, event):
		event.set_meta("customizable", true)
	InputMap.action_add_event(action, event)
	
	SaveManager.set_config_value(InputMap.action_get_events(action), "InputMapping", action)

func update_mapping_button(input: InputEvent):
	var kbm: String
	var joypad: String
	if input is InputEventKey:
		var physical_keycode: int = input.physical_keycode
		var keycode := DisplayServer.keyboard_get_keycode_from_physical(physical_keycode)
		kbm = OS.get_keycode_string(keycode)
	elif input is InputEventMouseButton:
		kbm = "mouse_" + str(input.button_index)
	elif input is InputEventJoypadButton:
		joypad = str(input.button_index)
	elif input is InputEventJoypadMotion:
		joypad = get_axis_str(input.axis, input.axis_value)
	
	var icon_path: String
	if kbm:
		icon_path = prompts_prefix + "kbm/dark/" + kbm.to_lower() + "_key_dark" + prompts_suffix
	elif joypad:
		if joy_name.contains("PS3"):
			icon_path = prompts_prefix + "ps3/" + joypad + prompts_suffix
		elif joy_name.contains("PS4"):
			icon_path = prompts_prefix + "ps4/" + joypad + prompts_suffix
		elif joy_name.contains("PS5"):
			icon_path = prompts_prefix + "ps5/" + joypad + prompts_suffix
		elif joy_name.contains("Switch"):
			icon_path = prompts_prefix + "switch/" + joypad + prompts_suffix
		else:
			icon_path = prompts_prefix + "xbox/" + joypad + prompts_suffix
	
	if ResourceLoader.exists(icon_path):
		selected_mapping_button.icon = load(icon_path)
		selected_mapping_button.text = ""
	else:
		selected_mapping_button.icon = null
		selected_mapping_button.text = kbm + joypad
