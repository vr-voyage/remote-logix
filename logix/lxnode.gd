extends GraphNode

class_name LXNode

var logix_class_name:String = ""
var inputs:Array = Array()
var outputs:Array = Array()

const INVALID_NODE_ID:int = 0
# We'll use negative numbers for dealing with write
# slots. So write output/inputs for type number 1
# will be -1.
# So just use 0 for invalid types.
const INVALID_SLOT_TYPE:int = 0
const INVALID_SLOT_COLOR:Color = Color(0,0,0,1)
const CURRENT_ID:Array = Array([1])
# Do NOT duplicate this value
var node_id:int = INVALID_NODE_ID setget set_node_id, get_node_id

enum DIRECTION { INVALID, INPUT, OUTPUT, COUNT }

const GENERIC_NODE_TYPE:int = -1024

func _generate_default_node_id():
	# Oh boy, I got owned by this one.
	# Turns out that the hashing system Godot use is
	# PURE garbage.
	# You'll quickly have duplicate hashes on
	# completely different names.
	# So... the best way is, IMHO, the simplest :
	# Incremental ID
	node_id = IDGenerator.generate_id()

func get_node_id() -> int:
	if node_id == INVALID_NODE_ID:
		_generate_default_node_id()
	return node_id

func set_node_id(new_id:int):
	node_id = new_id
	IDGenerator.set_max_if_lower_than(new_id)

# Why PoolStringArray don't have 'find' ?
const TYPES:Array = ["", "Impulse", "Int", "Float", "Bool"]
const logix_types_colors:Array = [
	Color(0,0,0,0),
	Color(1,1,1,1),
	Color(0,1,0,1),
	Color(0,0,1,0),
	Color(0.3,0.3,0.3,1)
]
const unknown_type_color:Color = Color(0.3,0.3,0.3,1)

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

# Awful hack because Godot is getting me insane
# with its stupid "cyclic" dependencies
class LXNodeSorter:
	static func _sort_serialized_types_by_names(serialized_type_a, serialized_type_b) -> bool:
		return serialized_type_a["name"] < serialized_type_b["name"]

static func types_setup_from_serialized(serialized:Array):
	_reset_types()
	serialized.sort_custom(LXNodeSorter, "_sort_serialized_types_by_names")
	for element in serialized:
		add_logix_type(
			element["name"],
			_color_from_serialized(element["color"]))

static func type_to_value(type_name:String) -> int:
	var value:int = TYPES.find(type_name)
	if value < 0:
		# FIXME This can lead to type names returning the same value
		# as other valid types, due to some coincidence.
		value = type_name.hash()
	return value

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

static func _color_for_type_value(logix_type_value:int) -> Color:
	var color:Color
	if _valid_type_idx(logix_type_value):
		color = logix_types_colors[logix_type_value]
	else:
		color = unknown_type_color
	return color

static func _color_for(logix_type_name:String) -> Color:
	return _color_for_type_value(TYPES.find(logix_type_name))

func _add_slot_to(list:Array) -> NodeSlot:
	var node_to_add:NodeSlot = NodeSlot.new("undefined", TYPES[0])
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



# FIXME ??? Remove this when possible
func get_short_title() -> String:
	return self.title

func get_full_title() -> String:
	return get_short_title() + " (" + self.logix_class_name + ")"

func _title_name() -> String:
	var bracket_pos:int = logix_class_name.find('<')
	if bracket_pos < 0:
		return logix_class_name.get_extension()
	else:
		var specialization_part:String = logix_class_name.substr(bracket_pos)
		var generic_part:String = logix_class_name.substr(0, bracket_pos)
		return generic_part.get_extension() + specialization_part

# TBD : Move away ?
var generic_class_names:Array = ["",""]

func can_connect_to_input(input_idx:int, from_node:LXNode, from_output_idx:int) -> bool:
	return true

func can_connect_to_output(output_idx:int, to_node:LXNode, to_input_idx:int) -> bool:
	return true

func connecting_input(input_idx:int, from_node:LXNode, from_output_idx:int) -> void:
	pass

func connecting_output(output_idx:int, to_node:LXNode, to_input_idx:int) -> void:
	pass

func disconnecting_input(input_idx:int) -> void:
	pass

func disconnecting_output(output_idx:int) -> void:
	pass

func set_class_name(new_logix_class_name:String):
	var class_names:PoolStringArray = new_logix_class_name.split(",")
	self.logix_class_name = class_names[0]
	for i in range(1, len(class_names)):
		generic_class_names.append(_get_short_name(class_names[i]))
	self.title = _title_name()

func _valid_dir_value(dir_value:int) -> bool:
	return DIRECTION.INVALID < dir_value and dir_value < DIRECTION.COUNT

var simple_io = preload("res://nodes_parts/simple_io.tscn")

func _set_input_slot(slot_idx:int, slot_def:NodeSlot):
	var new_slot_type:int = type_to_value(slot_def.logix_type)
	set_slot(slot_idx, 
		true, new_slot_type, _color_for_type_value(new_slot_type),
		false, INVALID_SLOT_TYPE, INVALID_SLOT_COLOR)

