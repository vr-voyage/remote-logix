extends Control

onready var graph:GraphEdit = $"TabContainer/Maincontainer/Program"

const LogixNode = preload("res://LogixNode.tscn")

class LXNode extends GraphNode:
	var logix_class_name:String = ""
	var inputs:PoolStringArray = PoolStringArray()
	var outputs:PoolStringArray = PoolStringArray()

	func complete_dup() -> LXNode:
		var duplicate_node:LXNode = self.duplicate()
		# These fields are kind of 'constant' anyway, so that
		# should do the trick for now
		duplicate_node.inputs = self.inputs
		duplicate_node.outputs = self.outputs
		duplicate_node.logix_class_name = self.logix_class_name
		return duplicate_node

	enum DIRECTION { INVALID, INPUT, OUTPUT, COUNT }

	enum TYPES { INVALID, IMPULSE, INT, FLOAT, BOOL, COUNT }

	# FIXME This construction is horrible
	const logix_types = {
		"_unknown": {"value": TYPES.INVALID, "color": Color(0,0,0,1)},
		"impulse":  {"value": TYPES.IMPULSE, "color": Color(1,1,1,1)},
		"int":      {"value": TYPES.INT, "color": Color(0,1,0,1)},
		"float":    {"value": TYPES.FLOAT, "color": Color(0,0,1,0)},
		"bool":     {"value": TYPES.BOOL, "color": Color(0.3,0.3,0.3,1)}
	}

	func register_slot(
		slot_title:String,
		logix_type_name:String,
		direction:int):

		if direction <= DIRECTION.INVALID || direction >= DIRECTION.COUNT:
			printerr("Invalid direction value : " + str(direction))
			return

		var n_slots:int = get_child_count()
		var actual_type_name:String = (
			logix_type_name if logix_types.has(logix_type_name)
			else "_unknown")
		var type_infos:Dictionary = logix_types[actual_type_name]
		var label:Label = Label.new()
		label.text = slot_title
		add_child(label)
		match direction:
			DIRECTION.INPUT:
				set_slot(n_slots, 
					true, type_infos["value"], type_infos["color"],
					false, -1, Color(0,0,0,1))
				inputs.append(slot_title)
			DIRECTION.OUTPUT:
				set_slot(n_slots,
					false, -1, Color(0,0,0,1),
					true, type_infos["value"], type_infos["color"])
				outputs.append(slot_title)
				label.align = Label.ALIGN_RIGHT

	func _get_name_from_list(idx:int, list:PoolStringArray) -> String:
		if 0 <= idx and idx < len(list):
			return list[idx]
		printerr(
			"Invalid slot index : " + str(idx) + 
			" (Max : " + str(len(list)) + ")")
		return ""

	func get_input_name(input_slot_idx:int) -> String:
		return _get_name_from_list(input_slot_idx, inputs)

	func get_output_name(output_slot_idx:int) -> String:
		return _get_name_from_list(output_slot_idx, outputs)

	func _ready():
		rect_min_size = Vector2(0,80)

# FIXME Seriously, parse this from JSON files...
# And complete the editor !
var nodes_serialized:Dictionary = {
	"FrooxEngine.LogiX.Operators.Add_Int": {
		"slots": [
			{"name": "A", "type": "int", "direction": LXNode.DIRECTION.INPUT},
			{"name": "B", "type": "int", "direction": LXNode.DIRECTION.INPUT},
			{"name": "*", "type": "int", "direction": LXNode.DIRECTION.OUTPUT}
		],
	},
	"FrooxEngine.LogiX.Math.Abs_Int": {
		"slots": [
			{"name": "N", "type": "int", "direction": LXNode.DIRECTION.INPUT},
			{"name": "*", "type": "int", "direction": LXNode.DIRECTION.OUTPUT}
		]
	},
	"FrooxEngine.LogiX.ProgramFlow.IfNode": {
		"slots": [
			{"name": "Run",       "type": "impulse", "direction": LXNode.DIRECTION.INPUT},
			{"name": "Condition", "type": "bool",    "direction": LXNode.DIRECTION.INPUT},
			{"name": "True",      "type": "impulse", "direction": LXNode.DIRECTION.OUTPUT},
			{"name": "False",     "type": "impulse", "direction": LXNode.DIRECTION.OUTPUT}
		]
	},
	"FrooxEngine.LogiX.ProgramFlow.ForNode": {
		"slots": [
			{"name": "Run", "type": "impulse", "direction": LXNode.DIRECTION.INPUT},
			{"name": "Count", "type": "int", "direction": LXNode.DIRECTION.INPUT},
			{"name": "Reverse", "type": "bool", "direction": LXNode.DIRECTION.INPUT},
			{"name": "LoopStart", "type": "impulse", "direction": LXNode.DIRECTION.OUTPUT},
			{"name": "LoopIteration", "type": "impulse", "direction": LXNode.DIRECTION.OUTPUT},
			{"name": "LoopEnd", "type": "impulse", "direction": LXNode.DIRECTION.OUTPUT},
			{"name": "Iteration", "type": "int", "direction": LXNode.DIRECTION.OUTPUT},
		]
	},
	"FrooxEngine.LogiX.Operators.Equals_Int": {
		"slots": [
			{"name": "A", "type": "int", "direction": LXNode.DIRECTION.INPUT},
			{"name": "B", "type": "int", "direction": LXNode.DIRECTION.INPUT},
			{"name": "*", "type": "bool", "direction": LXNode.DIRECTION.OUTPUT}
		]
	}
}

