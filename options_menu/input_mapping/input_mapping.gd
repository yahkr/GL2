extends Control


const axis_deadzone = 0.5

const prompts_prefix = "res://options_menu/input_mapping/prompts/%s/"
const prompts_suffix = ".png"

const kbm_prompts_prefix = prompts_prefix % "kbm/dark"
const kbm_prompts_suffix = "_key_dark.png"

const ps3_prompts_prefix = prompts_prefix % "ps3"

const ps4_prompts_prefix = prompts_prefix % "ps4"

const ps5_prompts_prefix = prompts_prefix % "ps5"

const switch_prompts_prefix = prompts_prefix % "switch"

const xbox_prompts_prefix = prompts_prefix % "xbox"

var axis_mapped: bool
var joy_name: String
var selected_action_button: Button


func _ready():
	for control in get_children():
		if not control is Panel:
			continue
		
		var hbox := control.get_node("HBoxContainer")
		
		var action_label := hbox.get_node("Action")
		action_label.text = tr(control.name)
		
		var action_button_kbm := hbox.get_node("KBMActionButton")
		update_action_button(action_button_kbm, get_first_mapping(control.name))
		action_button_kbm.toggled.connect(toggle_action_remap.bind(action_button_kbm))
		
		if Input.get_connected_joypads().size() > 0:
			joy_name = Input.get_joy_name(0)
		else:
			joy_name = "Joypad"
		
		var action_button_controller := hbox.get_node("ControllerActionButton")
		update_action_button(action_button_controller, get_first_mapping(control.name, true), true)
		action_button_controller.toggled.connect(toggle_action_remap.bind(action_button_controller))


func _input(event):
	if not selected_action_button:
		return
	
	if event is InputEventJoypadButton:
		if event.pressed:
			accept_event()
			
			joy_name = Input.get_joy_name(event.device)
			
			update_action_button(selected_action_button, event.button_index, true)
		else:
			selected_action_button.button_pressed = false
			selected_action_button = null
			axis_mapped = false
	elif event is InputEventJoypadMotion:
		joy_name = Input.get_joy_name(event.device)
		var axis_str := "axis/"
		
		var largest_axis := 0
		var largest_axis_value := 0.0
		for i in range(6):
			var axis_value := Input.get_joy_axis(event.device, i)
			if abs(axis_value) > abs(largest_axis_value):
				largest_axis = i
				largest_axis_value = axis_value
		
		axis_str += str(largest_axis)
		
		if largest_axis_value > axis_deadzone:
			axis_str += "+"
			axis_mapped = true
		elif largest_axis_value < -axis_deadzone:
			axis_str += "-"
			axis_mapped = true
		else:
			if axis_mapped:
				selected_action_button.button_pressed = false
				selected_action_button = null
				axis_mapped = false
			return
		
		update_action_button(selected_action_button, largest_axis, true, axis_str)
	elif event is InputEventKey:
		if event.pressed:
			if event.echo:
				return
			
			accept_event()
			
			var action_name = selected_action_button.get_parent().get_parent().name
			
			for mapping in InputMap.action_get_events(action_name):
				if mapping is InputEventKey:
					InputMap.action_erase_event(action_name, mapping)
			
			InputMap.action_add_event(action_name, event)
		
			update_action_button(selected_action_button, event.keycode)
		else:
			selected_action_button.button_pressed = false
			selected_action_button = null
			axis_mapped = false


func get_first_mapping(action: String, joypad := false) -> int:
	for mapping in InputMap.action_get_events(action):
			if joypad:
				if mapping is InputEventJoypadButton:
					return mapping.button_index
			elif mapping is InputEventKey:
				var physical_keycode: int = mapping.physical_keycode
				var keycode := DisplayServer.keyboard_get_keycode_from_physical(physical_keycode)
				return keycode
	return 0


func toggle_action_remap(button_pressed: bool, action_button: Button):
	selected_action_button = action_button
	
	for button in get_tree().get_nodes_in_group("ActionButton"):
		button.disabled = button_pressed and button != action_button
	
	if button_pressed:
		action_button.icon = null
		action_button.text = "Press any button..."
		action_button.disabled = false


func update_action_button(action_button: Button, button: int, joypad := false, axis_str := ""):
	var button_name: String
	
	if joypad:
		if axis_str.is_empty():
			button_name = str(button)
		else:
			button_name = str(axis_str)
		
		if joy_name.contains("PS3"):
			action_button.icon = load(ps3_prompts_prefix + button_name + prompts_suffix)
		elif joy_name.contains("PS4"):
			action_button.icon = load(ps4_prompts_prefix + button_name + prompts_suffix)
		elif joy_name.contains("PS5"):
			action_button.icon = load(ps5_prompts_prefix + button_name + prompts_suffix)
		elif joy_name.contains("Switch"):
			action_button.icon = load(switch_prompts_prefix + button_name + prompts_suffix)
		else:
			action_button.icon = load(xbox_prompts_prefix + button_name + prompts_suffix)
	else:
		button_name = OS.get_keycode_string(button)
		action_button.icon = load(kbm_prompts_prefix + button_name.to_lower() + kbm_prompts_suffix)
	
	if action_button.icon == null:
		action_button.text = button_name
	else:
		action_button.text = ""
