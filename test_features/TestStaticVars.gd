extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

class A:
	const wonderful_table:Array = ["Nya"]

func b(arr:Array):
	arr.append("fezfzefze")

# Called when the node enters the scene tree for the first time.
func _ready():
	printerr(A.wonderful_table[0])
	A.wonderful_table.append("Meow")
	printerr(A.wonderful_table[1])
	var arr:Array = Array()
	b(arr)
	printerr(arr)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
