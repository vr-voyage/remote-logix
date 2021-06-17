extends Control

onready var graph:GraphEdit = $"TabContainer/Maincontainer/Program"

export(NodePath) var path_editor_slots_types
onready var ui_slot_types_option:OptionButton = get_node(path_editor_slots_types)

export(NodePath) var path_editor_node_slot_name
onready var ui_edited_node_slot_name = get_node(path_editor_node_slot_name)

export(NodePath) var path_editor_nodes_list_option
onready var ui_nodes_list_option:OptionButton = get_node(path_editor_nodes_list_option)

export(NodePath) var path_editor_node_class_name_input
onready var ui_edited_node_class_name_input = get_node(path_editor_node_class_name_input)

export(NodePath) var path_editor_inputs_slots_list
onready var ui_edited_node_slots_input_list:ItemList = get_node(path_editor_inputs_slots_list)

export(NodePath) var path_editor_outputs_slots_list
onready var ui_edited_node_slots_output_list:ItemList = get_node(path_editor_outputs_slots_list)

export(NodePath) var path_save_button
onready var ui_save_button = get_node(path_save_button)

export(NodePath) var path_popup_menu
onready var ui_popup_menu:PopupMenu = get_node(path_popup_menu)

export(NodePath) var path_program_name_input
onready var ui_program_name_text:LineEdit = get_node(path_program_name_input)

export(NodePath) var path_editor_types_list
onready var ui_type_editor_list:ItemList = get_node(path_editor_types_list)

export(NodePath) var path_edited_type_name
onready var ui_edited_type_name:LineEdit = get_node(path_edited_type_name)

export(NodePath) var path_edited_type_color
onready var ui_edited_type_color:ColorPicker = get_node(path_edited_type_color)

export(String) var save_filepath = "user://definitions.json"
export(String) var definitions_filepath = "user://meow.json"

var useable_nodes:LXNodeDefs = LXNodeDefs.new()

class NodeSlot:
	var title:String
	var logix_type:String

	func _init(node_title:String, node_type:String):
		title = node_title
		logix_type = node_type

	static func from_serialized_def(serialized_slot:Dictionary) -> NodeSlot:
		if not serialized_slot.has("name") or not serialized_slot.has("type"):
			printerr(
				"Missing the fields name and type in the following " +
				"serialized field :\n" +
				str(serialized_slot))
			return null
		return NodeSlot.new(serialized_slot["name"], serialized_slot["type"])

	func serialize_def() -> Dictionary:
		return {"name": title, "type": logix_type}

