extends "res://addons/enetheru.mp_test/runner-base.gd"

# State Generation
const TestGen = preload('res://addons/enetheru.mp_test/scripts/generator.gd')
const TestVar = preload('res://addons/enetheru.mp_test/scripts/variable.gd')
const TestRule = preload('res://addons/enetheru.mp_test/scripts/rule.gd')
const TestCombo = preload('res://addons/enetheru.mp_test/scripts/combo.gd')

var generator : TestGen



func _init() -> void:
	title = "State Generation"
	desc = "Figuring out the idea I have for generating the majority of" \
		+ "the information needed for testing, and providing tools to fill out" \
		+ " the rest."

	roles.merge({
		&'PEER1':0,
		&'PEER2':0,
	})

	generator = TestGen.new(self)
	generator.moves.append( TestMove.new("DoNothing", [], null ) )


func _compose_status() -> String:
	return "Status OK"


func _requirements() -> Dictionary:
	var unmet : Dictionary
	if get_peers( PeerStatus.ASSIGNED ).size() < 2:
		unmet["Wants Two Peers"] = "This runner requires two peers assigned to work."
	return unmet


func rule_var_is_active( id : int, variable : TestVar ) -> bool:
	# this rule requires src_var to be in an active state.
	return id & variable.get_mask()


func _setup_states() -> void:
	var var1 := TestVar.new(self, "Testing Variable One", "var1")
	var var2 := TestVar.new(self, "Testing Variable Two", "var2")
	var var3 := TestVar.new(self, "Testing Variable Three", "var3")

	var rule1 := TestRule.new("Depends","dep")
	rule1.conditions = [rule_var_is_active.bind(var1)]

	# This rule applies to all Modes
	var3.rules[var3.get_mask()] = rule1
	# The mask is not shifted left because
	# the variable has yet to be added to the generator

	generator.add_var( var1 )
	generator.add_var( var2 )
	generator.add_var( var3 )

	all_states.append_array(generator.generate_states())

	starting_state = all_states.front()
	#starting_state.moves = [TestMove.new(&"SERVER", [], starting_state)]
	starting_state.moves.push_front(TestMove.new(&"SERVER", [], starting_state))

	server_is_ready.connect(generator.try_moves, CONNECT_ONE_SHOT )
	# FIXME I have a catch22 here, setup of the states is before
	# validation, I cant move till I have validation.
	# but validation requires moves.
	# I guess I can add a do-nothing move to satisfy the constraint.

func _reset() -> Constant:
	if server_is_ready.is_connected(generator.try_moves):
		server_is_ready.disconnect(generator.try_moves)
	return Constant.OK

#func _setup_states() -> void:
	#var src_var := SectorVar.new(self, "Source Sector", "src")
	#var dst_var := SectorVar.new(self, "Destination Sector", "dst")
	#var obj_var := SectorVar.new(self, "Object", "obj")
#
#
#
	#var rule := TestRule.new("needs src","")
	#rule.conditions = [rule_var_is_active.bind(src_var)]
#
	## This rule applies to all Modes, before being added to the generator
			## the mask will not be shifted into position.
	#obj_var.rules[obj_var.get_mask()] = rule
#
	## I want to place a restriction on adding the object state.
	## it can only be added if the state of src is non zero.
	#generator.add_var( src_var )
	#generator.add_var( dst_var )
	#generator.add_var( obj_var )
#
	#all_states.append_array(generator.generate_states())
#
	#var first_state : TestState = all_states.front()
	#first_state.name = "Start"




#class SectorVar extends TestVar:
	#func _init( _runner : RunnerBase, _name : String, _short_name : String ) -> void:
		#super(_runner, _name, _short_name)
		#name = _name
		#Mode = {
			#ø = 0x0,
			#A = 0x01,
			#B = 0x02,
			#C = 0x04,
			#D = 0x08,
			#E = 0x10,
			#F = 0x20,
		#}
		#stubs = {}
		#width = Mode.size() -1 # A does not count
#
		#tests = {
			#Mode.A:{&'SERVER':[runner.test_always_success]},
		#}
