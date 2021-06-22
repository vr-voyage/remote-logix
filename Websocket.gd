extends HBoxContainer

export(NodePath) var path_log_list
onready var ui_log_list = get_node(path_log_list)

export(NodePath) var path_clients_list
onready var ui_clients_list:ItemList = get_node(path_clients_list)

# The port we will listen to
const PORT = 9080
# Our WebSocketServer instance
var _server = WebSocketServer.new()

var clients:Array = []

func _ui_refresh_clients_list():
	ui_clients_list.clear()
	for client_id in clients:
		ui_clients_list.add_item(str(client_id))

func _add_client(id):
	clients.append(id)
	_ui_refresh_clients_list()

func _remove_client(id):
	var client_idx:int = clients.find(id)
	if client_idx >= 0:
		clients.remove(client_idx)
		_ui_refresh_clients_list()
	

func log_msg(msg:String, direction:int = 0) -> void:
	var prefix:String = ""
	match direction:
		0:
			prefix = "-> "
		1:
			prefix = "<- "
		2:
			prefix = "STATUS : "
		-1:
			prefix = "/!\\ "
	var text:RichTextLabel = RichTextLabel.new()
	text.text = prefix + msg
	text.selection_enabled = true
	text.fit_content_height = true
	ui_log_list.add_child(text)
	

func _ready():
	# Connect base signals to get notified of new client connections,
	# disconnections, and disconnect requests.
	_server.connect("client_connected", self, "_connected")
	_server.connect("client_disconnected", self, "_disconnected")
	_server.connect("client_close_request", self, "_close_request")
	# This signal is emitted when not using the Multiplayer API every time a
	# full packet is received.
	# Alternatively, you could check get_peer(PEER_ID).get_available_packets()
	# in a loop for each connected peer.
	_server.connect("data_received", self, "_on_data")
	# Start listening on the given port.
	var err = _server.listen(PORT)
	if err != OK:
		log_msg("Unable to start server", -1)
		set_process(false)
	log_msg("Server started !", 2)

func _connected(id, proto):
	# This is called when a new peer connects, "id" will be the assigned peer id,
	# "proto" will be the selected WebSocket sub-protocol (which is optional)
	log_msg("Client %d connected with protocol: %s" % [id, proto], 2)
	_server.get_peer(id).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	_add_client(id)

func _close_request(id, code, reason):
	# This is called when a client notifies that it wishes to close the connection,
	# providing a reason string and close code.
	log_msg("Client %d disconnecting with code: %d, reason: %s" % [id, code, reason], 2)

func _disconnected(id, was_clean = false):
	# This is called when a client disconnects, "id" will be the one of the
	# disconnecting client, "was_clean" will tell you if the disconnection
	# was correctly notified by the remote peer before closing the socket.
	log_msg("Client %d disconnected, clean: %s" % [id, str(was_clean)], 2)
	_remove_client(id)

func _on_data(id):
	# Print the received packet, you MUST always use get_peer(id).get_packet to receive data,
	# and not get_packet directly when not using the MultiplayerAPI.
	var pkt = _server.get_peer(id).get_packet()
	log_msg("Got data from client %d: %s" % [id, pkt.get_string_from_utf8()], 2)


func _process(delta):
	# Call this in _process or _physics_process.
	# Data transfer, and signals emission will only happen when calling this function.
	_server.poll()

func send_string(text_data:String) -> int:
	var sent_n_times:int = 0

	for client_id in clients:
		var client = _server.get_peer(client_id)
		if client == null:
			log_msg("Client is null", -1)
			continue
		client.put_packet(text_data.to_utf8())
		log_msg("[Client:%d] %s" % [client_id, text_data])
		sent_n_times += 1

	if sent_n_times == 0:
		log_msg("Last message was not sent : ", -1)
		log_msg(text_data, -1)
	return sent_n_times