class LXNode extends GraphNode:
	var logix_class_name:String = ""
	var inputs:Array = Array()
	var outputs:Array = Array()
	
	const INVALID_NODE_ID:int = 0
	# Do NOT duplicate this value
	var node_id:int = INVALID_NODE_ID

	func _generate_default_node_id():
		node_id = self.name.hash()

	func get_node_id() -> int:
		if node_id == INVALID_NODE_ID:
			_generate_default_node_id()
		return node_id

	# Why PoolStringArray don't have 'find' ?
	const TYPES:Array = ["", "Impulse", "Int", "Float", "Bool"]
	const logix_types_colors:Array = [
		Color(0,0,0,0),
		Color(1,1,1,1),
		Color(0,1,0,1),
		Color(0,0,1,0),
		Color(0.3,0.3,0.3,1)
	]

	static func add_logix_type(type_name:String, type_color:Color) -> int:
		var added_idx:int = len(TYPES)
		TYPES.append(type_name)
		logix_types_colors.append(type_color)
		return added_idx

	static func _add_default_type():
		add_logix_type("", Color(0,0,0,0))

	static func _reset_types():
		TYPES.clear()
		logix_types_colors.clear()
		_add_default_type()

	static func _valid_edit_type_idx(type_idx:int):
		return (0 < type_idx and type_idx < len(TYPES))

	static func change_type_idx_name(type_idx:int, new_name:String) -> bool:
		var valid_idx = _valid_edit_type_idx(type_idx)
		if valid_idx:
			TYPES[type_idx] = new_name
		return valid_idx

	static func change_type_idx_color(type_idx:int, new_color:Color) -> bool:
		var valid_idx = _valid_edit_type_idx(type_idx)
		if valid_idx:
			logix_types_colors[type_idx] = new_color
		return valid_idx

	static func _serialize_color(color:Color) -> String:
		return color.to_html()

	static func _color_from_serialized(val:String) -> Color:
		return Color(val)

	static func types_serialize_defs() -> Array:
		var ret:Array = []
		# 0 is reserved for the 'unknown' type
		for i in range(1, len(TYPES)):
			var serialized_color:String = _serialize_color(logix_types_colors[i])
			ret.append({"name": TYPES[i], "color": serialized_color})
		return ret

	static func _sort_serialized_types_by_names(serialized_type_a, serialized_type_b) -> bool:
		return serialized_type_a["name"] < serialized_type_b["name"]

	static func types_setup_from_serialized(serialized:Array):
		_reset_types()
		serialized.sort_custom(LXNode, "_sort_serialized_types_by_names")
		for element in serialized:
			add_logix_type(
				element["name"],
				_color_from_serialized(element["color"]))

	static func type_to_value(type_name:String) -> int:
		return TYPES.find(type_name)

	static func _valid_type_idx(type_idx:int) -> bool:
		return 0 <= type_idx and type_idx < len(TYPES)

	static func _type_name(logix_type:int) -> String:
		var logix_type_name:String = (
			TYPES[logix_type] 
			if _valid_type_idx(logix_type)
			else TYPES[0])
		return logix_type_name

	static func _clamp_type_idx(logix_type:int) -> int:
		if _valid_type_idx(logix_type):
			return logix_type
		printerr("Unknown type : " + str(logix_type))
		return 0

	static func _color_for_idx(logix_type_idx:int) -> Color:
		return logix_types_colors[_clamp_type_idx(logix_type_idx)]

	static func _color_for(logix_type_name:String) -> Color:
		return _color_for_idx(TYPES.find(logix_type_name))

	func _add_slot_to(list:Array) -> NodeSlot:
		var node_to_add:NodeSlot = NodeSlot.new("undefined", LXNode.TYPES[0])
		list.append(node_to_add)
		return node_to_add

	# FIXME Factorize and port this to the inputs/outputs
	func add_input() -> NodeSlot:
		return _add_slot_to(inputs)

	func add_output() -> NodeSlot:
		return _add_slot_to(outputs)

	func delete_slot(slot:NodeSlot) -> bool:
		var slot_idx:int = inputs.find(slot)
		if slot_idx >= 0:
			inputs.remove(slot_idx)
			_regenerate_slots()
			return true
		
		slot_idx = outputs.find(slot)
		if slot_idx >= 0:
			outputs.remove(slot_idx)
			_regenerate_slots()
			return true

		printerr(
			"Can't find slot " + str(slot) + 
			" in " + logix_class_name)
		return false

	enum DIRECTION { INVALID, INPUT, OUTPUT, COUNT }



	func get_short_title() -> String:
		return logix_class_name.get_extension()

	func get_full_title() -> String:
		return get_short_title() + " (" + self.logix_class_name + ")"



	func set_class_name(new_logix_class_name:String):
		logix_class_name = new_logix_class_name
		self.title = new_logix_class_name.get_extension()

	func _valid_dir_value(dir_value:int) -> bool:
		return DIRECTION.INVALID < dir_value and dir_value < DIRECTION.COUNT

	func _display_slot(
		slot_def:NodeSlot,
		direction:int):

		if not _valid_dir_value(direction):
			printerr("Invalid direction value : " + str(direction))
			return

		var n_slots:int = get_child_count()
		var new_slot_type:int = LXNode.new().type_to_value(slot_def.logix_type)

		var label:Label = Label.new()
		label.text = slot_def.title
		add_child(label)
		match direction:
			DIRECTION.INPUT:
				set_slot(n_slots, 
					true, new_slot_type, _color_for_idx(new_slot_type),
					false, -1, Color(0,0,0,1))
			DIRECTION.OUTPUT:
				set_slot(n_slots,
					false, -1, Color(0,0,0,1),
					true, new_slot_type, _color_for_idx(new_slot_type))
				label.align = Label.ALIGN_RIGHT

	func _regenerate_slots() -> void:
		for child in get_children():
			remove_child(child)
		for input_slot in inputs:
			_display_slot(input_slot, DIRECTION.INPUT)
		for output_slot in outputs:
			_display_slot(output_slot, DIRECTION.OUTPUT)


	func refresh_slots_style():
		_regenerate_slots()
		pass

	func set_io(new_inputs:Array, new_outputs: Array):
		self.inputs = new_inputs
		self.outputs = new_outputs
		refresh_slots_style()

	static func _parse_slots(serialized_slots_defs:Array, out_list:Array):
		for serialized_slot_def in serialized_slots_defs:
			var node_slot:NodeSlot = NodeSlot.from_serialized_def(serialized_slot_def)
			if node_slot != null:
				out_list.append(node_slot)
			else:
				printerr("Could not add a serialized slot")

	static func from_serialized_def(serialized_node:Dictionary) -> LXNode:
		if (not serialized_node.has("inputs") or 
			not serialized_node.has("outputs") or
			not serialized_node.has("classname")):
			printerr("Missing fields in serialized node definition :\n" +
				"inputs, outputs.\n" +
				"Definition :" + str(serialized_node))
			return null
		var deser_inputs:Array = Array()
		var deser_outputs:Array = Array()
		_parse_slots(serialized_node["inputs"], deser_inputs)
		_parse_slots(serialized_node["outputs"], deser_outputs)
		var logix_node:LXNode = LXNode.new()
		logix_node.set_io(deser_inputs, deser_outputs)
		logix_node.set_class_name(serialized_node["classname"])
		return logix_node

	static func _serialize_slots_defs(slots_list:Array, defs_list:Array):
		for slot in slots_list:
			printerr(slot)
			defs_list.append(slot.serialize_def())

	func serialize_def() -> Dictionary:
		var serialized_inputs:Array = []
		var serialized_outputs:Array = []
		_serialize_slots_defs(inputs, serialized_inputs)
		_serialize_slots_defs(outputs, serialized_outputs)
		return {
			"classname": logix_class_name,
			"inputs": serialized_inputs,
			"outputs": serialized_outputs}

	func complete_dup() -> LXNode:
		var duplicate_node:LXNode = self.duplicate()
		# These fields are kind of 'constant' anyway, so that
		# should do the trick for now
		duplicate_node.inputs = self.inputs
		duplicate_node.outputs = self.outputs
		duplicate_node.logix_class_name = self.logix_class_name
		return duplicate_node

	func _get_name_from_list(idx:int, list:Array) -> String:
		if 0 <= idx and idx < len(list):
			return list[idx].title
		printerr(
			"Invalid slot index : " + str(idx) + 
			" (Max : " + str(len(list)) + ")")
		return ""

	func get_input_name(input_slot_idx:int) -> String:
		return _get_name_from_list(input_slot_idx, inputs)

	func get_output_name(output_slot_idx:int) -> String:
		return _get_name_from_list(output_slot_idx, outputs)

	func get_input_idx(input_name:String) -> int:
		for i in len(inputs):
			if inputs[i].title == input_name:
				return i
		return -1

	func get_output_idx(output_name:String) -> int:
		# FIXME Factorize this
		for i in len(outputs):
			if outputs[i].title == output_name:
				return i
		return -1

	func _ready():
		rect_min_size = Vector2(0,80)

