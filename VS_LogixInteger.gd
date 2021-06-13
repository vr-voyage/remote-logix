tool
extends VisualScriptCustomNode

func _get_output_value_port_count():
	return 1

func _get_output_value_port_name(idx):
	return "value"

func _get_caption():
	return "Logix Integer"

func _get_output_value_port_type(idx):
	return TYPE_INT

func _get_category():
	return "LogiX"

