extends Control

export(String) var logix_program_dirpath = "user://"
export(String) var logix_program_filename_prefix = "logix_program_"
export(String) var logix_program_extension = "slx"

export(NodePath) var path_graph
onready var graph:GraphEdit = get_node(path_graph) as GraphEdit
#onready var graph:GraphEdit = $"TabContainer/Maincontainer/Program"

export(NodePath) var path_tabs
onready var ui_tabs = get_node(path_tabs)

export(NodePath) var path_scripts_list
onready var ui_scripts_list:ItemList = get_node(path_scripts_list) as ItemList

export(NodePath) var path_script_selected_text
onready var ui_script_selected_text:TextEdit = get_node(path_script_selected_text)

export(NodePath) var path_nodes_definitions_text
onready var ui_nodes_definitions_text = get_node(path_nodes_definitions_text)

export(NodePath) var path_editor_slots_types
onready var ui_slot_types_option:OptionButton = get_node(path_editor_slots_types)

export(NodePath) var path_editor_node_slot_name
onready var ui_edited_node_slot_name = get_node(path_editor_node_slot_name)

export(NodePath) var path_editor_nodes_list_option
onready var ui_nodes_list_option:OptionButton = get_node(path_editor_nodes_list_option)

export(NodePath) var path_editor_node_class_name_input
onready var ui_edited_node_class_name_input = get_node(path_editor_node_class_name_input)

export(NodePath) var path_editor_node_inputs_fields_editor
onready var ui_edited_node_inputs_fields_editor = get_node(path_editor_node_inputs_fields_editor)

export(NodePath) var path_editor_node_is_input_checkbox
onready var ui_edited_node_is_input_checkbox = get_node(path_editor_node_is_input_checkbox)

export(NodePath) var path_editor_node_input_grid_columns_spinbox
onready var ui_edited_node_input_grid_columns_spinbox = get_node(path_editor_node_input_grid_columns_spinbox)

export(NodePath) var path_editor_node_input_grid_rows_spinbox
onready var ui_edited_node_input_grid_rows_spinbox = get_node(path_editor_node_input_grid_rows_spinbox)

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

export(String) var definitions_filepath = "user://nodes_definitions.json"
export(String) var base_definitions_filepath = "res://data/definitions.json"

onready var useable_nodes:LXNodeDefs = $LXNodeDefs

func _sort_menu_entries(a, b) -> bool:
	return a["short_title"] < b["short_title"]

func prepare_popup_menu() -> void:
	ui_popup_menu.clear()
	for idx in useable_nodes.sorted_nodes_indices:
		var logix_node_model:LXNode = useable_nodes.get_model_node_at(idx)
		ui_popup_menu.add_item(logix_node_model.get_full_title(), idx)

func _ui_nodes_definitions_text_refresh() -> void:
	ui_nodes_definitions_text.text = JSON.print(useable_nodes.serialize(), "\t")

func _ui_refresh_nodes_list() -> void:
	ui_nodes_list_option.clear()
	for idx in useable_nodes.sorted_nodes_indices:
		var logix_node:LXNode = useable_nodes.get_model_node_at(idx)
		ui_nodes_list_option.add_item(logix_node.get_full_title(), idx)
	_ui_nodes_definitions_text_refresh()

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
	_ui_nodes_definitions_text_refresh()

func prepare_editor() -> void:
	_ui_refresh_nodes_list()
	_ui_refresh_types_lists()


func load_saved_definitions_nodes():
	if not load_definitions_from(definitions_filepath):
		_copy_base_definitions(base_definitions_filepath, definitions_filepath)
		if not load_definitions_from(definitions_filepath):
			load_definitions_from(base_definitions_filepath)

func refresh_menus() -> void:
	#prepare_useable_nodes()
	prepare_popup_menu()
	prepare_editor()

func save_definitions_to(filepath:String) -> bool:
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