class LXNodeDefs:
	var nodes:Array = Array()
	const CURRENT_VERSION = 2

	var sorted_nodes_indices:PoolIntArray = PoolIntArray()

	func _compare_short_names(idx_a:int, idx_b:int):
		return get_model_node_at(idx_a).get_short_title() < get_model_node_at(idx_b).get_short_title()

	func sort_by_short_names():
		var sorted_indices = range(0,len(nodes))
		var i = 0
		sorted_indices.sort_custom(self, "_compare_short_names")
		sorted_nodes_indices.resize(0)
		sorted_nodes_indices.append_array(sorted_indices)

	func serialize() -> Dictionary:
		var serialized_defs:Array = Array()
		for node in nodes:
			serialized_defs.append(node.serialize_def())
			
		return {
			"version": CURRENT_VERSION,
			"definitions": serialized_defs,
			"types": LXNode.types_serialize_defs()
		}

	func _valid_idx(idx:int) -> bool:
		return (0 <= idx and idx < len(nodes))

	func get_model_node_at(idx:int) -> LXNode:
		return nodes[idx] if _valid_idx(idx) else null

	static func from_serialized(serialized:Dictionary) -> LXNodeDefs:
		var deser_nodes:Array = Array()
		LXNode.types_setup_from_serialized(serialized["types"])
		for definition in serialized["definitions"]:
			deser_nodes.append(LXNode.from_serialized_def(definition))
		var lxnodes_defs:LXNodeDefs = LXNodeDefs.new()
		lxnodes_defs.nodes = deser_nodes
		lxnodes_defs.sort_by_short_names()
		return lxnodes_defs

	func append(node_definition:LXNode):
		nodes.append(node_definition)

	func instantiate_from_idx(idx:int) -> LXNode:
		if not _valid_idx(idx):
			return null 

		return nodes[idx].complete_dup()

	func create_new() -> int:
		var n_nodes:int = len(nodes)
		var new_node:LXNode = LXNode.new()
		new_node.set_class_name("FrooxEngine.LogiX.")
		nodes.append(new_node)
		sort_by_short_names()
		return n_nodes

	func get_definition_for(logix_class_name:String) -> LXNode:
		for node in nodes:
			if node.logix_class_name == logix_class_name:
				return node
		return null

func _sort_menu_entries(a, b) -> bool:
	return a["short_title"] < b["short_title"]

func prepare_popup_menu() -> void:
	ui_popup_menu.clear()
	for idx in useable_nodes.sorted_nodes_indices:
		var logix_node_model:LXNode = useable_nodes.get_model_node_at(idx)
		ui_popup_menu.add_item(logix_node_model.get_full_title(), idx)