var useable_nodes:Array
var useable_nodes_sorted_by_names:Array
func prepare_useable_nodes() -> void:
	useable_nodes.clear()
	for serialized_node_name in nodes_serialized.keys():
		var logix_node:LXNode = LXNode.new()
		var serialized_infos:Dictionary = nodes_serialized[serialized_node_name]
		var short_name:String = serialized_node_name.get_extension()
		logix_node.title = short_name

		for slot_infos in serialized_infos["slots"]:
			logix_node.register_slot(
				slot_infos["name"], slot_infos["type"],
				slot_infos["direction"])

		useable_nodes.append(logix_node)
		logix_node.name = short_name
		# FIXME Set the title when setting up the class name
		logix_node.logix_class_name = serialized_node_name
		

onready var ui_popup_menu:PopupMenu = $PopupMenu
func _sort_menu_entries(a, b) -> bool:
	return a["short_title"] < b["short_title"]

func prepare_popup_menu() -> void:
	ui_popup_menu.clear()
	var sorted_items:Array = []
	var i = 0
	for available_node in useable_nodes:
		var logix_class_name:String = available_node.logix_class_name
		var short_title:String = available_node.title
		var menu_entry:String = short_title + " (" + logix_class_name + ")"
		sorted_items.append({"short_title": short_title, "menu_title": menu_entry, "id": i})
		i += 1
	sorted_items.sort_custom(self, "_sort_menu_entries")
	for sorted_item in sorted_items:
		ui_popup_menu.add_item(sorted_item["menu_title"], sorted_item["id"])
	useable_nodes_sorted_by_names = sorted_items

onready var ui_nodes_list_option:OptionButton = $TabContainer/VBoxContainer/NodesListButton
onready var ui_slot_types_option:OptionButton = $TabContainer/VBoxContainer/SlotTypeOptions
func prepare_editor() -> void:
	ui_nodes_list_option.clear()
	for sorted_item in useable_nodes_sorted_by_names:
		ui_nodes_list_option.add_item(
			sorted_item["menu_title"], sorted_item["id"])
	var type_names:Array = LXNode.TYPES.keys()
	for i in range(1, len(type_names)):
		ui_slot_types_option.add_item(type_names[i], i)

func refresh_menus() -> void:
	prepare_useable_nodes()
	prepare_popup_menu()
	prepare_editor()
	print(LXNode.TYPES.keys())

func _ready():
	refresh_menus()

func node_id(graph_node:GraphNode) -> int:
	return graph_node.name.hash()

func node_id_from_name(graph_node_name:String) -> int:
	return graph_node_name.hash()

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

func _on_GraphEdit_paste_nodes_request():
	# I have zero idea how to handle that
	printerr("Paste nodes request")


func _on_PopupMenu_id_pressed(id):
	var logix_node:LXNode = useable_nodes[id]
	logix_node.offset = ui_popup_menu.rect_position
	graph.add_child(useable_nodes[id].complete_dup())

func line(line:String) -> String:
	 return line + "\n"

