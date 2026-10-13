class_name OnlineAPI
extends Node
var base_url := "http://127.0.0.1:8080"
var token := ""
var account: Dictionary = {}

func request(path: String, data: Dictionary = {}, method: int = HTTPClient.METHOD_POST, server_key: String = "") -> Dictionary:
 var http := HTTPRequest.new()
 http.timeout = 12
 http.body_size_limit = 2000000
 add_child(http)
 var headers := PackedStringArray(["Content-Type: application/json"])
 if not token.is_empty():
  headers.append("Authorization: Bearer " + token)
 if not server_key.is_empty():
  headers.append("X-Galactic-Server-Key: " + server_key)
 var error := http.request(base_url.trim_suffix("/") + path, headers, method, JSON.stringify(data) if method != HTTPClient.METHOD_GET else "")
 if error != OK:
  http.queue_free()
  return {"error": "Could not start connection to the account server"}
 var reply: Array = await http.request_completed
 http.queue_free()
 if reply[0] != HTTPRequest.RESULT_SUCCESS:
  return {"error": "Account server unavailable. Check its address and that it is running."}
 var parser := JSON.new()
 if parser.parse(reply[3].get_string_from_utf8()) != OK:
  return {"error": "Account server sent an invalid reply"}
 if int(reply[1]) < 200 or int(reply[1]) >= 300:
  return parser.data if parser.data is Dictionary else {"error": "Account server rejected the request"}
 return {"data": parser.data}

func sign_in(username: String, password: String, register: bool = false) -> Dictionary:
 var reply := await request("/register" if register else "/login", {"username": username, "password": password})
 if reply.has("data"):
  token = str(reply.data.token)
  account = reply.data.profile
 return reply

func refresh() -> Dictionary:
 var reply := await request("/me", {}, HTTPClient.METHOD_GET)
 if reply.has("data"):
  account = reply.data
 return reply
