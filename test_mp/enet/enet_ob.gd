@tool
class_name MPTEnetOb
extends Node
##[codeblock lang=text]
##│ __  __ ___ _____ ___          _    ___  _
##│|  \/  | _ \_   _| __|_ _  ___| |_ / _ \| |__
##│| |\/| |  _/ | | | _|| ' \/ -_)  _| (_) | '_ \
##│|_|  |_|_|   |_| |___|_||_\___|\__|\___/|_.__/
##╰────────────────────────────────────────────────
##[/codeblock]ENet MultiplayerPeer for local host and join.
##
## Sets [member MultiplayerAPI.multiplayer_peer] on this node's
## [member Node.multiplayer] (the SceneTree API by default). The runner's
## [MPTControlPlaneRpc] rides that same API; this node only establishes the
## peer. No HelloWorld [code]NM[/code] / UDPecan.

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


enum Status {
	CONNECTED = MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED,
	CONNECTING = MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTING,
	DISCONNECTED = MultiplayerPeer.ConnectionStatus.CONNECTION_DISCONNECTED,
}


# ██████  ██████   ██████  ██████  ███████ ██████  ████████ ██ ███████ ███████ #
# ██   ██ ██   ██ ██    ██ ██   ██ ██      ██   ██    ██    ██ ██      ██      #
# ██████  ██████  ██    ██ ██████  █████   ██████     ██    ██ █████   ███████ #
# ██      ██   ██ ██    ██ ██      ██      ██   ██    ██    ██ ██           ██ #
# ██      ██   ██  ██████  ██      ███████ ██   ██    ██    ██ ███████ ███████ #
func                        ________PROPERTIES_______              ()->void:pass

## TCP/UDP port for [method start_server] / [method start_client].
@export var port:int = 24567

## Address [method start_client] connects to.
@export var address:String = "127.0.0.1"

## ENet server slot count (not used for offline).
@export var max_clients:int = 8

## HelloWorld UDPecan auto-promoted to server. Do the same on play.
enum AutoStart { NONE, OFFLINE, SERVER }
@export var auto_start:AutoStart = AutoStart.SERVER

var _hosting:bool = false


#            ███████ ██  ██████  ███    ██  █████  ██      ███████             #
#            ██      ██ ██       ████   ██ ██   ██ ██      ██                  #
#            ███████ ██ ██   ███ ██ ██  ██ ███████ ██      ███████             #
#                 ██ ██ ██    ██ ██  ██ ██ ██   ██ ██           ██             #
#            ███████ ██  ██████  ██   ████ ██   ██ ███████ ███████             #
func                        _________SIGNALS_________              ()->void:pass

signal stopping_network
signal server_started
signal server_stopped
signal client_started
signal connected_to_server
signal server_disconnected
signal peer_connected(peer_id:int)
signal peer_disconnected(peer_id:int)


#             ███████ ██    ██ ███████ ███    ██ ████████ ███████              #
#             ██      ██    ██ ██      ████   ██    ██    ██                   #
#             █████   ██    ██ █████   ██ ██  ██    ██    ███████              #
#             ██       ██  ██  ██      ██  ██ ██    ██         ██              #
#             ███████   ████   ███████ ██   ████    ██    ███████              #
func                        __________EVENTS_________              ()->void:pass

func _on_mp_peer_connected( peer_id:int ) -> void:
	peer_connected.emit(peer_id)


func _on_mp_peer_disconnected( peer_id:int ) -> void:
	peer_disconnected.emit(peer_id)


func _on_mp_connected_to_server() -> void:
	connected_to_server.emit()


func _on_mp_connection_failed() -> void:
	reset_network()


func _on_mp_server_disconnected() -> void:
	server_disconnected.emit()
	reset_network()


#      ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████     #
#     ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██          #
#     ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████     #
#     ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██     #
#      ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████     #
func                        ________OVERRIDES________              ()->void:pass

func _init() -> void:
	name = "EnetProvider"


func _enter_tree() -> void:
	trace()
	if Engine.is_editor_hint():
		return
	var api:MultiplayerAPI = multiplayer
	if not is_instance_valid(api):
		return
	Util.safe_connect(api.peer_connected, _on_mp_peer_connected)
	Util.safe_connect(api.peer_disconnected, _on_mp_peer_disconnected)
	Util.safe_connect(api.connected_to_server, _on_mp_connected_to_server)
	Util.safe_connect(api.connection_failed, _on_mp_connection_failed)
	Util.safe_connect(api.server_disconnected, _on_mp_server_disconnected)


func _ready() -> void:
	trace()
	if Engine.is_editor_hint():
		return
	if _wants_join():
		start_client()
		return
	match auto_start:
		AutoStart.OFFLINE:
			start_offline()
		AutoStart.SERVER:
			if not _try_start_server():
				start_client()
		_:
			pass


#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass

func reset_network() -> void:
	trace()
	if not _has_peer():
		return
	stopping_network.emit()
	if _hosting:
		server_stopped.emit()
	multiplayer.multiplayer_peer = null
	_hosting = false


func start_server() -> void:
	trace()
	if _try_start_server():
		return
	trace_lvl(Log.Level.ERROR, "create_server failed on port %d" % port)


func _try_start_server() -> bool:
	reset_network()
	var enet := ENetMultiplayerPeer.new()
	var err:Error = enet.create_server(port, max_clients)
	if err != OK:
		return false
	multiplayer.multiplayer_peer = enet
	_hosting = true
	server_started.emit()
	return true


func _wants_join() -> bool:
	var args:PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()
	return "--mpt-join" in args


func start_client() -> void:
	trace()
	reset_network()
	var enet := ENetMultiplayerPeer.new()
	var err:Error = enet.create_client(address, port)
	if err != OK:
		trace_lvl(Log.Level.ERROR, "create_client: %s" % error_string(err))
		return
	multiplayer.multiplayer_peer = enet
	_hosting = false
	client_started.emit()


func is_client() -> bool:
	return _has_peer() and not multiplayer.is_server()


func is_server() -> bool:
	return _has_peer() and multiplayer.is_server()


func get_status() -> int:
	if not _has_peer():
		return Status.DISCONNECTED
	match multiplayer.multiplayer_peer.get_connection_status():
		MultiplayerPeer.CONNECTION_CONNECTING:
			return Status.CONNECTING
		MultiplayerPeer.CONNECTION_CONNECTED:
			return Status.CONNECTED
		_:
			return Status.DISCONNECTED


func get_status_string() -> String:
	return str(Status.find_key(get_status()))


func get_peers() -> PackedInt32Array:
	if not _has_peer():
		return PackedInt32Array()
	return multiplayer.get_peers()


func get_unique_id() -> int:
	if not _has_peer():
		return 0
	return multiplayer.get_unique_id()


## Single-instance peer (unique id 1). Emits [signal server_started].
func start_offline() -> void:
	trace()
	reset_network()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_hosting = true
	server_started.emit()


## Drop [param peer_id] if this is an ENet server.
func kick_peer( peer_id:int ) -> void:
	trace({&'peer_id': peer_id})
	var peer:MultiplayerPeer = multiplayer.multiplayer_peer
	if peer is ENetMultiplayerPeer:
		peer.disconnect_peer(peer_id)


func _has_peer() -> bool:
	return is_instance_valid(multiplayer) \
			and multiplayer.multiplayer_peer != null
