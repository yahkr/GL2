extends Node


@onready var config = ConfigFile.new()


func _ready():
	config.load("user://options.cfg")


func get_config_value(tab: StringName, option: StringName, default_value: Variant) -> Variant:
	if not config.has_section_key(tab, option):
		config.set_value(tab, option, default_value)
	return config.get_value(tab, option)


func set_config_value(new_value: Variant, tab: StringName, option: StringName):
	config.set_value(tab, option, new_value)
	save_config_file()


func save_config_file():
	config.save("user://options.cfg")
