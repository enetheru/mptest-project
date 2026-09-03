extends MPTVariable

# an example of setting up a simple binary choice variable.

func _init() -> void:
	id = 'bin'
	width = 1
	Mode = { ø = 0x0, ON = 0x1 }
	stubs = { Mode.ø:'∅', Mode.ON:'●', }

	#descriptions  = {
		#Mode.ø:'%s is off.' % id,
		#Mode.ON:'%s is on.' % id,
	#}

	# Would need to add tests, or rules too.