func serialize_current_program(program_name:String) -> String:
	var serialized_program = line("P," + program_name)

	for child in graph.get_children():
		if not child is LXNode:
			continue
		var logix_node:LXNode = child
		var instruction:PoolStringArray = PoolStringArray()
		instruction.append("N")
		instruction.append(str(node_id(logix_node)))
		instruction.append(logix_node.logix_class_name)
		instruction.append(logix_node.title)
		serialized_program += line(instruction.join(","))

	# FIXME Iterate through the connections and list them
	for connection in graph.get_connection_list():
		var to_node_uncast:Node   = graph.get_node(connection["to"])
		var from_node_uncast:Node = graph.get_node(connection["from"])
		if (not to_node_uncast is LXNode) or (not from_node_uncast is LXNode):
			printerr(
				"Won't handle connection between : " + connection["from"] + 
				" and " + connection["to"])
			printerr(to_node_uncast)
			printerr(from_node_uncast)
			continue

		var to_node:LXNode   = to_node_uncast
		var from_node:LXNode = from_node_uncast
		var to_slot:int      = connection["to_port"]
		var from_slot:int    = connection["from_port"]
		var input_type:int   = to_node.get_slot_type_left(to_slot)
		var instruction:PoolStringArray = PoolStringArray()
		# FIXME Put this as a function, at least...
		if input_type != LXNode.TYPES.IMPULSE:
			instruction.append("I")
		else:
			instruction.append("IM")

		instruction.append(str(node_id(to_node)))
		instruction.append(str(to_slot))
		instruction.append(to_node.get_input_name(to_slot))
		instruction.append(str(node_id(from_node)))
		instruction.append(str(from_slot))
		instruction.append(from_node.get_output_name(from_slot))
		serialized_program += line(instruction.join(","))

		printerr(connection)
	return serialized_program

func save_program(program_name:String):
	var serialized_program:String = serialize_current_program(program_name)
	printerr(serialized_program)
	return
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

onready var ui_program_name_text = $TabContainer/Maincontainer/Program/Metadata/NameInput

func _on_SaveButton_pressed():
	var program_name:String = ui_program_name_text.text
	# FIXME Sanitize filenames
	# Check if the sanitized filenames still have characters in it
	if program_name.strip_edges().empty():
		# FIXME Throw a real error message
		printerr("Meep ! Provide a name for the program")
		return
	save_program(program_name)

func _on_Program_delete_nodes_request():
	printerr("Deletion of multiple nodes requested")

var useable_nodes_selected:int = -1
func get_edited_useable_node() -> LXNode:
	var n_useable_nodes:int = len(useable_nodes)
	if useable_nodes_selected < 0 || useable_nodes_selected >= n_useable_nodes:
		printerr("Invalid useable node index : " + str(useable_nodes_selected))
		printerr("Max : " + str(n_useable_nodes))
		return null
	var uncasted_node = useable_nodes[useable_nodes_selected]
	if not uncasted_node is LXNode:
		printerr("useable_nodes[" + str(useable_nodes_selected) + "] is invalid")
		printerr(str(uncasted_node))
		return null
	return uncasted_node

var edited_slot
func modify_edited_slot():
	if edited_slot == null:
		printerr("The edited slot is not set !?")
		return

	var node:LXNode = get_edited_useable_node()
	if node == null:
		printerr("Can't edit slots of invalid nodes")
		return

	var slot_name:String = ui_edited_node_class_name_input.text
	var slot_type:int = ui_edited_node_type_options.get_selected_id()
	
	edited_slot.change(slot_name, slot_type)

onready var ui_edited_node_slots_list = $TabContainer/VBoxContainer/SlotsList
onready var ui_edited_node_class_name_input = $TabContainer/VBoxContainer/ClassNameInput
onready var ui_edited_node_type_options = $TabContainer/VBoxContainer/SlotTypeOptions
func edit_node(useable_node_idx:int):
	var n_useable_nodes:int = len(useable_nodes)
	# FIXME factorize
	if useable_node_idx < 0 || useable_node_idx >= n_useable_nodes:
		printerr("Invalid node index provided : " + str(useable_node_idx))
		printerr("Max : " + str(n_useable_nodes))
		return
	var node_uncast = useable_nodes[useable_node_idx]
	if not node_uncast is LXNode:
		printerr(
			"Useable node " + str(useable_node_idx) + 
			" is actually unuseable. (" + str(node_uncast) + ")")
		return
	useable_nodes_selected = useable_node_idx

	var node:LXNode = node_uncast
	ui_edited_node_slots_list.clear()
	ui_edited_node_class_name_input.text = node.logix_class_name
	for title in node.inputs:
		ui_edited_node_slots_list.add_item(title)
	for title in node.outputs:
		ui_edited_node_slots_list.add_item(title)

func _on_NodesListButton_item_selected(index):
	var actual_idx:int = ui_nodes_list_option.get_item_id(index)
	edit_node(actual_idx)

func _on_ClassNameInput_text_entered(new_text):
	var node:LXNode = get_edited_useable_node()
	if node == null:
		return
	node.logix_class_name = new_text
	pass # Replace with function body.
