extends VBoxContainer

export(NodePath) var path_log_list
onready var ui_log_list = get_node(path_log_list)

export(NodePath) var path_clients_list
onready var ui_clients_list:ItemList = get_node(path_clients_list)

onready var ui_relay_client_status_color  = $"RelayClient/ConnectionConfiguration/Status"
onready var ui_relay_client_configuration = $"RelayClient/ConnectionConfiguration"
onready var ui_relay_client_uri           = $"RelayClient/ConnectionConfiguration/URIText"
onready var ui_relay_connect_button       = $"RelayClient/ConnectionConfiguration/ConnectButton"
onready var ui_relay_disconnect_button    = $"RelayClient/ConnectionConfiguration/DisconnectButton"

onready var ui_server_status_color      = $"Server/ServerConfiguration/Status"
onready var ui_server_configuration     = $"Server/ServerConfiguration"
onready var ui_server_bind_address_text = $"Server/ServerConfiguration/BindToText"
onready var ui_server_bind_port_text    = $"Server/ServerConfiguration/PortText"
onready var ui_server_start_button      = $"Server/ServerConfiguration/StartButton"
onready var ui_server_stop_button       = $"Server/ServerConfiguration/StopButton"

export(Color) var connected_color
export(Color) var disconnected_color

# Our WebSocketServer instance
var _server = WebSocketServer.new()
var _relay_client:WebSocketClient = WebSocketClient.new()

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

func _start_server() -> void:
	# Start listening on the given port.
	_server.set_bind_ip(ui_server_bind_address_text.text)
	var err = _server.listen(ui_server_bind_port_text.text.to_int())
	if err != OK:
		log_msg("Unable to start server. Error : %d" % [err], -1)
		return
	log_msg("Server started !", 2)
	ui_server_status_color.color    = connected_color
	ui_server_start_button.disabled = true
	ui_server_stop_button.disabled  = false

func _stop_server() -> void:
	log_msg("Server stopped", 2)
	ui_server_status_color.color    = disconnected_color
	ui_server_stop_button.disabled  = true
	ui_server_start_button.disabled = false
	_server.stop()

func _relay_client_connected() -> bool:
	return _relay_client.get_connection_status() == _relay_client.CONNECTION_CONNECTED

func _relay_client_enable_new_connections(status:bool) -> void:
	ui_relay_connect_button.disabled    = !status
	ui_relay_disconnect_button.disabled = status

func _relay_client_connect() -> void:
	_relay_client_enable_new_connections(false)
	var err:int = _relay_client.connect_to_url(ui_relay_client_uri.text)
	if err != OK:
		log_msg("Could not connect to relay server. Error code : %d" % [err], -1)
		_relay_client_enable_new_connections(true)
		return
	log_msg("Connecting to url : OK ? %s" % [str(err == OK)], 2)

func _relay_client_show_disconnected():
	_relay_client_enable_new_connections(true)
	ui_relay_client_status_color.color = disconnected_color

func _relay_client_show_connected():
	log_msg("Connected !", 2)
	_relay_client_enable_new_connections(false)
	ui_relay_client_status_color.color = connected_color

func _relay_client_connection_closed(_was_clean_closed:bool):
	log_msg("Connection closed", 2)
	_relay_client_show_disconnected()

func _relay_client_server_disconected():
	_relay_client_show_disconnected()

func _relay_client_connection_error():
	log_msg("Connection error", -1)
	_relay_client_show_disconnected()

func _relay_client_disconnect() -> void:
	_relay_client.disconnect_from_host()
	log_msg("Disconnecting", 2)
	_relay_client_show_disconnected()

func _relay_client_connection_established(_protocol:String) -> void:
	log_msg("Connected to relay server !", 2)
	_relay_client_show_connected()

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
	if not _is_html_version():
		_enable_server_section()
		_start_server()

	var _unchecked
	_unchecked = _relay_client.connect("connection_closed", self, "_relay_client_connection_closed")
	_unchecked = _relay_client.connect("connection_error", self, "_relay_client_connection_error")
	_unchecked = _relay_client.connect("connection_established", self, "_relay_client_connection_established")
	_unchecked = _relay_client.connect("server_disconnected", self, "_relay_client_server_disconected")

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


func _process(_delta):
	# Call this in _process or _physics_process.
	# Data transfer, and signals emission will only happen when calling this function.
	_server.poll()
	_relay_client.poll()

func send_string(text_data:String) -> int:
	var text_packet:PoolByteArray = text_data.to_utf8()
	var sent_n_times:int = 0
	if _server.is_listening():
		for client_id in clients:
			var client = _server.get_peer(client_id)
			if client == null:
				log_msg("Client is null", -1)
				continue
			client.put_packet(text_packet)
			log_msg("[Client:%d] %s" % [client_id, text_data])
			sent_n_times += 1


	if _relay_client_connected():
		var _unchecked = _relay_client.get_peer(1).put_packet(text_packet)
		log_msg("[Through relay connection] %s" % [text_data])
		sent_n_times += 1

	if sent_n_times == 0:
		log_msg("Last message was not sent : ", -1)
		log_msg(text_data, -1)
	return sent_n_times


func _enable_relay_client_section():
	ui_relay_client_configuration.show()

func _disable_relay_client_section():
	_relay_client_disconnect()
	ui_relay_client_configuration.hide()

func _is_html_version() -> bool:
	return false

func _enable_server_section():
	if _is_html_version():
		printerr("Cannot enable the Websocket server on the web version")
		return false
	ui_server_configuration.show()


func _disable_server_section():
	_stop_server()
	ui_server_configuration.hide()

func _on_RelayClient_ConnectButton_pressed():
	_relay_client_connect()

func _on_RelayClient_DisconnectButton_pressed():
	_relay_client_disconnect()

func _on_Server_StartButton_pressed():
	_start_server()

func _on_Server_StopButton_pressed():
	_stop_server()

func _on_Server_Checkbox_toggled(button_pressed):
	if button_pressed:
		_enable_server_section()
	else:
		_disable_server_section()

func _on_RelayClient_CheckBox_toggled(button_pressed):
	if button_pressed:
		_enable_relay_client_section()
	else:
		_disable_relay_client_section()

