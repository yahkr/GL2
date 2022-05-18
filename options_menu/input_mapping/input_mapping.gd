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
		
		var unbind: bool
		if (event is InputEventKey and event.keycode == KEY_ESCAPE
				or event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START):
			unbind = true
		
		if selected_mapping_button.name == "KBMMappingButton":
			if unbind:
				update_mapping_button(null)
				update_input_map(action, null, KBM)
			elif get_input_type(event) == KBM:
				update_mapping_button(event)
				update_input_map(action, event, KBM)
			elif get_input_type(event) == JOYPAD:
				update_mapping_button(get_input_map(action)[KBM])
		elif selected_mapping_button.name == "ControllerMappingButton":
			if unbind:
				update_mapping_button(null)
				update_input_map(action, null, JOYPAD)
			if get_input_type(event) == KBM:
				update_mapping_button(get_input_map(action)[JOYPAD])
			elif get_input_type(event) == JOYPAD:
				update_mapping_button(event)
				update_input_map(action, event, JOYPAD)
		
		selected_mapping_button.button_pressed = false
		selected_mapping_button = null


func connect_selected_mapping_button():
	if selected_mapping_button.toggled.get_connections().size() == 0:
		selected_mapping_button.toggled.connect(toggle_action_mapping.bind(selected_mapping_button))


func get_axis_str(axis: int, axis_value: float) -> String:
	var axis_str = str(axis)
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
			if get_input_type(event) == KBM:
				input_map[KBM] = event
		
		if not input_map[JOYPAD]:
			if get_input_type(event) == JOYPAD:
				input_map[JOYPAD] = event
		
		if input_map[KBM] and input_map[JOYPAD]:
			break
	return input_map


func get_input_str(input: InputEvent) -> String:
	if input is InputEventKey:
		return OS.get_keycode_string(input.physical_keycode)
	elif input is InputEventMouseButton:
		return "Mouse_" + str(input.button_index)
	elif input is InputEventJoypadButton:
		return "Button_" + str(input.button_index)
	elif input is InputEventJoypadMotion:
		return "Axis_" + get_axis_str(input.axis, input.axis_value)
	return ""


func get_input_type(input: InputEvent) -> int:
	if input is InputEventKey or input is InputEventMouseButton:
		return KBM
	elif input is InputEventJoypadButton or input is InputEventJoypadMotion:
		return JOYPAD
	return -1


func initialize_actions():
	for action in get_node("ScrollContainer").get_node("VBoxContainer").get_children():
		if not action.is_in_group("Action"):
			continue
		
#		var events: Variant = SaveManager.get_config_value("InputMapping", action.name, null)
#
#		if events:
#			for event in events:
#				InputMap.action_add_event(action.name, event)
		
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


func update_input_map(action: String, input: InputEvent, input_type: int):
	var input_map = get_input_map(action)
	
	if input_map[input_type] and input_map[input_type].get_meta("customizable"):
		InputMap.action_erase_event(action, input_map[input_type])
	
	var option_suffix: String
	if input_type == KBM:
		option_suffix = "_kbm"
	elif input_type == JOYPAD:
		option_suffix = "_joypad"
	
	if input:
		if not InputMap.action_has_event(action, input):
			input.set_meta("customizable", true)
			InputMap.action_add_event(action, input)
		
		SaveManager.set_config_value(get_input_str(input), "InputMapping", action + option_suffix)
	else:
		SaveManager.remove_config_value("InputMapping", action + option_suffix)

func update_mapping_button(input: InputEvent):
	var input_str := get_input_str(input)
	var input_str_path := input_str.to_lower()
	
	var icon_path: String
	if get_input_type(input) == KBM:
		icon_path = prompts_prefix + "kbm/dark/" + input_str_path + prompts_suffix
	elif get_input_type(input) == JOYPAD:
		if joy_name.contains("PS3"):
			icon_path = prompts_prefix + "ps3/" + input_str_path + prompts_suffix
		elif joy_name.contains("PS4"):
			icon_path = prompts_prefix + "ps4/" + input_str_path + prompts_suffix
		elif joy_name.contains("PS5"):
			icon_path = prompts_prefix + "ps5/" + input_str_path + prompts_suffix
		elif joy_name.contains("Switch"):
			icon_path = prompts_prefix + "switch/" + input_str_path + prompts_suffix
		else:
			icon_path = prompts_prefix + "xbox/" + input_str_path + prompts_suffix
	
	
	if ResourceLoader.exists(icon_path):
		selected_mapping_button.icon = load(icon_path)
		selected_mapping_button.text = ""
	else:
		selected_mapping_button.icon = null
		selected_mapping_button.text = input_str.replace("_", " ")
