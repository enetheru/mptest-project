@tool
extends RichTextLabel

## Host / join / offline / spawn panel that drives an [MPTEnetOb].
## Replaces the HelloWorld [code]NM[/code] + UDPecan auto-network tab.

const Util = preload("uid://bnihbelkt5wkt")

#region trace
const Log = preload( "uid://dotfrtflqu05s" )
static var class_lvl:int = Log.Level.SILENT
@export_enum("SILENT:0","CRITICAL:1","ERROR:3","WARNING:7",
		"NOTICE:15","INFO:31","DEBUG:63","TRACE:127","MASK:255")
var local_lvl:int = Log.Level.SILENT
func trace( args:Dictionary = {}, object:Object = self,
			stack:Array = Log.get_stack_popped( 1 ) ) -> void:
	Log.trace( args, object, stack )
func trace_lvl( lvl:int, content:Variant, object:Object = null,
			stack:Array = Log.get_stack_popped() ) -> void:
	Log.lvl( lvl, content, object, stack )
#endregion


# ██████  ██████   ██████  ██████  ███████ ██████  ████████ ██ ███████ ███████ #
# ██   ██ ██   ██ ██    ██ ██   ██ ██      ██   ██    ██    ██ ██      ██      #
# ██████  ██████  ██    ██ ██████  █████   ██████     ██    ██ █████   ███████ #
# ██      ██   ██ ██    ██ ██      ██      ██   ██    ██    ██ ██           ██ #
# ██      ██   ██  ██████  ██      ███████ ██   ██    ██    ██ ███████ ███████ #
func                        ________PROPERTIES_______              ()->void:pass

@export var netob:MPTEnetOb
@export var runner:MPTRunner


#             ███████ ██    ██ ███████ ███    ██ ████████ ███████              #
#             ██      ██    ██ ██      ████   ██    ██    ██                   #
#             █████   ██    ██ █████   ██ ██  ██    ██    ███████              #
#             ██       ██  ██  ██      ██  ██ ██    ██         ██              #
#             ███████   ████   ███████ ██   ████    ██    ███████              #
func                        __________EVENTS_________              ()->void:pass

func _on_net_changed( _a:Variant = null, _b:Variant = null ) -> void:
	update_text()


func _on_meta_clicked( meta:String ) -> void:
	trace({&'meta': meta})
	if not is_instance_valid(netob):
		return
	match meta:
		"offline":
			netob.start_offline()
		"client":
			netob.start_client()
		"host":
			netob.start_server()
		"stop_server", "disconnect", "delete":
			netob.reset_network()
		"spawn":
			if is_instance_valid(runner):
				runner.spawn_new_debug_instance()
		"refresh":
			pass
		_:
			if meta.begins_with("kick="):
				netob.kick_peer(meta.get_slice("=", 1).to_int())
	update_text()


#      ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████     #
#     ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██          #
#     ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████     #
#     ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██     #
#      ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████     #
func                        ________OVERRIDES________              ()->void:pass

func _enter_tree() -> void:
	trace()
	bbcode_enabled = true
	Util.safe_connect(meta_clicked, _on_meta_clicked)
	if Engine.is_editor_hint():
		return
	if not is_instance_valid(netob):
		return
	Util.safe_connect(netob.peer_connected, _on_net_changed)
	Util.safe_connect(netob.peer_disconnected, _on_net_changed)
	Util.safe_connect(netob.connected_to_server, _on_net_changed)
	Util.safe_connect(netob.server_disconnected, _on_net_changed)
	Util.safe_connect(netob.server_started, _on_net_changed)
	Util.safe_connect(netob.server_stopped, _on_net_changed)
	Util.safe_connect(netob.client_started, _on_net_changed)
	Util.safe_connect(netob.stopping_network, _on_net_changed)


func _ready() -> void:
	trace()
	update_text()


#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass

func centre( string:String ) -> String:
	return "[center]%s[/center]" % string


func nl( string:String ) -> void:
	text += "\n%s" % string


func update_text() -> void:
	text = centre("ENet Network")
	if not is_instance_valid(netob):
		nl("No MPTEnetOb assigned.")
		return

	nl("Address: %s:%d" % [netob.address, netob.port])
	nl("Status: %s" % netob.get_status_string())

	var netid_string:String = "Unique ID: "
	if netob.is_server() or netob.is_client():
		netid_string += Util.id_str(netob.get_unique_id())
	else:
		netid_string += "OFFLINE"
	nl(netid_string)

	if netob.is_server():
		nl("peers = {")
		for peer_id:int in netob.get_peers():
			nl("  " + Util.link("kick=%d" % peer_id, Util.id_str(peer_id)))
		nl("}")

	nl(centre("\nOptions"))
	if netob.is_server() or netob.is_client():
		nl(centre(Util.link("delete", "Drop Multiplayer Peer")))
		if netob.is_server():
			nl(centre(Util.link("stop_server", "Stop Server")))
		else:
			nl(centre(Util.link("disconnect", "Disconnect")))
	else:
		nl(centre(Util.link("offline", "Offline Peer")))
		nl(centre(Util.link("client", "Connect to ENet Server")))
		nl(centre(Util.link("host", "Host an ENet Server")))
	nl(centre(Util.link("refresh", "Refresh This Text")))
	nl(centre(Util.link("spawn", "Spawn a new Godot instance")))
