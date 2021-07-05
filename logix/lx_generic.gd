extends LXNode

class_name LXGeneric

var generic_default_types = ["",""]
var generic_slots  = [[[],[]],[[],[]]]
const generic_inputs:int = 0
const generic_outputs:int = 1


func complete_dup():
	var n = .complete_dup()
	n.generic_slots = generic_slots
	n.generic_default_types = generic_default_types.duplicate()
	return n

func _set_generic_type(generic_idx:int, type_name:String):
	if generic_idx < 0 or generic_idx >= len(generic_class_names):
		printerr(
			"[BUG] generic_idx %d is out of bounds (max : %d)" %
			[generic_idx, len(generic_class_names)])
		return
	generic_class_names[generic_idx] = type_name

func reconfigure_generic_slots(generic_idx:int):
	for input_idx in generic_slots[generic_inputs][generic_idx]:
		var slot:NodeSlot = inputs[input_idx]
		slot.logix_type = generic_class_names[generic_idx]
		_set_input_slot(input_idx, slot)
	var slot_offset:int = len(inputs)
	for output_idx in generic_slots[generic_outputs][generic_idx]:
		var slot:NodeSlot = outputs[output_idx]
		slot.logix_type = generic_class_names[generic_idx]
		_set_output_slot(slot_offset + output_idx, slot)

func _register_and_duplicate_generic_slots(slots_list:Array, out_list:Array):
	for i in range(0,len(slots_list)):
		if slots_list[i].generic == 1:
			var original_slot:NodeSlot = slots_list[i]
			slots_list[i] = original_slot.complete_dup()
			out_list.append(i)

func set_io(new_inputs:Array, new_outputs: Array):
	printerr("[lx_generic_with_menu] Calling set_io from generic")
	var generic_idx:int = 0

	_register_and_duplicate_generic_slots(
		new_inputs, generic_slots[generic_inputs][generic_idx])
	_register_and_duplicate_generic_slots(
		new_outputs, generic_slots[generic_outputs][generic_idx])
	#for i in range(0,len(new_inputs)):
	#	if new_inputs[i].generic == 1:
	#		var original_slot:NodeSlot = new_inputs[i]
	#		var cloned_slot:NodeSlot   = original_slot.complete_dup()
	#		new_inputs[i] = cloned_slot
	#		generic_slots[0][0].append(i)
	#for i in range(0,len(new_outputs)):
	#	if new_outputs[i].generic == 1:
	#		generic_slots[0][1].append(i)
	.set_io(new_inputs, new_outputs)

func serialize_def() -> Dictionary:
	var main_def:Dictionary = .serialize_def()
	main_def["generic"] = {
		"default_types": generic_default_types
	}
	return main_def

func _report_faulty_conf(serialized_node:Dictionary, msg:String):
	printerr(msg)
	printerr("Configuration was : %s" % [to_json(serialized_node)])

func configure_from_serialized(serialized_node:Dictionary) -> bool:
	if not .configure_from_serialized(serialized_node):
		return false

	if not serialized_node.has("generic"):
		_report_faulty_conf(
			serialized_node,
			"[BUG] Generic node configuration without a 'generic' section")
		return false

	var serialized_generic_conf:Dictionary = serialized_node["generic"] as Dictionary
	if serialized_generic_conf == null:
		_report_faulty_conf(
			serialized_node,
			"[BUG] Expected a JSON object for 'generic' !")
		return false

	if not serialized_generic_conf.has("default_types"):
		_report_faulty_conf(
			serialized_node,
			"[BUG] Expected a definition of the default types for this " +
			"generic.\n")
		return false

	var default_types:Array = serialized_generic_conf["default_types"] as Array
	if default_types == null:
		_report_faulty_conf(
			serialized_node,
			"[BUG] Expected generic -> default_types to be an Array")
		return false

	self.generic_default_types = default_types
	# Let's avoid sharing the same reference object
	self.generic_class_names   = generic_class_names.duplicate()
	return true
