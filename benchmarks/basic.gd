@tool
extends EditorScript
## Empty loop + tiny spin. GDSBench analog of BM_empty / BM_spin.
##
## Run (privileged):
## [code] File → Run [/code] in the script editor, or
## [code] RUN_SCRIPT res://benchmarks/basic.gd [/code]

const RegisterLib = preload("res://addons/enetheru.gdsbench/lib/benchmark_register.gd")
const ConsoleReporter = preload("res://addons/enetheru.gdsbench/lib/console_reporter.gd")

const Benchmark = RegisterLib.Benchmark
const FunctionBenchmark = RegisterLib.FunctionBenchmark


func _run() -> void:
	var saved_list:bool = BenchLib.FLAGS_benchmark_list_tests
	var saved_dry:bool = BenchLib.FLAGS_benchmark_dry_run
	var saved_min_time:String = BenchLib.FLAGS_benchmark_min_time
	RegisterLib.ClearRegisteredBenchmarks()
	BenchLib.FLAGS_benchmark_list_tests = false
	BenchLib.FLAGS_benchmark_dry_run = false
	BenchLib.FLAGS_benchmark_min_time = "0.1s"
	var _empty:Benchmark = register_bm(BM_Empty)
	var _spin:Benchmark = register_bm(BM_Spin).ArgName("n").Arg(64).Arg(256)
	var reporter := ConsoleReporter.new()
	var n:int = BenchLib.RunSpecifiedBenchmarks(reporter)
	print("GDSBench basic: %d run(s)" % n)
	RegisterLib.ClearRegisteredBenchmarks()
	BenchLib.FLAGS_benchmark_list_tests = saved_list
	BenchLib.FLAGS_benchmark_dry_run = saved_dry
	BenchLib.FLAGS_benchmark_min_time = saved_min_time


func register_bm(fn:Callable, bm_name:String = "") -> Benchmark:
	return RegisterLib.RegisterBenchmarkInternal(
			FunctionBenchmark.new(fn, bm_name))


static func BM_Empty(state:State) -> void:
	for _i in state:
		pass


static func BM_Spin(state:State) -> void:
	var n:int = state.get_range(0)
	for _i in state:
		var _acc:int = 0
		for k:int in n:
			_acc += k
