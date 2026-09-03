extends Node

# mp_test logging shim
const Logging = preload("uid://dotfrtflqu05s")


class ShimAdapter:
	func trace( args: Dictionary = {},
				object:Object = null,
				stack:Array = Logging.get_stack_popped( 1 ) ) -> void:
		EneLog.trace(args, stack, object)


	func lvl(	_p_lvl:int,
				content:Variant,
				object:Object,
				stack:Array ) -> void:
		EneLog.printy( content, [], object, "", stack )


static func _static_init() -> void:
	print("BindLog Static Init")
	await _EneLog.AutoloadReady.when_autoload_ready(
			EneLog, _EneLog.AUTOLOAD_READY_SIGNAL)

	EneLog.disabled = false

	print("Printy Is Ready %s" % EneLog._default_level)
	EneLog.printy("Message from Printy")

	var adapter := ShimAdapter.new()

	# set the logging backend.
	Logging.set_backend(adapter)
	EneLog.printy("Logging Adapter is set")

	Logging.lvl(Logging.Level.TRACE, "Logging Adapter is set")
