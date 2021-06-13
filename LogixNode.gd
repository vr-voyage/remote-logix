extends GraphNode

var inputs:Array = Array()

export(PoolStringArray) var input_names;

func get_input_name(var idx:int) -> String:
	if idx < len(input_names):
		return input_names[idx]
	return ""

func set_input_connection(
	slot_number:int,
	graph_node:GraphNode, 
	graph_node_output_slot:int):

	if len(inputs) <= slot_number:
		inputs.resize(slot_number+1)

	inputs[slot_number] = {
		"from_name": graph_node.name,
		"output": graph_node_output_slot
	}

func remove_connection(slot_number:int):
	inputs[slot_number] = null
