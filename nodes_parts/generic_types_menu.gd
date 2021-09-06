extends HBoxContainer

onready var types_name_list:OptionButton = $TypesNameOptions as OptionButton
onready var type_name_input:LineEdit     = $TypeNameInput as LineEdit

signal type_defined(type_name)

func setup_menu(short_type_names:PoolStringArray, selected_type:String) -> void:
	types_name_list.clear()
	# There's no 'find' in PoolStringArray...
	var actual_type_names:Array = Array()
	for type_name in short_type_names:
		match type_name:
			"_primitives":
				for primitive_type in LXNode.get_primitive_types():
					actual_type_names.append(primitive_type)
			_:
				actual_type_names.append(type_name)
	for type_name in actual_type_names:
		types_name_list.add_item(type_name)
	var type_name_idx:int = actual_type_names.find(selected_type)
	if type_name_idx >= 0:
		# Might want to disconnect the signals, just in case...
		types_name_list.select(type_name_idx)
	else:
		_show_raw_edit_mode(true)
		type_name_input.text = selected_type

func _show_raw_edit_mode(status:bool):
	types_name_list.visible = !status
	type_name_input.visible = status

func _on_CheckButton_toggled(button_pressed):
	_show_raw_edit_mode(button_pressed)

func get_selected_type_name() -> String:
	return type_name_input.text

func _on_TypesNameOptions_item_selected(index):
	type_name_input.text = types_name_list.get_item_text(index)
	_signal_type_changed()

func _signal_type_changed():
	printerr("Emitting signal !")
	emit_signal("type_defined", type_name_input.text)

func _on_TypeNameInput_text_entered(_new_text):
	_signal_type_changed()

func _on_TypeNameInput_focus_exited():
	_signal_type_changed()