func _ui_refresh_nodes_list() -> void:
	ui_nodes_list_option.clear()
	for idx in useable_nodes.sorted_nodes_indices:
		var logix_node:LXNode = useable_nodes.get_model_node_at(idx)
		ui_nodes_list_option.add_item(logix_node.get_full_title(), idx)

func _ui_refresh_nodes_list_keep_selection() -> void:
	var selected_id:int = ui_nodes_list_option.get_selected_id()
	_ui_refresh_nodes_list()
	var current_item_index:int = ui_nodes_list_option.get_item_index(selected_id)
	ui_nodes_list_option.select(current_item_index)
	ui_nodes_list_option.emit_signal("item_selected", current_item_index)


func _ui_refresh_types_lists() -> void:

	var previous_edited_slot_type_idx:int = ui_slot_types_option.selected
	ui_type_editor_list.clear()
	ui_slot_types_option.clear()
	for type_name in LXNode.TYPES:
		ui_slot_types_option.add_item(type_name)
		ui_type_editor_list.add_item(type_name)
	if edited_type_idx >= 0:
		ui_type_editor_list.select(edited_type_idx)

	ui_slot_types_option.select(previous_edited_slot_type_idx)

func prepare_editor() -> void:
	_ui_refresh_nodes_list()
	_ui_refresh_types_lists()

func refresh_menus() -> void:
	#prepare_useable_nodes()
	load_definitions_from(definitions_filepath)
	prepare_popup_menu()
	prepare_editor()

func save_definitions_to(filepath:String) -> bool:
	printerr("Meow")
	var json_definitions:String = to_json(useable_nodes.serialize())
	var f:File = File.new()
	var err:int = f.open(filepath, File.WRITE)
	if err == OK:
		f.store_string(json_definitions)
		f.close()
	else:
		printerr(
			"Could not write to " + filepath +".\n" +
			"Error code : " + str(err))

	return err == OK

func load_definitions_from(filepath:String) -> bool:
	var f:File = File.new()
	var err:int = f.open(filepath, File.READ)
	if err != OK:
		printerr(
			"Could not open nodes definitions at " + filepath + "\n" +
			"Error code : " + str(err))
		return false

	var parse_result:JSONParseResult = JSON.parse(f.get_as_text())
	if parse_result.error != OK:
		printerr(
			"Could not parse the nodes defnition JSON file at " + filepath + "\n" +
			"Reason : \n" + parse_result.error_string + "\n" +
			"Line : " + str(parse_result.error_line))
		return false

	if not parse_result.result is Dictionary:
		printerr("Invalid save file. Expected a dictionary, got a " + 
			str(parse_result.result))
		return false

	var new_defs:LXNodeDefs = LXNodeDefs.from_serialized(parse_result.result)
	if new_defs != null:
		useable_nodes = new_defs
	return new_defs != null


func _ready():
	refresh_menus()

func _on_GraphEdit_connection_request(from, from_slot, to, to_slot):
	printerr("Connection request between \n" + 
		str(from) + ":" + str(from_slot) + "\n" +
		str(to) + ":" + str(to_slot) + "\n")
	graph.connect_node(from, from_slot, to, to_slot)

func _on_GraphEdit_connection_to_empty(from, from_slot, release_position):
	printerr("Connection to empty !")

func _on_GraphEdit_connection_from_empty(to, to_slot, release_position):
	printerr("Connection from empty !")

func _on_GraphEdit_disconnection_request(from, from_slot, to, to_slot):
	printerr("Requesting disconnection between :\n" +
		str(from) + ":" + str(from_slot) + "\n" +
		str(to) + ":" + str(to_slot) + "\n")
	graph.disconnect_node(from, from_slot, to, to_slot)

func _on_GraphEdit_popup_request(position):
	printerr("Requesting popup")
	ui_popup_menu.set_position(position)
	ui_popup_menu.show()

func _on_GraphEdit_copy_nodes_request():
	printerr("Requesting node copy... ?")

func _on_GraphEdit_duplicate_nodes_request():
	printerr("Requesting duplication")
	for node in _graph_get_selected_nodes():
		node.selected = false
		var duplicated_node:LXNode = node.complete_dup()
		duplicated_node.offset += Vector2(10,10)
		graph.add_child(duplicated_node)

func _on_GraphEdit_paste_nodes_request():
	# I have zero idea how to handle that
	printerr("Paste nodes request")


func _on_PopupMenu_id_pressed(id):
	var logix_node:LXNode = useable_nodes.instantiate_from_idx(id)
	logix_node.offset = ui_popup_menu.rect_position
	graph.add_child(logix_node)

func line(line:String) -> String:
	 return line + "\n"

# Preparing for the next iterations
export(String) var script_fields_separator = ' '

func _script_quote_string(unquoted_string:String) -> String:
	return "'" + unquoted_string.replace("'", "''") + "'"

func _script_unquote_string(quoted_string:String) -> String:
	return quoted_string.replace("''", "'").trim_prefix("'").trim_suffix("'")

