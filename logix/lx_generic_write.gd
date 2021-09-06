extends LXGenericOnConnect

class_name LXGenericWrite

# TODO Alpha 3 : Get rid of this connection mess
# Each slot has special connections limits
# Nodes also have special connection rules, that modifies
# their slots
# The fact that everything is handled at the grid level is
# extremely weird and really doesn't help making the code
# clean.

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _set_output_slot(slot_idx:int, slot_def:NodeSlot):
	var used_slot_type:int
	var slot_color:Color

	if slot_def.generic == 0:
		used_slot_type = type_to_value(slot_def.logix_type)
	else:
		used_slot_type = type_to_value("IValue`1")

	slot_color = _color_for_type_value(used_slot_type)

	set_slot(slot_idx,
		false, INVALID_SLOT_TYPE, INVALID_SLOT_COLOR,
		true, used_slot_type, slot_color)
	get_child(slot_idx).set_tooltip(slot_def.logix_type)

func reconfigure_generic_slots(generic_idx:int):
	var generic_type_name:String = generic_class_names[generic_idx]

	for input_idx in generic_slots[generic_inputs][generic_idx]:
		var slot:NodeSlot = inputs[input_idx]
		slot.logix_type = generic_type_name
		_set_input_slot(input_idx, slot)

	var slot_offset:int = len(inputs)

	for output_idx in generic_slots[generic_outputs][generic_idx]:
		var slot:NodeSlot = outputs[output_idx]
		var typename:String = "IValue`1,%s" % [generic_type_name]
		var typecolor = _color_for(generic_type_name)
		slot.logix_type = typename
		# TODO Factorize if possible
		var new_slot_type:int = type_to_value("IValue`1")
		set_slot(output_idx + slot_offset,
			false, INVALID_SLOT_TYPE, INVALID_SLOT_COLOR,
			true, new_slot_type, typecolor)
		get_child(output_idx + slot_offset).set_tooltip(typename)

func _get_target_node_input_type(to_node:LXNode, to_input_idx:int) -> String:
	if to_node is LXRegister:
		# FIXME Awful hack
		return to_node.get_output_type(0)
	else:
		return ._get_target_node_input_type(to_node, to_input_idx)

func can_connect_to_output(_output_idx:int, _to_node:LXNode, _to_input_idx:int) -> bool:
	printerr(_output_idx)
	return true

