extends LXGeneric

class_name LXGenericWithMenu

var generic_menu = preload("res://nodes_parts/generic_types_menu.tscn")
var menu_types:Array = Array()

const generic_menu_name:String = "GenericMenu"

signal recheck_connections(node)

func configure_from_serialized(serialized_node:Dictionary) -> bool:
	if not .configure_from_serialized(serialized_node):
		return false

	var serialized_generic_conf:Dictionary = serialized_node["generic"]

	if not serialized_generic_conf.has("menu"):
		_report_faulty_conf(
			serialized_node,
			"[BUG] Configuring a generic with type definition from menu " +
			"without specifiying a menu !")
		return false

	if not serialized_generic_conf["menu"] is Array:
		_report_faulty_conf(
			serialized_node, "[BUG] generic -> menu MUST be an array !")
		return false

	self.menu_types = serialized_node["generic"]["menu"]
	add_types_menu()
	reconfigure_generic_slots(0)
	return true

func setup_generic_types_list(types:PoolStringArray):
	get_node("GenericMenu").setup_menu(types)

func _cb_selected_generic_type_from_menu(type_name:String):
	printerr("Called ?")
	_set_generic_type(0, type_name)
	reconfigure_generic_slots(0)
	emit_signal("recheck_connections", self)

func complete_dup():
	var n = .complete_dup()
	n.menu_types = menu_types
	n.generic_menu = generic_menu
	n._connect_menu()
	return n

func _connect_menu():
	var menu = get_node("GenericMenu")
	if menu != null:
		menu.connect("type_defined", self, "_cb_selected_generic_type_from_menu")
	else:
		printerr("Meep ! Menu is null !")

func add_types_menu():
	var menu = generic_menu.instance()
	menu.name = generic_menu_name
	add_child(menu)
	menu.setup_menu(menu_types, generic_class_names[0])
	menu.connect("type_defined", self, "_cb_selected_generic_type_from_menu")

func get_logix_class_full_name():
	var selected_type:String = get_node(generic_menu_name).get_selected_type_name()
	var actual_csharp_name:String = _get_csharp_class_name_for(selected_type)
	return logix_class_name + "," + actual_csharp_name

func serialize_def() -> Dictionary:
	var main_conf:Dictionary = .serialize_def()
	main_conf["generic"]["menu"] = self.menu_types
	main_conf["type"]    = "GenericWithMenu"
	return main_conf

