extends HBoxContainer

onready var types_name_list:OptionButton = $TypesNameOptions as OptionButton
onready var type_name_input:LineEdit     = $TypeNameInput as LineEdit

func setup_menu(short_type_names:PoolStringArray) -> void:
	types_name_list.clear()
	for type_name in short_type_names:
		types_name_list.add_item(type_name)
	# FIXME Have to trigger this by hand...
	types_name_list.emit_signal("item_selected", 0)

func _on_CheckButton_toggled(button_pressed):
	types_name_list.visible = !button_pressed
	type_name_input.visible = button_pressed

func get_selected_type_name() -> String:
	return type_name_input.text

func _on_TypesNameOptions_item_selected(index):
	type_name_input.text = types_name_list.get_item_text(index)

