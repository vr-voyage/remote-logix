extends Control

class_name NodeSlot

var title:String
var logix_type:String

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
	return true

#static func from_serialized_def(serialized_slot:Dictionary) -> NodeSlot:
#	if not serialized_slot.has("name") or not serialized_slot.has("type"):
#		printerr(
#			"Missing the fields name and type in the following " +
#			"serialized field :\n" +
#			str(serialized_slot))
#		return null
#	return NodeSlot.new(serialized_slot["name"], serialized_slot["type"])

func serialize_def() -> Dictionary:
	return {"name": title, "type": logix_type}