func _generate_instruction_from(instructions_data:PoolStringArray) -> String:
	return instructions_data.join(script_fields_separator)

func _script_define_node(logix_node:LXNode) -> String:
	var instruction_data:PoolStringArray = PoolStringArray([
		"NODE",
		str(logix_node.get_node_id()),
		_script_quote_string(logix_node.logix_class_name),
		_script_quote_string(logix_node.title)
	])
	return _generate_instruction_from(instruction_data)

func _script_define_node_position(logix_node:LXNode) -> String:
	var instruction_data:PoolStringArray = PoolStringArray([
		"POS",
		str(logix_node.get_node_id()),
		logix_node.offset.x,
		logix_node.offset.y
	])
	return _generate_instruction_from(instruction_data)

func _script_define_nodes(node_graph:GraphEdit) -> PoolStringArray:

	var local_array:PoolStringArray = PoolStringArray()
	for child in node_graph.get_children():
		if not child is LXNode:
			continue
		local_array.append(_script_define_node(child))
	return local_array

# FIXME Maybe the positions should be set with the nodes...
# But that won't fix the fact that we might move them
# afterwards, independently of their redefinitions
func _script_define_nodes_positions(node_graph:GraphEdit) -> PoolStringArray:
	var local_array:PoolStringArray = PoolStringArray()
	for child in node_graph.get_children():
		if not child is LXNode:
			continue
		local_array.append(_script_define_node_position(child))
	return local_array

func _script_define_connection(connection:Dictionary) -> Array:
	
	var to_node_uncast:Node   = graph.get_node(connection["to"])
	var from_node_uncast:Node = graph.get_node(connection["from"])

	if (not to_node_uncast is LXNode) or (not from_node_uncast is LXNode):
		printerr(
			"Won't handle connection between : " + connection["from"] + 
			" and " + connection["to"])
		printerr(to_node_uncast)
		printerr(from_node_uncast)
		return [false, ""]

	var to_node:LXNode   = to_node_uncast
	var from_node:LXNode = from_node_uncast
	var to_slot:int      = connection["to_port"]
	var from_slot:int    = connection["from_port"]
	var input_type:int   = to_node.get_slot_type_left(to_slot)
	
	var instruction_data:PoolStringArray = PoolStringArray([
		"INPUT",
		str(to_node.get_node_id()),
		_script_quote_string(to_node.get_input_name(to_slot)),
		str(from_node.get_node_id()),
		_script_quote_string(from_node.get_output_name(from_slot))
	])
	# FIXME With the current type editing system, this can
	# easily break
	# Make the 'Impulse' type, a default type that cannot be
	# removed !
	if to_node._type_name(input_type) == "Impulse":
		instruction_data[0] = "IMPULSE"

	return [true, _generate_instruction_from(instruction_data)]

func _script_define_connections(node_graph:GraphEdit) -> PoolStringArray:
	# Godot played dirty on this one.
	# If you pass a PoolStringArray as an argument, you'll get
	# a copy of it instead.
	# Yes, a COPY. Of an ENTIRE ARRAY !
	# Instead of just passing the reference.
	# That means that 'append' calls won't be of any use.
	# So I'm now building local arrays and outputing their
	# results everytime. So much fun !
	var local_array:PoolStringArray = PoolStringArray()
	for connection in graph.get_connection_list():
		# FIXME Fucking ugly quick fix, remove that horror as
		# soon as possible
		var result:Array = _script_define_connection(connection)
		if result[0] == true:
			local_array.append(result[1])
	return local_array

func _script_define_program_name(
	program_name:String) -> String:
	var instruction_data:PoolStringArray = PoolStringArray([
		"PROGRAM",
		_script_quote_string(program_name)])
	return _generate_instruction_from(instruction_data)

func serialize_current_program(program_name:String) -> String:
	var listing:PoolStringArray = PoolStringArray()

	listing.append(_script_define_program_name(program_name))
	listing.append_array(_script_define_nodes(graph))
	listing.append_array(_script_define_nodes_positions(graph))
	listing.append_array(_script_define_connections(graph))
	return listing.join("\n")

class ScriptLoaderState:
	var nodes_refs:Dictionary = {}

func _report_bogus_line(
	instruction_name:String,
	n_args_expected:int,
	n_args_actual:int,
	script_line:String):

	printerr(
		"Bogus " + instruction_name + " LINE.\n" +
		"Expecting " + str(n_args_expected) + " arguments, " +
		"got : " + str(n_args_actual) + "\n" +
		"Raw line : " + script_line)

func _parse_program_line(script_line:String, state:Dictionary):
	var args:PoolStringArray = script_line.split(script_fields_separator)
	ui_program_name_text.text = _script_unquote_string(args[1])
	return

