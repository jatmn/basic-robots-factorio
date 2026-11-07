stds.factorio = {
  read_globals = {
    "defines", "log", "settings", "serpent",
    table = {fields = {deepcopy = {}}},
  },
}
std = "lua52+factorio"
not_globals = {"io", "os", "dofile", "loadfile", "coroutine"}
max_line_length = false
exclude_files = {"build/**", ".cache/**"}

files["data*.lua"].globals = {"data"}
files["data*.lua"].read_globals = {"mods", "util"}
files["settings*.lua"].globals = {"data"}
files["settings*.lua"].read_globals = {"mods"}
files["control.lua"].globals = {"game", "storage"}
files["control.lua"].read_globals = {"script", "remote", "rendering", "prototypes", "helpers"}
files["migrations/**"].globals = {"game", "storage"}
files["migrations/**"].read_globals = {"script", "remote", "prototypes"}
