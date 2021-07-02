extends "lxnode.gd"

class_name LXConstValue

# FIXME That's a horrendous hack, just to have constant
# value support ASAP.
# That said, trying to handle this with a 'value'
# next to the field name is tricky.
# Understand that, for each constant value defined,
# you need a corresponding 'Input' nodes in LogiX.
# So if I automatically do something like
#
#   _______________
#  | Add_Int       |
#  |---------------|
#  |* A [___0]     |
#  |* B [___0]     |
#  |           C * |
#  |_______________|
#
# I'll have to generate two input nodes for the
# default values, unless I add a special 'Edit'
# icon for editing and ony generate Input values
# if the icon is checked.
# Knowing that I still should handle direct input
# correctly...
#
# This is the kind of stuff where I'd prefer to start
# hacking the Visual Shader editor instead, since it
# already has support for that kind of things.
# However, that would require the ability to use that
# editor 'in-game'.
# 
# This might be done for the next version. Meanwhile,
# dirty hacks !

# Emulating LogiX const output nodes, which only
# have ONE output
# At the moment, no check is performed on the inputs
# which accept any kind of strings.
#
# Afternotes:
# I should have gone the 'additional fields' way
# instead of creating a new class, this just generate
# much more issues for zero gain.


var editor_grid_size:Vector2 = Vector2(1,1)

const DEFAULT_SLOT_NUMBER = 0

static func _can_become_const_input(node:Node) -> bool:
	if not node is LXNode:
		return false
	var logix_node:LXNode = node
	return (len(logix_node.inputs) == 0) and (len(logix_node.outputs) == 1)

func _copy_from_lxnode(logix_node:LXNode) -> bool:
	if not _can_become_const_input(logix_node):
		printerr("Node " + str(logix_node) + " cannot become a const value node")
		return false

	set_io(logix_node.inputs, logix_node.outputs)
	set_class_name(logix_node.logix_class_name)
	return true

func _to_lxnode() -> LXNode:
	var new_node:LXNode = LXNode.new()
	new_node.set_io(self.inputs, self.outputs)
	new_node.set_class_name(self.logix_class_name)
	return new_node

func configure_from_serialized(serialized_node:Dictionary) -> bool:
	if not serialized_node.has("editor_grid_size"):
		printerr(
			"Missing additional fields in serialized const input definition :\n" +
			"editor_grid_size.\n" +
			"Definition :" + str(serialized_node))
		return false
	if not .configure_from_serialized(serialized_node):
		return false
	editor_grid_size = Vector2(
		serialized_node["editor_grid_size"][0],
		serialized_node["editor_grid_size"][1])
	refresh_slots_style()
	return true

func serialize_def() -> Dictionary:
	var main_dic:Dictionary = .serialize_def()
	main_dic["editor_grid_size"] = [editor_grid_size.x, editor_grid_size.y]
	main_dic["type"]             = "ConstValue"
	return main_dic

func _generate_user_inputs() -> Node:
	var input_grid:GridContainer = GridContainer.new()
	var n_columns:int = editor_grid_size.y as int
	var n_inputs:int  = (editor_grid_size.x * editor_grid_size.y) as int
	printerr(
		"[_generate_user_inputs]\n"     +
		"  Columns : " + str(n_columns) +
		"  Inputs  : " + str(n_inputs))
	input_grid.columns = n_columns
	for i in range(0, n_inputs):
		# FIXME Create templates and use them here
		# instead of setting everything manually
		var line_edit:LineEdit = LineEdit.new()
		line_edit.expand_to_text_length = true
		line_edit.rect_min_size = Vector2(48,16)
		input_grid.add_child(line_edit)
	return input_grid

func _generate_output_slot_node() -> Node:
	var container:HBoxContainer = HBoxContainer.new()
	var output_label:Label      = Label.new()
	output_label.text           = outputs[0].title
	container.add_child(_generate_user_inputs())
	container.add_child(output_label)
	return container

func _get_input_values_node() -> Node:
	# FIXME Horrendous. Use a path instead ?
	# To use paths correctly, templates are clearly
	# needed.
	return get_child(0).get_child(0) # HBoxContainer/GridContainer

func _get_input_values() -> PoolStringArray:
	var values:PoolStringArray = PoolStringArray()
	for child in _get_input_values_node().get_children():
		if not child is LineEdit:
			printerr("Not parsing value from : " + str(child))
			continue
		var line_edit:LineEdit = child
		values.append(line_edit.text)
	return values

func get_values() -> PoolStringArray:
	return _get_input_values()

func _regenerate_slots() -> void:
	if (len(outputs) == 0):
		printerr("[BUG] No outputs defined for the constant value")
		return

	var constant_type:int = LXNode.type_to_value(outputs[0].logix_type)
	set_slot(DEFAULT_SLOT_NUMBER,
		false, INVALID_SLOT_TYPE, INVALID_SLOT_COLOR,
		true, constant_type, _color_for_type_value(constant_type))

	for child in get_children():
		remove_child(child)

	add_child(_generate_output_slot_node())

func set_values(values:PoolStringArray):
	var i = 0
	for child in _get_input_values_node().get_children():
		if child is LineEdit:
			if i < len(values):
				child.text = values[i]
			else:
				printerr("Not enough values for the fields !")
				return
