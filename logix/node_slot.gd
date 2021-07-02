extends Control

class_name NodeSlot

var title:String
var logix_type:String
var generic:int = 0
onready var default_type:String = logix_type

func _setup(node_title:String, node_type:String):
	title = node_title
	logix_type = node_type

func _init(node_title:String, node_type:String):
	_setup(node_title, node_type)

func config_from_serialized(serialized_slot:Dictionary) -> bool:
	if not serialized_slot.has("name") or not serialized_slot.has("type"):
		printerr(
			"Missing the fields name and type in the following " +
			"serialized field :\n" +
			str(serialized_slot))
		return false
	_setup(serialized_slot["name"], serialized_slot["type"])
	if serialized_slot.has("generic"):
		self.generic = int(serialized_slot["generic"])
	return true

func serialize_def() -> Dictionary:
	var conf:Dictionary = {"name": title, "type": logix_type}
	if generic >= 0:
		conf["generic"] = generic
	return conf
