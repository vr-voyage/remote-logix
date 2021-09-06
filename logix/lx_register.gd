extends LXGenericWithMenu

class_name LXRegister

# Turns out that it's a generic node now.

# In order to emulate the "write to register",
# with the Write "Target" being connected to
# an empty space near the register, we basically
# add an IValue`1 input
# This input will have the color of the register
# type, but the "IValue`1" internal type id.

# This makes it easier to connect Write nodes
# to registers, using this "wonderful" Grid
# system.

func change_write_slot_color(type_name:String):
	# FIXME
	# Horrendous hack for Alpha 2. Get rid of this
	# Basically, we just change the color of the
	# write slot we added to deal with write connections.
	set_slot(0,
		true, type_to_value("IValue`1"), _color_for(type_name),
		false, INVALID_SLOT_TYPE, INVALID_SLOT_COLOR)
	get_child(0).set_tooltip("IValue`1," + type_name)

func _cb_selected_generic_type_from_menu(type_name:String):
	printerr(type_name)
	._cb_selected_generic_type_from_menu(type_name)
	change_write_slot_color(type_name)
