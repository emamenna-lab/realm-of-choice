extends SceneTree
## Esegue tutti i test: godot --headless --path . -s tests/run_tests.gd
## Esce con codice 1 se qualcosa fallisce.

const TEST_DIR := "res://tests/"


func _init() -> void:
	var total := 0
	var failed: Array[String] = []
	for file in DirAccess.get_files_at(TEST_DIR):
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file == "test_case.gd":
			continue
		var script: GDScript = load(TEST_DIR + file)
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			var instance: TestCase = script.new()
			instance._current = "%s::%s" % [file, name]
			instance.call(name)
			total += 1
			failed.append_array(instance.failures)
			print(("  ok  " if instance.failures.is_empty() else "  KO  ") + instance._current)
	print("")
	for f in failed:
		print("FALLITO: " + f)
	print("%d test, %d verifiche fallite" % [total, failed.size()])
	quit(1 if not failed.is_empty() else 0)