func _parse_node_line(script_line:String, state:Dictionary):
	var args:PoolStringArray = script_line.split(script_fields_separator)
	var expected_args:int = 4
	var n_args:int = len(args)
	if n_args < expected_args:
		_report_bogus_line("NODE", expected_args, n_args, script_line)
		return

	var node_id:int           = (args[1] as String).to_int()
	var node_logix_class_name = _script_unquote_string(args[2])
	var node_title            = _script_unquote_string(args[3])

	var node_model:LXNode = useable_nodes.get_definition_for(node_logix_class_name)
	if node_model == null:
		printerr(
			"Could not find a node definition for " + node_logix_class_name + "\n" +
			"Skipping...\n")
		return

	var added_node:LXNode = node_model.complete_dup()
	# FIXME This is actually dangerous, check for duplicate id
	# first !
	added_node.node_id = node_id
	added_node.title   = node_title

	# FIXME Get rid of that global variable
	graph.add_child(added_node)

	state["nodes"][node_id] = added_node

	return

func _parse_connection_line(script_line:String, state:Dictionary):
	var args:PoolStringArray = script_line.split(script_fields_separator)
	var expected_args:int = 5
	var n_args:int = len(args)
	var instruction_name:String = args[0]
	if n_args < expected_args:
		_report_bogus_line(instruction_name, expected_args, n_args, script_line)
		return

	var to_id:int        = args[1].to_int()
	var to_slot_name     = _script_unquote_string(args[2])
	var from_id:int      = args[3].to_int()
	var from_slot_name   = _script_unquote_string(args[4])

	var script_nodes:Dictionary = state["nodes"]
	if (not script_nodes.has(from_id)) or (not script_nodes.has(to_id)):
		printerr("Could not found the nodes required for the connection.\n" +
			"From ID : " + str(from_id) + "\n" +
			"To ID   : " + str(to_id) + "\n" +
			"IDS : " + str(script_nodes.keys()))
		return

	# CHECK Why not search for the node inside the list ?
	var from_node:LXNode = script_nodes[from_id]
	var to_node:LXNode   = script_nodes[to_id]

	var from_idx:int = from_node.get_output_idx(from_slot_name)
	var to_idx:int = to_node.get_input_idx(to_slot_name)

	if (from_idx < 0) or (to_idx < 0):
		printerr(
			"Could not either find :\n" +
			"  The output : " + from_slot_name + " on " + from_node.title + "\n" +
			"  The input  : " + to_slot_name + " on " + to_node.title + "\n")
		return

	if (graph.connect_node(from_node.name, from_idx, to_node.name, to_idx)) != OK:
		printerr(
			"Could not connect :\n" + 
			from_node.name + ":" + from_slot_name + "(" + str(from_idx) + ")\n" +
			to_node.name + ":" + to_slot_name + "(" + str(to_idx) + ")\n")

func _parse_input_line(script_line:String, state:Dictionary):
	_parse_connection_line(script_line, state)

func _parse_impulse_line(script_line:String, state:Dictionary):
	_parse_connection_line(script_line, state)

func _parse_pos_line(script_line:String, state:Dictionary):
	# FIXME Factorize this...
	var args:PoolStringArray = script_line.split(script_fields_separator)
	var expected_args:int = 4
	var n_args:int = len(args)
	if n_args < expected_args:
		_report_bogus_line("POS", expected_args, n_args, script_line)
		return

	var node_id:int = args[1].to_int()
	if not state["nodes"].has(node_id):
		printerr("Can't handle the position of unknown node : " + str(node_id))
		return

	var node:LXNode = state["nodes"][node_id]

	var node_pos_x:float = args[2].to_float()
	var node_pos_y:float = args[3].to_float()

	node.offset = Vector2(node_pos_x, node_pos_y)

func load_script(program_script:String):
	var state = {"nodes": {}}
	graph.clear_connections()
	for child in graph.get_children():
		if child is LXNode:
			graph.remove_child(child)

	# FIXME Doing it the stupid way, to release the whole thing ASAP
	# This will fail miserably when trying to parse string definitions
	# containing carriage returns
	var lines:PoolStringArray = program_script.split('\n')
	for line in lines:
		match line.split(script_fields_separator)[0]:
			"IMPULSE":
				_parse_impulse_line(line, state)
			"INPUT":
				_parse_input_line(line, state)
			"NODE":
				_parse_node_line(line, state)
			"PROGRAM":
				_parse_program_line(line, state)
			"POS":
				_parse_pos_line(line, state)

func save_program(program_name:String):
	var serialized_program:String = serialize_current_program(program_name)
	printerr(serialized_program)
	# SLX for Serialized LogiX
	var extension_name:String = "slx"
	var program_filename:String = "logix_program_" + program_name + "." + extension_name
	var program_filepath:String = "user://" + program_filename
	var f = File.new()
	var err:int = f.open(program_filepath, File.WRITE)
	if err == OK:
		f.store_string(serialized_program)
		f.close()
	else:
		printerr(
			"Could not open " + program_filepath + " :\n" +
			"Code : " + str(err))

