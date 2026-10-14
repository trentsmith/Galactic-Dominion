class_name ServerConnection
extends RefCounted

var api_url := "http://127.0.0.1:8080"
var combat_host := "127.0.0.1"
var combat_port := 7777
var commander := ""
var save_path := "user://server_connection.cfg"

func load_settings() -> void:
 _read("res://resources/server_defaults.cfg")
 # A host can distribute a configured server.cfg beside the standalone game.
 if not OS.has_feature("editor"):
  _read(OS.get_executable_path().get_base_dir().path_join("server.cfg"))
 _read(save_path)

func _read(path: String) -> void:
 var config := ConfigFile.new()
 if config.load(path) != OK: return
 var url := str(config.get_value("server", "api_url", api_url)).strip_edges().trim_suffix("/")
 var host := str(config.get_value("server", "combat_host", combat_host)).strip_edges()
 var port := int(config.get_value("server", "combat_port", combat_port))
 if url.begins_with("https://") or url.begins_with("http://"): api_url = url
 if not host.is_empty(): combat_host = host
 if port >= 1 and port <= 65535: combat_port = port
 commander = str(config.get_value("server", "commander", commander)).left(24)

func save_settings(url: String, host: String, port: int, name_text: String) -> bool:
 url = url.strip_edges().trim_suffix("/")
 host = host.strip_edges()
 if not (url.begins_with("https://") or url.begins_with("http://")) or host.is_empty() or port < 1 or port > 65535: return false
 api_url = url
 combat_host = host
 combat_port = port
 commander = name_text.left(24)
 var config := ConfigFile.new()
 config.set_value("server", "api_url", api_url)
 config.set_value("server", "combat_host", combat_host)
 config.set_value("server", "combat_port", combat_port)
 config.set_value("server", "commander", commander)
 return config.save(save_path) == OK