func _copy_base_definitions(from_filepath:String, to_filepath:String) -> bool:
	var from_file:File = File.new()
	var err:int = from_file.open(from_filepath, File.READ)
	if err != OK:
		printerr("[BUG] Could not open the base definitions file !")
		printerr("Error code : %d" % [err])
		return false

	var to_file:File = File.new()
	err = to_file.open(to_filepath, File.WRITE)
	if err != OK:
		printerr("[BUG] Could not open the target definitions file")
		printerr("Error code : %d" % [err])
		return false

	to_file.store_string(from_file.get_as_text())
	to_file.close()
	from_file.close()

	return true

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

	# FIXME We just nuked useful error management
	# See the method definition.
	useable_nodes.configure_from_serialized(parse_result.result)
	return true

# FIXME Get rid of this if possible...
# I don't know how to do this correclty though.
# Using the same 'slot type' and allowing connections to
# anything sounds cool at first, but will just be a UX
# nightmare, due to snapping.
# Still, that might just resolve the issue altogether...

func _register_generic_connections():
	for i in range(1, len(LXNode.TYPES)):
		graph.add_valid_connection_type(LXNode.GENERIC_NODE_TYPE, i)

func _ready():
	load_saved_definitions_nodes()
	refresh_menus()
	_ui_scripts_list_refresh()
	get_tree().connect("files_dropped", self, "_on_files_dropped")
	_register_generic_connections()


func _on_GraphEdit_connection_request(from, from_slot, to, to_slot):
	printerr(
		"Connection request between \n%s:%d\n%s:%d" % 
		[str(from), from_slot, str(to), to_slot])
	var from_node:LXNode = graph.get_node(from) as LXNode
	var to_node:LXNode   = graph.get_node(to) as LXNode
	if from_node == null or to_node == null:
		printerr("[BUG] Not connecting Logix nodes !")
		return

	var can_connect:bool = (
		  from_node.can_connect_to_output(from_slot, to, to_slot)
		and to_node.can_connect_to_input(to_slot, from, from_slot))

	if can_connect:
		from_node.connecting_output(from_slot, to_node, to_slot)
		to_node.connecting_input(to_slot, from_node, from_slot)
		graph.connect_node(from, from_slot, to, to_slot)

func _on_GraphEdit_connection_to_empty(from, from_slot, release_position):
	printerr("Connection to empty !")

func _on_GraphEdit_connection_from_empty(to, to_slot, release_position):
	printerr("Connection from empty !")

func _on_GraphEdit_disconnection_request(from, from_slot, to, to_slot):
	printerr("Requesting disconnection between :\n" +
		str(from) + ":" + str(from_slot) + "\n" +
		str(to) + ":" + str(to_slot) + "\n")
	var from_node:LXNode = graph.get_node(from) as LXNode
	var to_node:LXNode   = graph.get_node(to) as LXNode
	if from_node != null and to_node != null:
		from_node.disconnecting_output(from_slot)
		to_node.disconnecting_input(to_slot)
	else:
		printerr("[BUG] Could not find the Logix nodes being disconnected !")
		# We still continue, because we have to honor
		# the disconnection.

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
		duplicated_node.selected = true

func _on_GraphEdit_paste_nodes_request():
	# I have zero idea how to handle that
	printerr("Paste nodes request")


func _on_PopupMenu_id_pressed(id):
	var logix_node:LXNode = useable_nodes.instantiate_from_idx(id)
	logix_node.offset = ui_popup_menu.rect_position + graph.scroll_offset
	graph.add_child(logix_node)

func line(line:String) -> String:
	 return line + "\n"

# Preparing for the next iterations
export(String) var script_fields_separator = ' '

func _script_quote_string(unquoted_string:String) -> String:
	return "'" + unquoted_string.replace("'", "''") + "'"

func _script_unquote_string(quoted_string:String) -> String:
	return quoted_string.replace("''", "'").trim_prefix("'").trim_suffix("'")

func _script_user_input_to_base64(unquoted_data:String) -> String:
	return '"' + Marshalls.utf8_to_base64(unquoted_data) + '"'

func _script_base64_to_user_input(quoted_data:String) -> String:
	return Marshalls.base64_to_utf8(quoted_data.trim_prefix('"').trim_suffix('"'))

func _generate_instruction_from(instructions_data:PoolStringArray) -> String:
	return instructions_data.join(script_fields_separator)

