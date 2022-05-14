extends Control


@onready var vbox = $VBoxContainer

#enum AntiAliasing {DISABLED, FXAA, MSAA}
#
#const FSR = {
#	DISABLED = 0,
#	ULTRA_QUALITY = 0.77,
#	QUALITY = 0.67,
#	BALANCED = 0.59,
#	PERFORMANCE = 0.5,
#}
#
#const gameplay_options = {
#	"mouse_sensitivity": 0.1,
#	"controller_sensitivity_x": 0.01,
#	"controller_sensitivity_y": 0.01,
#}
#
#const video_options = {
#	"3d_scale": 1,
#	"antialiasing": AntiAliasing.FXAA,
#	"bloom": true,
#	"brightness": 1,
#	"fov": 90,
#	"fsr": FSR.DISABLED,
#	"fullscreen": true,
#	"max_fps": 0,
#	"show_fps": false,
#	"vsync": true,
#}
#
#const audio_options = {
#	"volume_master": 1,
#	"volume_sfx": 1,
#	"volume_music": 1,
#	"volume_dialog": 1,
#}


func add_option(tab: String, resource: Resource, config_value: Variant):
	var hbox := HBoxContainer.new()
	
	var resource_name_label := Label.new()
	resource_name_label.text = tr(resource.resource_name)
	resource_name_label.size_flags_horizontal = SIZE_EXPAND_FILL
	resource_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(resource_name_label)
	
	var value_label := Label.new()
	value_label.size_flags_horizontal = SIZE_EXPAND_FILL
	
	if resource is SliderOption:
		update_value_label(config_value, value_label)

		var slider := HSlider.new()
		slider.minimum_size.x = 400
		slider.min_value = resource.min_value
		slider.max_value = resource.max_value
		slider.step = resource.step
		slider.ticks_on_borders = true
		slider.tick_count = 20
		slider.value = config_value
		
		slider.value_changed.connect(SaveManager.save_changed_option.bind(tab, resource))
		slider.value_changed.connect(update_value_label.bind(value_label))
		
		hbox.add_child(slider)
	elif resource is CheckboxOption:
		var checkbox := CheckBox.new()
		checkbox.button_pressed = config_value
		update_value_label(config_value, checkbox)
		
		checkbox.toggled.connect(update_value_label.bind(checkbox))
		hbox.add_child(checkbox)
	
	hbox.add_child(value_label)
	vbox.add_child(hbox)


func update_value_label(value: Variant, value_label: Control):
	if value is float:
		value_label.text = "%.2f" % value
	elif value is bool:
		value_label.text = "Enabled" if value else "Disabled"


func initialize_options(path):
	var dir = Directory.new()
	if dir.open(path) == OK:
		for tab in dir.get_directories():
			print(tab)
			$"%TabBar".add_tab(tr(tab))
			if dir.open(path + tab) == OK:
				for resource_name in dir.get_files():
					var resource = load(path + tab + "/" + resource_name)
					resource.resource_name = resource_name.trim_suffix(".tres")
					var config_value = SaveManager.get_config_value(tab, resource)
					add_option(tab, resource, config_value)
	SaveManager.save_config_file()


func _ready():
	initialize_options("res://options/option_resources/")


func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		visible = !visible
		get_tree().paused = visible
		if visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


#func _on_mouse_sensitivity_slider_value_changed(value):
#	$"%MouseSensitivityValue".text = "%.2f" % value
#	emit_signal("option_changed", "Gameplay", "mouse_sensitivity", value / 100)
#
#
#func _on_horizontal_controller_sensitivity_slider_value_changed(value):
#	$"%HorizontalControllerSensitivityValue".text = "%.2f" % value
#	emit_signal("option_changed", "Gameplay", "controller_sensitivity_x", value / 10)
#
#
#func _on_vertical_controller_sensitivity_slider_value_changed(value):
#	$"%VerticalControllerSensitivityValue".text = "%.2f" % value
#	emit_signal("option_changed", "Gameplay", "controller_sensitivity_y", value / 10)


func _on_tab_bar_tab_changed(tab):
	for i in range($"%TabBar".tab_count):
		$VBoxContainer.get_child(tab).visible = tab == i
