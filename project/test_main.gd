extends 'res://addons/enetheru.mp_test/runner-base.gd'


var generator : MPT.Generator


func _init() -> void:
	title = "State Generation"
	desc = "Figuring out the idea I have for generating the majority of" \
		+ "the information needed for testing, and providing tools to fill out" \
		+ " the rest."

	roles.merge({
		&'PEER1':0,
		&'PEER2':0,
	})

	generator = MPT.Generator.new(self)
	generator.moves.append( Util.new_from_dict(MPT.Move.new(), {
		&'name':"nah yeah",
		&'name_short':"nah",
		&'role':&'SERVER'
	}) )


func _compose_status() -> String:
	return "Status OK"


#func _requirements() -> Dictionary:
	#var unmet : Dictionary
	#if get_peers( PeerStatus.ASSIGNED ).size() < 2:
		#unmet["Wants Two Peers"] = "This runner requires two peers assigned to work."
	#return unmet


func _setup( _level : ResetLevel ) -> Constant:
	if _level & ResetLevel.FAILURE_STATE: pass
	if _level & ResetLevel.PROGRAM_STATE: pass
	if _level & ResetLevel.NETWORK_STATE: pass
	if _level & ResetLevel.TEST_RESULTS:  pass
	if _level & ResetLevel.STATE_GRAPH:   _setup_states()
	if _level & ResetLevel.REPORTING:     pass
	return Constant.OK


func _reset( _level : ResetLevel ) -> Constant:
	if _level & ResetLevel.FAILURE_STATE: pass
	if _level & ResetLevel.PROGRAM_STATE: pass
	if _level & ResetLevel.NETWORK_STATE: pass
	if _level & ResetLevel.TEST_RESULTS:  pass
	if _level & ResetLevel.STATE_GRAPH:   pass
	if _level & ResetLevel.REPORTING:     pass
	return Constant.OK


func _setup_states() -> void:
	var var1 := MPT.Variable.new()
	var1.id = "v1"
	var1.desc = "Testing Variable One"

	var var2 := MPT.Variable.new()
	var2.id = "v2"
	var2.desc = "Testing Variable Two"

	var var3 := MPT.Variable.new()
	var3.id = "v3"
	var3.desc = "Testing Variable Three"


	var rule1 := MPT.Rule.new()
	rule1.name = "Depends"
	rule1.conditions = [rule_var_is_active.bind(var1)]

	# This rule applies to all Modes
	var3.rules[var3.get_mask()] = rule1
	# The mask is not shifted left because
	# the variable has yet to be added to the generator

	generator.add_vars( [var1, var2, var3] )

	all_states.append_array(generator.generate_states())
	var first_state : MPT.State = all_states.front()

	#starting_state.moves = [TestMove.new(&"SERVER", [], starting_state)]
	var test_move := MPT.Move.new()

	var test_action := MPT.Action.new()
	test_action.role = &"SERVER"
	test_action.callables = [a_ok]

	var test_action2 : MPT.Action = test_action.dup()
	test_action2.role = &'PEER1'

	var test_action3 : MPT.Action = test_action.dup()
	test_action3.role = &'PEER2'

	test_move.name = "test_move"
	test_move.desc = "Description of Test Move"
	test_move.actions_temp = [test_action, test_action2, test_action3]
	test_move.dest = first_state

	first_state.moves.push_front(test_move)

	#server_is_ready.connect( generator.try_moves, CONNECT_ONE_SHOT )
	# FIXME I have a catch22 here, setup of the states is before
	# validation, I cant move till I have validation.
	# but validation requires moves.
	# I guess I can add a do-nothing move to satisfy the constraint.

	# I might be able to add a generation step to the test runner?


func rule_var_is_active( id : int, variable : MPT.Variable ) -> bool:
	# this rule requires src_var to be in an active state.
	return id & variable.get_mask()

func a_ok() -> Constant:
	Util.printy( "a_ok()", null, self )
	return Constant.OK

#func _setup_states() -> void:
	#var src_var := SectorVar.new(self, "Source Sector", "src")
	#var dst_var := SectorVar.new(self, "Destination Sector", "dst")
	#var obj_var := SectorVar.new(self, "Object", "obj")
#
#
#
	#var rule := MPT.Rule.new("needs src","")
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




#class SectorVar extends MPT.Variable:
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