func _script_define_node(logix_node:LXNode) -> String:
	var instruction_data:PoolStringArray = PoolStringArray([
		"NODE",
		str(logix_node.get_node_id()),
		# logix_node.logix_class_name
		_script_quote_string(logix_node.get_logix_class_full_name()),
		# At the moments, title are automatically set up
		# But that might change
		_script_user_input_to_base64(logix_node.title)
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

func _script_define_connection(
	node_graph:GraphEdit,
	connection:Dictionary) -> Array:
	
	var to_node_uncast:Node   = node_graph.get_node(connection["to"])
	var from_node_uncast:Node = node_graph.get_node(connection["from"])

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
	for connection in node_graph.get_connection_list():
		# FIXME Fucking ugly quick fix, remove that horror as
		# soon as possible
		var result:Array = _script_define_connection(node_graph, connection)
		if result[0] == true:
			local_array.append(result[1])
	return local_array

# File versions allow interpreters to understand how
# they should parse your file, once the format evolves
const PROGRAM_SCRIPT_VERSION:int = 1

func _script_define_program_name(program_name:String) -> String:

	var instruction_data:PoolStringArray = PoolStringArray([
		"PROGRAM",
		_script_user_input_to_base64(program_name),
		str(PROGRAM_SCRIPT_VERSION)])
	return _generate_instruction_from(instruction_data)

# FIXME This is bound to miserably
export(String) var script_values_separator = ' '
func _script_define_const_node_value(logix_const_node:LXConstValue) -> String:

	var quoted_values:PoolStringArray = PoolStringArray()

	for value in logix_const_node.get_values():
		quoted_values.append(_script_user_input_to_base64(value))

	var instruction_data:PoolStringArray = PoolStringArray([
		"SETCONST",
		str(logix_const_node.get_node_id()),
		quoted_values.join(script_values_separator)
	]) 
	return _generate_instruction_from(instruction_data)

func _script_define_const_nodes_values(node_graph:GraphEdit) -> PoolStringArray:

	var values:PoolStringArray = PoolStringArray()
	for child in node_graph.get_children():
		if not child is LXConstValue:
			continue
		values.append(_script_define_const_node_value(child))

	return values

func serialize_current_program(program_name:String) -> String:
	var listing:PoolStringArray = PoolStringArray()

	listing.append(_script_define_program_name(program_name))
	listing.append_array(_script_define_nodes(graph))
	listing.append_array(_script_define_const_nodes_values(graph))
	listing.append_array(_script_define_nodes_positions(graph))
	listing.append_array(_script_define_connections(graph))
	return listing.join("\n") + "\n"

class ScriptLoaderState:
	var nodes_refs:Dictionary = {}

func _report_bogus_line(
	instruction_name:String,
	n_args_expected:int,
	n_args_actual:int,
	script_line:String):

	printerr(
		"Bogus "      + instruction_name + " LINE.\n" +
		"Expecting "  + str(n_args_expected) + " arguments, " +
		"got : "      + str(n_args_actual) + "\n" +
		"Raw line : " + script_line)

func _parse_program_line(script_line:String, state:Dictionary):
	var args:PoolStringArray = script_line.split(script_fields_separator)
	ui_program_name_text.text = _script_base64_to_user_input(args[1])
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

	var node_model:LXNode = useable_nodes.find_def(node_logix_class_name)
	if node_model == null:
		printerr(
			"Could not find a node definition for " + node_logix_class_name + "\n" +
			"Skipping...\n")
		return

	var added_node:LXNode = node_model.complete_dup()
	# FIXME This is actually dangerous, check for duplicate id
	# first !
	added_node.node_id = node_id
	added_node.title   = _script_base64_to_user_input(node_title)

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

func _parse_setconst_line(script_line:String, state:Dictionary):
	# FIXME This is the 'C' definition of args, which can easily
	# surprise other programmers. Try to find another name. 
	var args:PoolStringArray = script_line.split(script_fields_separator)
	var min_expected_args:int = 3
	var n_args:int = len(args)
	if n_args < min_expected_args:
		_report_bogus_line("SETCONST", min_expected_args, n_args, script_line)
		return

	var node_id_str:String = args[1]
	printerr("Node ID : " + node_id_str)
	var node_id:int = node_id_str.to_int()
	if not state["nodes"].has(node_id):
		printerr("Bogus node ID : " + str(node_id))
		return

	var node:LXConstValue = state["nodes"][node_id]
	var values:PoolStringArray = PoolStringArray()

	for i in range(2, n_args):
		values.append(_script_base64_to_user_input(args[i]))

	node.set_values(values)

func _load_script(program_script:String):
	var state = {"nodes": {}}
	graph.clear_connections()
	for child in graph.get_children():
		if child is LXNode:
			graph.remove_child(child)

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
			"SETCONST":
				_parse_setconst_line(line, state)

func _get_logix_program_filepath_for(script_name:String) -> String:
	return (
		logix_program_dirpath +
		logix_program_filename_prefix +
		script_name + "." +
		logix_program_extension)

func _save_script(program_name:String, serialized_program:String) -> bool:
	var program_filepath:String = _get_logix_program_filepath_for(program_name)
	var f = File.new()
	var err:int = f.open(program_filepath, File.WRITE)
	if err == OK:
		f.store_string(serialized_program)
		f.close()
	else:
		printerr(
			"Could not open " + program_filepath + " :\n" +
			"Code : " + str(err))
	return err == OK

func save_program(program_name:String) -> bool:
	var serialized_program:String = serialize_current_program(program_name)
	printerr(serialized_program)
	# SLX for Serialized LogiX
	return _save_script(program_name, serialized_program)

func _get_script_content(script_name:String):
	return _read_file_content(_get_logix_program_filepath_for(script_name))

func load_program(program_name:String) -> bool:
	var program_script:String = _get_script_content(program_name)
	if program_script == null:
		return false

	# FIXME Make the thing optionnaly atomic.
	# Half broken programs, might not be what people want.
	# Still, it's sometimes better than losing everything.
	_load_script(program_script)

	return true

# FIXME There's inconsistencies with the 'program' and 'scripts'
# naming.
func delete_program(program_name:String) -> int:
	var d:Directory = Directory.new()
	return d.remove(_get_logix_program_filepath_for(program_name))

func _get_program_name() -> String:
	return ui_program_name_text.text

func _on_SaveButton_pressed():
	var program_name:String = _get_program_name()
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

func _edited_node_can_convert_to_lxconst() -> bool:
	return LXConstValue._can_become_const_input(selected_node_model)

func _editor_const_inputs_show(state:bool):
	ui_edited_node_inputs_fields_editor.visible = state

func edit_node(useable_node_idx:int):
	var model_node:LXNode = useable_nodes.get_model_node_at(useable_node_idx)
	if model_node == null:
		printerr("Cannot get node model " + str(useable_node_idx))
		return

	selected_node_model = model_node
	ui_edited_node_class_name_input.text = model_node.logix_class_name

	_ui_refresh_edited_node_refresh_slots()

	# !!!?
	# Godot IS FUCKING INCOHERENT HERE
	# "item selected" signals ARE NOT TRIGGERED on UI list when calling
	# select methods on these lists.
	# However, checkboxes "toggled" signals are TRIGGERED when setting
	# pressed manually !?
	# WTF GODOT !
	ui_edited_node_is_input_checkbox.disconnect("toggled", self, "_on_CheckBox_toggled")
	ui_edited_node_is_input_checkbox.pressed = model_node is LXConstValue
	ui_edited_node_is_input_checkbox.connect("toggled", self, "_on_CheckBox_toggled")

	var show_fields_editor:bool = (
		model_node is LXConstValue or
		LXConstValue._can_become_const_input(selected_node_model))

	_editor_const_inputs_show(show_fields_editor)

	if selected_node_model is LXConstValue:
		var const_value_node:LXConstValue = model_node
		ui_edited_node_input_grid_columns_spinbox.value = const_value_node.editor_grid_size.x
		ui_edited_node_input_grid_rows_spinbox.value = const_value_node.editor_grid_size.y


func _on_NodesListButton_item_selected(index):
	var actual_idx:int = ui_nodes_list_option.get_item_id(index)
	edit_node(actual_idx)


func _graph_change_node_classname(old_name:String, new_name:String):
	for child in graph.get_children():
		if not child is LXNode:
			continue
		var logix_node:LXNode = child as LXNode
		if logix_node.logix_class_name == old_name:
			logix_node.set_class_name(new_name)

func _selected_node_model_change_name(new_name:String):
	if selected_node_model == invalid_node:
		return
	_graph_change_node_classname(
		selected_node_model.logix_class_name,
		new_name)
	selected_node_model.set_class_name(new_name)
	_ui_refresh_nodes_list_keep_selection()
	prepare_popup_menu()
	pass

func _on_ClassNameInput_text_entered(new_text):
	_selected_node_model_change_name(new_text)
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
	# FIXME Stupid hack for input fields support
	if (_edited_node_can_convert_to_lxconst()):
		_editor_const_inputs_show(true)

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
	var new_id:int = useable_nodes.add_new()
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
	save_definitions_to(definitions_filepath)

func _on_TypesEditor_AddButton_pressed():
	# Small hack to avoid losing changes
	if _editing_type():
		# FIXME Just make one function that save the current state
		LXNode.change_type_idx_name(edited_type_idx, ui_edited_type_name.text)
		
	var added_idx:int = LXNode.add_logix_type("NewType", Color(0.5,0.5,0.5,1))
	_ui_refresh_types_lists()
	editing_new = true
	ui_type_editor_list.emit_signal("item_selected", added_idx)

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

func _on_CheckBox_toggled(button_pressed:bool):
	printerr("Called CheckBox toggled")
	if selected_node_model != invalid_node:
		var selected_node_idx = useable_nodes.get_node_idx(selected_node_model)
		var new_node:LXNode
		var conversion_successful:bool = false
		if button_pressed:
			conversion_successful = useable_nodes.convert_node_to_lxconst(selected_node_model)
		else:
			conversion_successful = useable_nodes.convert_lxconst_to_node(selected_node_model)
		if conversion_successful:
			selected_node_model = useable_nodes.get_child(selected_node_idx)
		else:
			printerr("[BUG] new node is NULL !?")
			selected_node_model = invalid_node

func _on_ColumnsInput_value_changed(value):
	if selected_node_model is LXConstValue:
		selected_node_model.editor_grid_size.x = value

func _on_RowsInput_value_changed(value):
	if selected_node_model is LXConstValue:
		selected_node_model.editor_grid_size.y = value

func _on_SlotNameInput_text_changed(new_text):
	if edited_slot == invalid_node:
		printerr("[BUG] Trying to edit a null slot !")
	edited_slot.title = new_text
	_ui_refresh_edited_node_refresh_slots()

func _on_ClassNameInput_focus_exited():
	_selected_node_model_change_name(ui_edited_node_class_name_input.text)

func _on_SlotNameInput_focus_entered():
	if edited_slot == invalid_node:
		printerr("[BUG] Trying to edit a null slot !")
	edited_slot.title = ui_edited_node_slot_name.text
	_ui_refresh_edited_node_refresh_slots()

func _on_SendButton_pressed():
	$TabContainer/Websocket.send_string(serialize_current_program(_get_program_name()))

func _script_name_looks_valid(script_path:String) -> bool:
	# Be careful, filename seems to be a key property on Godot
	var fname:String = script_path.get_file()
	var ext:String   = script_path.get_extension()

	printerr("%s :\nbname : %s\next : %s" % [script_path, fname, ext])
	return (
		fname.begins_with(logix_program_filename_prefix) and
		ext == logix_program_extension)

func _script_name_get_from_path(script_path:String) -> String:
	return script_path.get_file().get_basename().replace(logix_program_filename_prefix, "")

func _ui_scripts_list_refresh():
	ui_scripts_list.clear()
	var dir:Directory = Directory.new()
	var err = dir.open(logix_program_dirpath)
	if err != OK:
		# FIXME That's a SERIOUS issue. Print a clear
		# warning on the screen !
		printerr(
			"Could not open programs directory %s.\n" +
			"Error : %d" % [logix_program_dirpath, err])
		return

	printerr("Refreshing")
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and _script_name_looks_valid(file_name):
			print("Found file: " + file_name)
			ui_scripts_list.add_item(_script_name_get_from_path(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

func _on_ScriptsList_item_selected(index):
	var script_name:String = ui_scripts_list.get_item_text(index)
	var content:String = _get_script_content(script_name)
	if content != null:
		ui_script_selected_text.text = content

enum TABS { SAVED_PROGRAMS, LOGIX_NODES, NODES_EDITOR, WEBSOCKET }

func _on_ScriptsList_item_activated(index):
	if load_program(ui_scripts_list.get_item_text(index)):
		ui_tabs.current_tab = TABS.LOGIX_NODES

func _on_TabContainer_tab_selected(tab):
	if tab == TABS.SAVED_PROGRAMS:
		_ui_scripts_list_refresh()

var program_right_clicked:String
func _on_FileDeletionConfirmation_confirmed():
	if program_right_clicked != null:
		delete_program(program_right_clicked)
		_ui_scripts_list_refresh()
		ui_script_selected_text.text = ""


func _on_FileContextMenu_id_pressed(id):
	if id == 2:
		$FileDeletionConfirmation.popup_centered()


func _on_ScriptsList_item_rmb_selected(index, at_position):
	program_right_clicked = ui_scripts_list.get_item_text(index)
	# FIXME Last minute hack because I'm fucking fed up
	# of Godot retarded behaviours.
	# I want to display the popup at the bottom right of the
	# cursor, to avoid having "Delete" selected by default !
	# But NOOOO, Godot will display THAT popup centered.
	
	$FileContextMenu.set_position(at_position + Vector2(30,30))
	$FileContextMenu.popup()
	pass # Replace with function body.


func _on_FileContextMenu_focus_exited():
	$FileContextMenu.hide()
	pass # Replace with function body.

func _read_file_content(filepath:String):
	var f:File = File.new()
	var err:int = f.open(filepath, File.READ)
	if err != OK:
		printerr("Could not read file %s.\nError code : %d" % [filepath, err])
		return null
	var content:String = f.get_as_text()
	f.close()
	return content

func _on_files_dropped(filepaths:PoolStringArray, screen) -> void:
	# FIXME Dubious check. Check if that actually happen
	if len(filepaths) == 0:
		return

	match ui_tabs.current_tab:
		TABS.NODES_EDITOR:
			var potential_filename:String = filepaths[0]
			if potential_filename.ends_with("json"):
				if load_definitions_from(filepaths[0]):
					_ui_reset_editor()
		TABS.SAVED_PROGRAMS:
			# FIXME Last minute hack. Add proper error handling, at least
			for filepath in filepaths:
				if not filepath.ends_with(logix_program_extension):
					continue
				var program_filename:String = filepath.get_file().get_basename()
				# Avoid corner cases
				if program_filename.begins_with(logix_program_filename_prefix):
					program_filename = program_filename.replace(
						logix_program_filename_prefix, "")
				var script_content = _read_file_content(filepath)
				if script_content == null:
					printerr("Skipping %s since the file cannot be read" % [filepath])
					continue
				_save_script(program_filename, script_content)
				_ui_scripts_list_refresh()

func _ui_reset_editor():
	ui_edited_node_slots_input_list.clear()
	ui_edited_node_slots_output_list.clear()
	ui_edited_node_slot_name.text = ""
	ui_edited_node_class_name_input.text = ""
	ui_type_editor_list.clear()
	refresh_menus()

func _on_ReloadDefaultsDefButton_pressed():
	printerr("Reloading base definitions")
	selected_node_model = invalid_node
	edited_slot = invalid_slot
	_ui_reset_editor()
	load_definitions_from(base_definitions_filepath)

func _focus_tab_logix():
	ui_tabs.current_tab = TABS.LOGIX_NODES

func _on_LoadExampleButton_pressed():
	_load_script(_read_file_content("res://programs/logix_program_Example.slx"))
	_focus_tab_logix()

