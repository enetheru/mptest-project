@tool
extends TestBase
## Smoke suite so TestRunner has something to discover and pass.


func _run_test() -> int:
	TEST_TRUE(true, "true")
	TEST_EQ(1, 1, "equal")
	TEST_APPROX(1.0, 1.0, "approx")
	return runcode
