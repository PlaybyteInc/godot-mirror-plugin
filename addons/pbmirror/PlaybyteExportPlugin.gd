extends EditorExportPlugin

signal set_export_path(path)

func _export_begin(features, is_debug, path, flags):
	if not "HTML5" in features:
		return
	var parts = path.split("/")
	parts.remove(parts.size() - 1)
	var folder = parts.join("/")
	emit_signal("set_export_path", folder)