func load_program(program_filename:String) -> bool:
	var f:File = File.new()

	var err:int = f.open(program_filename, File.READ)
	if err != OK:
		printerr(
			"Could not open " + program_filename + ".\n" +
			"Error code : " + str(err))
		return false

	var serialized_program:String = f.get_as_text()
	f.close()

	# FIXME Make the thing optionnaly atomic.
	# Half broken programs, might not be what people want.
	# Still, it's sometimes better than losing everything.
	load_script(serialized_program)

	return true

func _on_SaveButton_pressed():
	var program_name:String = ui_program_name_text.text
	# FIXME Sanitize filenames
	# Check if the sanitized filenames still have characters in it
	if program_name.strip_edges().empty():
		# FIXME Throw a real error message
		printerr("Meep ! Provide a name for the program")
		return
	save_program(program_name)

# ... WTF Godot... Why can't I just call this on GraphEdit !?
func _graph_get_selected_nodes() -> Array:
	var selected_nodes = []
	for i in graph.get_child_count():
		var node = graph.get_child(i)
		if node is LXNode:
			if node.selected:
				selected_nodes.append(node)
	return selected_nodes

func _remove_connections_to(node:LXNode, connections:Array):
	var node_name:String = node.name
	# Yes, top performances here...
	for connection in connections:
		if connection["from"] == node_name or connection["to"] == node_name:
			graph.disconnect_node(
				connection["from"], connection["from_port"],
				connection["to"], connection["to_port"])

func _on_Program_delete_nodes_request():
	printerr("Deletion of multiple nodes requested")
	# FIXME Ok... We're going to need an enhanced version
	# of 'GraphEdit' VERY SOON

	var connection_list:Array = graph.get_connection_list()
	for node in _graph_get_selected_nodes():
		_remove_connections_to(node, connection_list)
		node.queue_free()

var invalid_node:LXNode = LXNode.new()
var selected_node_model:LXNode = invalid_node

var invalid_slot:NodeSlot = NodeSlot.new("invalid", "")
var edited_slot:NodeSlot = invalid_slot
func modify_edited_slot():
	if edited_slot == invalid_slot:
		printerr("The edited slot is not set !?")
		return

	if selected_node_model == invalid_node:
		printerr("No useable node selected")
		return

	var node:LXNode = selected_node_model
	var slot_name:String = ui_edited_node_class_name_input.text
	var slot_type:int = ui_slot_types_option.get_selected_id()
	
	edited_slot.change(slot_name, slot_type)

func edit_node(useable_node_idx:int):
	var model_node:LXNode = useable_nodes.get_model_node_at(useable_node_idx)
	if model_node == null:
		printerr("Cannot get node model " + str(useable_node_idx))
		return

	selected_node_model = model_node
	ui_edited_node_class_name_input.text = model_node.logix_class_name

	_ui_refresh_edited_node_slots_list(
		ui_edited_node_slots_input_list,
		selected_node_model.inputs)
	_ui_refresh_edited_node_slots_list(
		ui_edited_node_slots_output_list,
		selected_node_model.outputs)


func _on_NodesListButton_item_selected(index):
	var actual_idx:int = ui_nodes_list_option.get_item_id(index)
	edit_node(actual_idx)

func _on_ClassNameInput_text_entered(new_text):
	if selected_node_model == invalid_node:
		return
	selected_node_model.set_class_name(new_text)
	_ui_refresh_nodes_list_keep_selection()
	prepare_popup_menu()
	pass # Replace with function body.

func _ui_refresh_nodes_look():
	selected_node_model.refresh_slots_style()
	for child in graph.get_children():
		if not child is LXNode:
			continue
		var logix_node:LXNode = child
		logix_node.refresh_slots_style()

func _ui_refresh_edited_node_refresh_slots():
	_ui_refresh_edited_node_slots_list(
		ui_edited_node_slots_input_list,
		selected_node_model.inputs)
	_ui_refresh_edited_node_slots_list(
		ui_edited_node_slots_output_list,
		selected_node_model.outputs)

func _ui_refresh_edited_node_slots_list(list:ItemList, slots:Array):
	list.clear()
	for slot in slots:
		list.add_item(slot.title)

func _on_Inputs_AddButton_pressed():
	if selected_node_model == invalid_node:
		printerr(
			"[BUG] Can't add an input slot if " +
			"no node is currently being edited")
		return
	selected_node_model.add_input()
	_ui_refresh_nodes_look()
	_ui_refresh_edited_node_slots_list(
		ui_edited_node_slots_input_list,
		selected_node_model.inputs)

