extends LXGeneric

class_name LXGenericOnConnect

var generic_slots_connections:Array = [0,0]

# TODO :
# Generalize :
# - reconfigure_generic_slots
# - generic_slots
# - generic_default_types <- Interpret from JSON

# FIXME: Factorize !
func _set_input_slot(slot_idx:int, slot_def:NodeSlot):
	var actual_type_value:int = type_to_value(slot_def.logix_type)
	var slot_color:Color = _color_for_type_value(actual_type_value)
	var used_slot_type:int = GENERIC_NODE_TYPE

	if slot_def.generic == 0:
		used_slot_type = actual_type_value

	set_slot(slot_idx, 
		true, used_slot_type, slot_color,
		false, INVALID_SLOT_TYPE, INVALID_SLOT_COLOR)
	get_child(slot_idx).set_tooltip(slot_def.logix_type)

func _set_output_slot(slot_idx:int, slot_def:NodeSlot):
	var actual_type_value:int = type_to_value(slot_def.logix_type)
	var slot_color:Color = _color_for_type_value(actual_type_value)
	var used_slot_type:int = GENERIC_NODE_TYPE

	if slot_def.generic == 0:
		used_slot_type = actual_type_value

	set_slot(slot_idx,
		false, INVALID_SLOT_TYPE, INVALID_SLOT_COLOR,
		true, used_slot_type, slot_color)
	get_child(slot_idx).set_tooltip(slot_def.logix_type)

func serialize_def() -> Dictionary:
	var main_def:Dictionary = .serialize_def()
	main_def["type"] = "GenericOnConnect"
	return main_def

func set_generic_slot_type(generic_idx:int, type_name:String):
	_set_generic_type(generic_idx, type_name)
	reconfigure_generic_slots(generic_idx)

func _increase_generic_slots_connection(generic_idx:int, type_name:String):
	generic_slots_connections[generic_idx] += 1
	if generic_slots_connections[generic_idx] == 1:
		set_generic_slot_type(generic_idx, type_name)

func connecting_input(input_idx:int, from_node:LXNode, from_output_idx:int) -> void:
	var generic_idx:int = inputs[input_idx].generic - 1
	if generic_idx >= 0:
		var from_type:String = from_node.get_output_type(from_output_idx)
		_increase_generic_slots_connection(generic_idx, from_type)

func connecting_output(output_idx:int, to_node:LXNode, to_input_idx:int) -> void:
	var generic_idx:int = outputs[output_idx].generic - 1
	if generic_idx >= 0:
		var to_type:String = to_node.get_input_type(output_idx)
		_increase_generic_slots_connection(generic_idx, to_type)

func _decrease_generic_slots_connection(generic_idx:int):
	generic_slots_connections[generic_idx] -= 1
	if generic_slots_connections[generic_idx] == 0:
		set_generic_slot_type(generic_idx, generic_default_types[generic_idx])

func disconnecting_input(input_idx:int) -> void:
	var generic_idx:int = inputs[input_idx].generic - 1
	if generic_idx >= 0:
		_decrease_generic_slots_connection(generic_idx)

func disconnecting_output(output_idx:int) -> void:
	var generic_idx:int = outputs[output_idx].generic - 1
	if generic_idx >= 0:
		_decrease_generic_slots_connection(generic_idx)


