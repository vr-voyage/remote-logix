extends Control

onready var ui_tree = $"ScrollContainer/VBoxContainer/Tree" as Tree

signal node_selected(node)

# Note
# I'm using Tree and TreeItem because I'm way too lazy to remake
# yet another tree view for Godot.
# Still, Tree and TreeItem are HORRENDOUS, for multiple reasons.
# The main one being that THERE'S ALREADY A TREE BASED HIERARCHY
# IN GODOT !! It's the main scene hierarchy, it's how it WORKS.
# It has nice features like "find_path" and all the things, which
# make it way more useful that Tree, which doesn't even have a way
# to ping the hierarchy in a clean fashion.
# I don't know how to pull out a decent UI to represent a SceneTree
# hierachy so I'm using Tree and TreeItem but... UGH...
# This should be replaced, IMHO

const separator:String = "."

var root_item:TreeItem

func _is_item(tree_item:TreeItem) -> bool:
	return tree_item.get_children() == null

# FIXME
# Move this to LXNode !
func _relative_class_name(logix_node:LXNode) -> String:
	return logix_node.logix_class_name.replace("FrooxEngine.LogiX.", "")

func _add_logix_nodes(logix_nodes:Array, tree_cache:Dictionary, tree:Tree = ui_tree):
	for logix_node in logix_nodes:
		var logix_node_name:String = _relative_class_name(logix_node)
		var logix_node_path:String = logix_node_name.get_basename()
		var logix_node_classname:String = logix_node_name.get_extension()

		if not tree_cache.has(logix_node_path):
			printerr("Cache is broken and should have references for %s" % logix_node_path)
			continue

		var tree_parent:TreeItem = tree_cache[logix_node_path] as TreeItem
		var new_item:TreeItem = tree.create_item(tree_parent)
		new_item.set_text(0, _readable_logix_name(logix_node_classname))
		new_item.set_metadata(0, logix_node)
		tree_cache[logix_node_name] = new_item

func _node_parent_category_name(node_classname:String) -> String:
	var separator_idx = node_classname.find_last(separator)
	if separator_idx == -1:
		separator_idx = 0
	return node_classname.substr(separator_idx)

func _prepare_tree_categories(logix_nodes:Array, tree_cache:Dictionary, tree:Tree = ui_tree):
	for logix_node in logix_nodes:
		var logix_node_name = _relative_class_name(logix_node)
		var n_separators:int = logix_node_name.count(separator)
		if n_separators == 0:
			continue

		# The separator is actually a dot, so we can use
		# get_basename() here
		var logix_node_path:String = logix_node_name.get_basename()

		var parent_separator_idx:int = 0
		var separator_idx:int = 0

		printerr("%d separators in %s" % [n_separators, logix_node_name])
		for _i in n_separators:
			parent_separator_idx = separator_idx
			separator_idx = logix_node_path.find(separator, (separator_idx+1))
			var sub_path = logix_node_path.substr(0, separator_idx)
			if not tree_cache.has(sub_path):
				var parent_path:String = logix_node_path.substr(0, parent_separator_idx)
				var parent_item:TreeItem = tree_cache.get(parent_path, root_item)
				# The separator being a '.', we can use get_extension() to get the
				# latest part
				var category:String = _node_parent_category_name(sub_path)
				var category_item:TreeItem = tree.create_item(parent_item)
				category_item.set_text(0, _readable_logix_name(category))
				printerr("Category of %s : %s" % [logix_node_path, category])
				tree_cache[sub_path] = category_item
				category_item.collapsed = true

func _readable_logix_name(logix_node_name:String):
	return logix_node_name.replace("_", " ")

func prepare_using_logix_nodes(logix_nodes_definitions:Array):
	var tree_cache:Dictionary = Dictionary()
	root_item = ui_tree.create_item(null)
	_prepare_tree_categories(logix_nodes_definitions, tree_cache)
	_add_logix_nodes(logix_nodes_definitions, tree_cache)

func _ready():
	root_item = ui_tree.create_item(null)

func _on_Tree_item_activated():
	var selected_item:TreeItem = ui_tree.get_selected()
	if (selected_item == null):
		printerr("[BUG] Tree is broken. Sent 'activated signal with no selection")
		return

	var selected_node_def:LXNode = selected_item.get_metadata(0) as LXNode
	if selected_node_def != null:
		emit_signal("node_selected", selected_node_def)
	pass # Replace with function body.

# FIXME
# This behaviour should not be set there.
# Emit the appropriate signals
# Catch them in the main UI
func _on_Tree_focus_exited():
	release_focus()
	hide()

func _on_Control_focus_entered():
	ui_tree.grab_focus()
	pass # Replace with function body.
