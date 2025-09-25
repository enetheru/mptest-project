```gdscript
#         ███    ███ ██████     ████████ ███████ ███████ ████████          #
#         ████  ████ ██   ██       ██    ██      ██         ██             #
#         ██ ████ ██ ██████  █████ ██    █████   ███████    ██             #
#         ██  ██  ██ ██            ██    ██           ██    ██             #
#         ██      ██ ██            ██    ███████ ███████    ██             #
func                 _________MP_TEST_________                 ()->void:pass
```

The Multi-Player Testing Harness (MPTest) is my GDScript-based framework designed to
test multiplayer game logic in Godot. It models a state machine to track and verify state transitions between
peers. It also provides some tools to automates the generation and
validation of test states, helping me to keep my code consistent as I write new features.

## Purpose

MPTest was created because I was going insane managing the complexity of synchronizing state across networked peers. As
I learned more and the features grew, manual testing became impractical due to the explosion in possible states and
interactions.

MPTest provides me a structured approach to:

- Define and verify game states for each peer role.
- Automate state transitions.
- Generate valid state combinations using variables and rules.
- Validate outcomes to prevent regressions during development.

## Core Concepts

MPTest models a multiplayer test environment as a state machine, where states are verified and transitioned using moves. Key components include:

### Test Runner

- **State (`MPTState`)**: Represents a game state with a set of verification tests (`tests`) for specific roles and a list of possible moves (`moves`) to transition to other states.
- **Move (`MPTMove`)**: Defines a transition to a destination state (`dest`) by executing actions (`actions`) for a specific role.
- **Action (`MPTAction`)**: Encapsulates a role and a set of `Callable`s to perform during a move.

### State Generation
- **Generator (`MPTGenerator`)**: Automates the creation of states and moves from variables and rules, reducing manual configuration.
- **Variable (`MPTVariable`)**: Defines modes (e.g., on/off) with associated tests, actions, and rules to generate valid state combinations.
- **Rule (`MPTRule`)**: Contains conditions to validate or expand combinations, adding tests to resulting states if successful.
- **Combo (`MPTCombo`)**: Represents a combination of variable modes, used to generate states and track relationships between them.

## How It Works

### State Machine
The testing process involves:
1. **Setup**: Initialize an `MPTRunner` with a set of states and role-to-peer mappings.
2. **Verification**: Each `MPTState` has role-specific tests (`Dictionary[StringName, Array[Callable]]`) to verify its validity.
3. **Transitions**: Execute `MPTMove`s, which trigger `MPTAction`s (role-based `Callable`s) to transition to a new state.
4. **Validation**: Verify the resulting state against its tests.

### State Generation
Manually defining states and moves is tedious, so `MPTGenerator` automates this:
- **Variables**: Define `MPTVariable`s with modes (e.g., on/off) and rules (`expansion_rules`, `elimination_rules`).
- **Combinations**: Generate valid `MPTCombo`s by expanding variables and applying rules to filter invalid combinations.
- **States**: Convert `MPTCombo`s to `MPTState`s, adding tests and moves based on variable configurations.
- **Moves**: Assign `MPTMove`s to states based on variable transitions, though move generation is still evolving (`@experimental`).

### Manual Workflow
1. Create `MPTState`s, assign tests.
3. Create `MPTMoves` specifying destination states directly 
4. Run tests via `MPTRunner`, executing moves and verifying states.

### State Generation Workflow
1. Create `MPTVariable`s to represent the destination states
2. Assign Callables as tests, to validate the resulting step
3. Assign mappings of role and Callable as instruction on how to reach the state ( only works if variables are independent )
4. Assign any rules to restrict expansion of variable multiplication 
2. Use `MPTGenerator` to create `MPTCombo`s representing all valid mode combinations.
3. Transform `MPTCombo`s into `MPTState`s with associated tests and moves.
4. Run tests via `MPTRunner`, executing moves and verifying states.

## Limitations and Ongoing Development
- **Failed Move Handling**: The system currently stops on move failure, requiring a full reset.

# OLD README

Multi-Player Testing Harness.

It ends up being like a state machine which keeps track of how things are
progressing, I don't really know if its a good idea or not, but what else am I
going to use to perform the testing, all the other testing frameworks ignore
multi-player altogether. Every time I see a new testing framework I check to see
if it supports multi-player things but alas, so far none of them do.

# Initial Seed of Inspiration

