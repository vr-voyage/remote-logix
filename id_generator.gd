extends Node

var max_id:int = 1

func generate_id() -> int:
	max_id += 1
	return max_id

func set_max_if_lower_than(id_val:int):
	if max_id <= id_val:
		max_id = id_val + 1
