extends Label

func setup_io(title:String, type:String):
	self.text   = title
	self.hint_tooltip = type

func set_tooltip(tooltip:String):
	self.hint_tooltip = tooltip