As I'm synchronising state across the network, some of the things I wish to do
become so convoluted, and complex, like trying to wrangle multiple divergent
realities with a lasso made of overcooked spaghetti, I lose track of my mental
model and get stuck. When working on the next feature, the complexity compounds
and I'm caught in an exponential explosion of integration hell. I needed a
testing harness to prove that later changes aren't breaking earlier ones as I'm
still developing the features, and they are all tightly woven.

So I built a few functions, some RPC's and started proving to myself that after
each operation the results that I expected were what I was was getting. That
one time, ended up being two times, and then three, and now I find myself
working on the testing harness abstraction separately so that I can develop the
features I want to make testing faster.

# The Core Idea

My running program is in some well defined state that I can verify with a set
of tests. I want to call set of arbitrary functions, which will result in some
other state that can also be verified. But because we're dealing with the
multi-verse that is multi-player, the state needs to be tested on each host
according to their role, and the actions to effect change might need to be
performed on any of the hosts.

So we have a `State`, which has a series of tests to verify its validity. The
`State` has a list of `Move`s it can use to move to another `State`. We have a
state machine.

```gdscript
# A stripped down version of the classes to illustrate
class Runner:
	var states : Array[State]
	var roles : Dictionary[StringName,int] # int is peer_id

class State:
	var moves : Array[Move]

class Move:
	var role : StringName
	var actions : Array[Callable]
```

# Processing

The testing process then involves setting up the state machine, and then
performing moves and verifying that the outcomes of those moves are valid. At
the moment if a move fails, the processing stops, and requires a reset of
everything but I want to change that.

This style has caveats, like sometimes, a state we want to test is nested deep
within the graph, so some rudimentary path-finding is needed to move in the

Direction we want to validate. Which inevitably leads to re-processing moves
that have previously passed validation.

# Generation

I found that it was getting very tedious to write out all the states and their
moves. So I am trying to figure out how to generate as much as possible.

The approach I am working is to define a set of `Variables` each having
discreet `Mode`'s, like a Boolean being on or off. Each Mode can have tests
associated with it. We can then combine the variables into all possible
Combinations or `Combo`s( I'm disregarding order, so AAB is equivalent to BAA
or ABA).

By itself, this expands exponentially, so a set of `Rule`s is added to each
`Variable` to determine if the expansion to a new `Combo` is valid.

Once all the combinations are generated, then they can be transformed into
`State`s.

```gdscript
# # A stripped down version of the classes to illustrate
class Variable:
	var Mode : Dictionary[StringName,int] # int is a bitmask
	var rules : Dictionary[int, Rule] # [Mode bitmask, Rule]
	var tests : Dictionary[int, Array]    # [Mode bitmask, Array[Callable->int]]

class Rule:
	var conditions : Array[Callable]
	var tests : Array[Callable]
```

This doesn't however address the moves, which I am still working on how I might
enable, do I introduce another set of variables to expand for moves? The
thoughts I have so far are:

## Thought One

I could add sets of actions to Variables and Rules, and expand the combinations
of those into new moves, but that is a vague thought, I know it wont capture
everything. Even so, there will be moves that fail, so some way to test
correctness will be needed

## Thought Two

I could define a set of moves separately, then, from the starting state,
perform the move, and then attempt to validate all states against it. This
could illustrate poorly thought out testing, where multiple States pass
validation, indicating that additional testing is needed to discriminate
between the two states, or consolidate them into one. Show orphan states that
are unreachable with the set of actions.

## Thought Three

While writing these thoughts out, creating a set of variable's with moves to
expand, their own sets of rules etc. might end up being the way to go, it
satisfies a few constraints at once. Initially I thought that perhaps I could
add actions to the variables, but I think that wont express intent well enough.

These idea's are in progress, but it's painful to think about, and slow to
test. I haven't been taking care of failure cases in a robust way, simply
throwing everything out and starting again, where instead I wish to handle
those failed cases more robustly and only partially reset. More work.

# Brain Dump

Because my projects grow out of necessity in the moment, the code is riddled
with inconsistencies, and moving forward always requires a great deal of
re-factoring. I also need to make sure I don't break things so badly for my main
project this is supposed to be testing, which then creates a back and forth,
that is very frustrating, but I can't work on this in isolation, it's entire
purpose is to test a real project, not test itself.


# Wish-List

I want to provide a way to visualise the graph once it's built.
