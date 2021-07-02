extends LXNode

class_name LXGenericOnConnect

var generic_slots_connections:Array = [0,0]

# TODO :
# Generalize :
# - reconfigure_generic_slots
# - generic_slots
# - generic_default_types <- Interpret from JSON

func set_generic_slot_type(generic_idx:int, type_name:String):
	pass

func _increase_generic_slots_connection(generic_idx:int, type_name:String):
	generic_slots_connections[generic_idx] += 1
	if generic_slots_connections[generic_idx] == 1:
		set_generic_slot_type(generic_idx, type_name)

func _on_input_connection(input_idx:int, from_node:LXNode, from_output_idx:int) -> bool:
	var generic_idx:int = inputs[input_idx].generic - 1
	if generic_idx >= 0:
		var from_type:String = from_node.get_output_type(from_output_idx)
		_increase_generic_slots_connection(generic_idx, from_type)
	return true

func _on_output_connection(output_idx:int, to_node:LXNode, to_input_idx:int) -> bool:
	var generic_idx:int = outputs[output_idx].generic - 1
	if generic_idx >= 0:
		var to_type:String = to_node.get_input_type(output_idx)
		_increase_generic_slots_connection(generic_idx, to_type)
	return true

func _decrease_generic_slots_connection(generic_idx:int):
	generic_slots_connections[generic_idx] -= 1
	if generic_slots_connections[generic_idx] == 0:
		set_generic_slot_type(generic_idx, generic_class_names[generic_idx])

func _on_input_disconnect(input_idx:int):
	var generic_idx:int = inputs[input_idx].generic - 1
	if generic_idx >= 0:
		_decrease_generic_slots_connection(generic_idx)
	return true

func _on_output_disconnect(output_idx:int):
	var generic_idx:int = outputs[output_idx].generic - 1
	if generic_idx >= 0:
		_decrease_generic_slots_connection(generic_idx)
	return true
