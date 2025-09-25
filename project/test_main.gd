extends MPTRunner

func _init() -> void:
	title = "State Generation"
	desc = "Figuring out the idea I have for generating the majority of" \
		+ "the information needed for testing, and providing tools to fill out" \
		+ " the rest."

	roles.merge({
		&'PEER1':0,
		&'PEER2':0,
	})

	generator = MPTGenerator.new(self)
	generator.moves.append( Util.new_from_dict(MPTMove.new(), {
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
	if _level & ResetLevel.STATE_GRAPH:   setup_states()
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


func setup_states() -> void:
	var var1 := MPTVariable.new("v1", "Testing Variable One")
	var var2 := MPTVariable.new("v2", "Testing Variable Two")
	var var3 := MPTVariable.new("v3", "Testing Variable Three")


	var rule1 := MPTRule.new("Depends", [rule_var_is_active.bind(var1)])

	# This rule applies to all Modes
	var3.elimination_rules[var3.get_mask()] = rule1
	# The mask is not shifted left because
	# the variable has yet to be added to the generator

	generator.add_vars( [var1, var2, var3] )

	all_states.append_array(generator.generate_states())

	# Fetch the first state from the generation.
	var first_state : MPTState = all_states.front()

	#starting_state.moves = [TestMove.new(&"SERVER", [], starting_state)]
	var test_move := MPTMove.new("test_move","Description of Test Move",
		[
			MPTAction.new(&"SERVER", [action_do_nothing]),
			MPTAction.new(&"PEER1", [action_do_nothing]),
			MPTAction.new(&"PEER2", [action_do_nothing])
		],
		first_state)

	first_state.moves.append(test_move)

	#server_is_ready.connect( generator.try_moves, CONNECT_ONE_SHOT )
	# FIXME I have a catch22 here, setup of the states is before
	# validation, I cant move till I have validation.
	# but validation requires moves.
	# I guess I can add a do-nothing move to satisfy the constraint.

	# I might be able to add a generation step to the test runner?


func rule_var_is_active( id : int, variable : MPTVariable ) -> bool:
	# this rule requires src_var to be in an active state.
	return id & variable.get_mask()


#class SectorVar extends MPTVariable:
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
