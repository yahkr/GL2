extends Node


@onready var config = ConfigFile.new()


func _ready():
	config.load("user://options.cfg")


func get_config_value(tab: String, resource: Resource) -> Variant:
	if not config.has_section_key(tab, resource.resource_name):
		config.set_value(tab, resource.resource_name, resource.value)
	return config.get_value(tab, resource.resource_name, resource.value)


func save_config_file():
	config.save("user://options.cfg")


func save_changed_option(new_value: Variant, tab: String, resource: Resource):
	config.set_value(tab, resource.resource_name, new_value)
	save_config_file()