func _set_output_slot(slot_idx:int, slot_def:NodeSlot):
	var new_slot_type:int = type_to_value(slot_def.logix_type)
	set_slot(slot_idx,
		false, INVALID_SLOT_TYPE, INVALID_SLOT_COLOR,
		true, new_slot_type, _color_for_type_value(new_slot_type))

func _display_slot(slot_def:NodeSlot, direction:int):
	if not _valid_dir_value(direction):
		printerr("Invalid direction value : " + str(direction))
		return

	var n_slots:int = get_child_count()
	var label = simple_io.instance()
	label.setup_io(slot_def.title, slot_def.logix_type)
	add_child(label)
	match direction:
		DIRECTION.INPUT:
			_set_input_slot(n_slots, slot_def)
		DIRECTION.OUTPUT:
			_set_output_slot(n_slots, slot_def)
			label.align = Label.ALIGN_RIGHT

func gen_csharp_names() -> Dictionary:
	var charp_type_names:Dictionary = {
		"bool":    "System.Bool",
		"bool2":   "BaseX.bool2",
		"bool3":   "BaseX.bool3",
		"bool4":   "BaseX.bool4",
		"byte":    "System.Byte",
		"char":    "System.Char",
		"color":   "BaseX.color",
		"floatQ":  "BaseX.floatQ",
		"doubleQ": "BaseX.doubleQ",
		"short":   "System.Int16",
		"int":     "System.Int32",
		"long":    "System.Int64",
	}
	for t in ["bool", "double", "float", "int", "long", "uint", "ulong"]:
		for n in ["2", "3", "4"]:
			var short_name:String = t + n
			charp_type_names[short_name] = "BaseX." + short_name
	for t in ["float", "double"]:
		for n in ["2", "3", "4"]:
			var short_name:String = t + n + "x" + n
			charp_type_names[short_name] = "BaseX." + short_name
	return charp_type_names

onready var csharp_names:Dictionary = gen_csharp_names()

func _get_csharp_class_name_for(type:String) -> String:
	if csharp_names.has(type):
		return csharp_names[type]
	else:
		if type.find(".") >= 0:
			return type
		else:
			return "FrooxEngine." + type

func _get_short_name(full_type_name:String) -> String:
	for k in csharp_names.keys():
		if csharp_names[k] == full_type_name:
			return k
	return full_type_name

func get_logix_class_full_name() -> String:
	return logix_class_name

func _regenerate_slots() -> void:
	for child in get_children():
		remove_child(child)
	for input_slot in inputs:
		_display_slot(input_slot, DIRECTION.INPUT)
	for output_slot in outputs:
		_display_slot(output_slot, DIRECTION.OUTPUT)

func refresh_slots_style():
	_regenerate_slots()

func set_io(new_inputs:Array, new_outputs: Array):
	self.inputs = new_inputs
	self.outputs = new_outputs
	refresh_slots_style()

# FIXME Fail fast or best effort ?
func _parse_slots(serialized_slots_defs:Array, out_list:Array):
	for serialized_slot_def in serialized_slots_defs:
		var node_slot:NodeSlot = NodeSlot.new("invalid", TYPES[0])
		if node_slot.config_from_serialized(serialized_slot_def):
			out_list.append(node_slot)
		else:
			printerr("Could not add a serialized slot")

func configure_from_serialized(serialized_node:Dictionary) -> bool:
	if (not serialized_node.has("inputs") or 
		not serialized_node.has("outputs") or
		not serialized_node.has("classname")):
		printerr("Missing fields in serialized node definition :\n" +
			"inputs, outputs.\n" +
			"Definition :" + str(serialized_node))
		return false
	var deser_inputs:Array = Array()
	var deser_outputs:Array = Array()
	# FIXME Fail fast or best effort ?
	# We're using a best effort approach here, but I wonder
	# if that's really a good idea
	_parse_slots(serialized_node["inputs"], deser_inputs)
	_parse_slots(serialized_node["outputs"], deser_outputs)
	set_class_name(serialized_node["classname"])
	set_io(deser_inputs, deser_outputs)
	return true

func _serialize_slots_defs(slots_list:Array, defs_list:Array):
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
		"outputs": serialized_outputs,
		"type": "Standard"
	}

func complete_dup():
	var duplicate_node = self.duplicate()
	# These fields are kind of 'constant' anyway, so that
	# should do the trick for now
	duplicate_node.inputs              = self.inputs
	duplicate_node.outputs             = self.outputs
	duplicate_node.logix_class_name    = self.logix_class_name
	duplicate_node.generic_class_names = self.generic_class_names
	# FIXME Make this a constant !
	duplicate_node.csharp_names = csharp_names
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

func get_output_type(output_slot_idx:int) -> String:
	return outputs[output_slot_idx].logix_type

func get_input_type(input_slot_idx:int) -> String:
	return inputs[input_slot_idx].logix_type

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

# FIXME Move this away
static func _is_lowercase_string(s:String) -> bool:
	return s.to_lower() == s

# This should be prepared once and for all !
static func get_primitive_types() -> PoolStringArray:
	var primitives_types:PoolStringArray = PoolStringArray()
	for t in TYPES:
		if _is_lowercase_string(t):
			primitives_types.append(t)
	return primitives_types