func _on_Outputs_AddButton_pressed():
	if selected_node_model == invalid_node:
		printerr(
			"[BUG] Can't add an output slot if " +
			"no node is currently being edited")
	selected_node_model.add_output()
	_ui_refresh_nodes_look()
	_ui_refresh_edited_node_slots_list(
		ui_edited_node_slots_output_list,
		selected_node_model.outputs)

func _ui_slot_editor_disable():
	ui_edited_node_slot_name.set_editable(false)
	ui_slot_types_option.set_disabled(true)

func _ui_slot_editor_enable():
	ui_edited_node_slot_name.set_editable(true)
	ui_slot_types_option.set_disabled(false)

func _edit_slot(slot:NodeSlot):
	if slot == null:
		printerr("[BUG] Trying to edit a null slot !")
	edited_slot = slot

	printerr(slot.serialize_def())
	var type_index:int = LXNode.type_to_value(slot.logix_type)
	if type_index < 0:
		# FIXME Show a real error message
		printerr("[BUG] Cannot edit the slot because of an invalid type !?")
		_ui_slot_editor_disable()
		# FIXME Disable the editors in this case !
		return

	_ui_slot_editor_enable()
	ui_edited_node_slot_name.text = slot.title
	ui_slot_types_option.select(type_index)

func _on_Inputs_List_item_selected(idx:int):
	_edit_slot(selected_node_model.inputs[idx])

func _on_Outputs_List_item_selected(idx:int):
	_edit_slot(selected_node_model.outputs[idx])

# FIXME Change the name, as it generates confusion
# between Text input and Nodes inputs
func _on_SlotNameInput_text_entered(new_text):
	if edited_slot == invalid_node:
		printerr("[BUG] Trying to edit a null slot !")
	edited_slot.title = new_text
	_ui_refresh_edited_node_refresh_slots()
	_ui_refresh_nodes_look()

func _on_SlotTypeOptions_item_selected(index):
	if edited_slot == invalid_node:
		printerr("[BUG] Trying to edit a null slot !")
	edited_slot.logix_type = LXNode.TYPES[ui_slot_types_option.selected]
	_ui_refresh_nodes_look()

func _on_CreateNode_Button_pressed():
	printerr("Adding node")
	var new_id:int = useable_nodes.create_new()
	_ui_refresh_nodes_list()
	prepare_popup_menu()
	var menu_index:int = ui_nodes_list_option.get_item_index(new_id)
	ui_nodes_list_option.select(menu_index)
	# FIXME I have no idea why I have to trigger this manually !
	# This should be triggered by the list !
	# Emit signal doesn't work
	ui_nodes_list_option.emit_signal("item_selected", menu_index)

func _on_DeleteSlotButton_pressed():
	if selected_node_model.delete_slot(edited_slot):
		edited_slot = invalid_slot
		_ui_refresh_edited_node_refresh_slots()
		_ui_refresh_nodes_look()

# FIXME Dirty hack
var editing_new:bool = false
func _editing_type() -> bool:
	return edited_type_idx != 0

func _save_type_changes():
	if _editing_type():
		LXNode.change_type_idx_name(edited_type_idx, ui_edited_type_name.text)
		LXNode.change_type_idx_color(edited_type_idx, ui_edited_type_color.color)
	save_definitions_to("user://meow.json")
	

func _on_TypesEditor_AddButton_pressed():
	# Small hack to avoid losing changes
	if _editing_type():
		# FIXME Just make one function that save the current state
		LXNode.change_type_idx_name(edited_type_idx, ui_edited_type_name.text)
		
	var added_idx:int = LXNode.add_logix_type("NewType", Color(0.5,0.5,0.5,1))
	_ui_refresh_types_lists()
	editing_new = true
	ui_type_editor_list.emit_signal("item_selected", added_idx)
	pass # Replace with function body.

var edited_type_idx:int = 0
func _on_List_item_selected(index):
	edited_type_idx = index
	var type_name:String = ui_type_editor_list.get_item_text(index)
	ui_edited_type_name.text = type_name
	ui_edited_type_color.color = LXNode._color_for(type_name)
	if editing_new:
		editing_new = false
		ui_edited_type_name.select_all()
		ui_edited_type_name.grab_focus()
	pass # Replace with function body.


func _on_NodesDefinitions_SaveButton_pressed():
	_save_type_changes()

func _on_ColorPicker_color_changed(color):
	_save_type_changes()
	_ui_refresh_types_lists()


func _on_TypeNameInput_text_entered(new_text):
	_save_type_changes()
	_ui_refresh_types_lists()


func _on_Button_pressed():
	load_program("user://logix_program_" + ui_program_name_text.text + ".slx")
	pass # Replace with function body.


func _on_PopupMenu_focus_exited():
	printerr("Focus exited")
	ui_popup_menu.hide()
	pass # Replace with function body.
