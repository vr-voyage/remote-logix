extends Control

class_name LXNodeDefs

const CURRENT_VERSION = 2

var sorted_nodes_indices:PoolIntArray = PoolIntArray()

func find_def(logix_class_name:String) -> LXNode:
	for child in get_children():
		if child.logix_class_name == logix_class_name:
			return child
	printerr("Could not find node definition : " + logix_class_name)
	return null

func get_node_idx(logix_node:LXNode) -> int:
	return get_children().find(logix_node)

func convert_node_to_lxconst(node:LXNode) -> bool:

	if not node._can_become_const_input(node):
		printerr("Node not elligible for conversion")
		return false

	var new_node:LXConstValue = LXConstValue.new()
	new_node._copy_from_lxnode(node)
	node.replace_by(new_node)
	return true

func convert_lxconst_to_node(lxconst:LXConstValue) -> bool:
	lxconst.replace_by(lxconst._to_lxnode())
	return true

func _compare_short_names(idx_a:int, idx_b:int):
	return get_model_node_at(idx_a).get_short_title() < get_model_node_at(idx_b).get_short_title()

func sort_by_short_names():
	var sorted_indices = range(0,get_child_count())
	var i = 0
	sorted_indices.sort_custom(self, "_compare_short_names")
	sorted_nodes_indices.resize(0)
	sorted_nodes_indices.append_array(sorted_indices)

func serialize() -> Dictionary:
	var serialized_defs:Array = Array()
	for node in get_children():
		serialized_defs.append(node.serialize_def())
		
	return {
		"version": CURRENT_VERSION,
		"definitions": serialized_defs,
		"types": LXNode.types_serialize_defs()
	}

func get_model_node_at(idx:int) -> LXNode:
	# ??? If I do return get_child(idx), Godot throws back some stupid error
	# about LXNode not being a Node, but if I define a variable, it's
	# okay !
	var lx_node:LXNode = get_child(idx)
	return lx_node

func _remove_definitions():
	for child in get_children():
		remove_child(child)

var lxnode_scene = preload("res://logix/lxnode.tscn")
var lx_const_value_scene = preload("res://logix/lx_const_value.tscn")

# FIXME That new function is CLEARLY not resilient at all,
# However, I still don't know if we should go for a fail-fast or
# best effort approach here...
func configure_from_serialized(serialized:Dictionary) -> bool:
	_remove_definitions()
	var n_children:int = get_child_count()
	LXNode.types_setup_from_serialized(serialized["types"])
	for definition in serialized["definitions"]:
		var node
		# FIXME Replace this stupid hack by a correct field !
		if not definition.has("editor_grid_size"):
			 node = lxnode_scene.instance()
		else:
			node = lx_const_value_scene.instance()
		add_child(node)
		if node.configure_from_serialized(definition) == false:
			remove_child(node)
			printerr("Could not use definition : " + definition)
			continue
	sort_by_short_names()
	return true

func append(node_definition:LXNode):
	add_child(node_definition)

func _valid_idx(idx:int) -> bool:
	return 0 <= idx && idx < get_child_count()

func instantiate_from_idx(idx:int) -> LXNode:
	if not _valid_idx(idx):
		return null 

	return get_child(idx).complete_dup()

func add_new() -> int:
	var n_nodes:int = get_child_count()
	var new_node:LXNode = LXNode.new()
	new_node.set_class_name("FrooxEngine.LogiX.")
	append(new_node)
	sort_by_short_names()
	return n_nodes
