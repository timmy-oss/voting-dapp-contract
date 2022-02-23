
# @title Voting
# @notice This smart contract facilitates voting exercise to take place on the blockchain via a decentralized app that runs in the browser
# @notice This Particular Dapp allows for voting for one of three different proposals
# @notice This Voting Contract optionally allows for delegation : You can give permission for someone else to vote on your behalf
# @dev Written in Vyper
# @dev The number of proposals must be known before hand due to the the nature of Vyper as it does not allow dynamic
# @license MIT



event Register:
    voter : address
    total_voters : uint256


event Voted:
    voter : address
    delegates : uint256

event Delegation:
    sender : address
    to : address


event VotingEnded:
    winner : bytes32
    votes : uint256



#@dev Voter Struct
struct Voter:
    voter_address : address
    delegates_count : uint256
    has_voted  : bool
    has_delegated : bool



#@dev State Variables

proposals : public( bytes32[3] )
winner : public( bytes32 )
allow_delegation : public(bool)
anchor : public(address)
start_time : public( uint256 )
registered_voters : public( HashMap[address, Voter])
reg_end_time : public( uint256)
voting_end_time : public(uint256)
voters_count : public( uint256)
delegations : HashMap[ address, Voter[32] ]
is_over : public(bool)
votes_distribution : public( HashMap[bytes32, HashMap[address, Voter] ])
records : public( HashMap[bytes32, uint256 ])




@external
def __init__(  _proposals : bytes32[3], _start_time : uint256, _voting_duration : uint256,  _allow_delegation : bool, _registeration_duration  : uint256  ):
    self.anchor = msg.sender
    self.allow_delegation = _allow_delegation
    self.voters_count = 0
    self.is_over = False

    # @dev Validation checks
    assert _start_time > block.timestamp , 'Start time must be in the future'
    assert _start_time + _registeration_duration > block.timestamp , 'Registeration must be in the future'
    assert _start_time + _voting_duration >  _start_time + _registeration_duration , 'Voting must be after registeration and start in the future'

    self.start_time = _start_time
    self.reg_end_time = _start_time + _registeration_duration
    self.voting_end_time = _start_time + _registeration_duration + _voting_duration

    for i in range(3):
        self.proposals[i] = _proposals[i]



@external
def register():
    # @dev Register a prospective voter against voting

    assert self.anchor != msg.sender
    assert block.timestamp > self.start_time, 'Registration has not started'
    assert block.timestamp < self.reg_end_time, 'Registration has ended'

    self.voters_count =+ 1
    new_voter : Voter = Voter({ voter_address : msg.sender, delegates_count : 0, has_voted : False, has_delegated : False })
    self.registered_voters[msg.sender] = new_voter
    log Register(msg.sender, self.voters_count)


@external
def delegate( _to : address ):

    # @dev Delegate vote to another voter, so they can vote on their behalf

    assert self.anchor != msg.sender
    assert block.timestamp > self.start_time, 'Registration has not started'
    assert block.timestamp < self.reg_end_time, 'Registration has ended'
    assert _to != msg.sender
    assert _to != ZERO_ADDRESS
    assert self.registered_voters[msg.sender] != empty(Voter), 'You have not registered'
    assert self.registered_voters[ _to ] != empty(Voter), 'The receipient of delegation is not registered'
    assert self.registered_voters[ msg.sender ].has_delegated != True, 'You have delegated your vote already'
    assert self.registered_voters[_to].delegates_count < 32, 'Maximum delegations reached'

    self.delegations[_to][self.registered_voters[_to].delegates_count] = self.registered_voters[msg.sender]
    self.registered_voters[_to].delegates_count += 1
    self.registered_voters[msg.sender].has_delegated = True
    log Delegation(msg.sender, _to)


@external
def vote( _choice : bytes32 ):

    # @dev Register user's vote , vote for the delegations they user has been given permission to also

    assert self.anchor != msg.sender
    assert block.timestamp > self.reg_end_time, 'Voting has not started'
    assert self.voting_end_time > block.timestamp, 'Voting has ended'
    assert self.registered_voters[msg.sender] != empty(Voter), 'You are not registered'
    assert self.registered_voters[ msg.sender ].has_delegated != True, 'You have delegated your vote already'

    isValidateChoice : bool  = False
    for i in range(3):
        if self.proposals[i] == _choice:
            isValidateChoice = True

    assert isValidateChoice, 'Invalid choice'

    # @dev Register the sender's vote

    this_voter : Voter  = self.registered_voters[msg.sender]
    this_voter.has_voted = True
    self.votes_distribution[_choice][msg.sender]  = this_voter
    self.records[_choice] += 1

    # @dev Vote for the the delegates attached

    number_of_delegates : uint256 = self.registered_voters[msg.sender].delegates_count

    for delegate_index in range(32):
        if (delegate_index > number_of_delegates):
            break
        this_delegated_voter : Voter  = self.delegations[msg.sender][delegate_index]
        this_delegated_voter.has_voted = True
        self.votes_distribution[_choice][this_delegated_voter.voter_address] = this_delegated_voter
        self.records[_choice] += 1

    log Voted( msg.sender, number_of_delegates )


@internal
def _determineWinner() -> bytes32:

    # @dev Determine the winner of the voting exercise and return it

    assert block.timestamp > self.voting_end_time, 'Voting is still on'

    if self.is_over :
        return self.winner


    wining_votes : uint256 = 0

    for i in range(3):
        if( self.records[self.proposals[i]]) > wining_votes:
            self.winner = self.proposals[i]

    self.is_over = True
    return self.winner


@external
def getWinner() -> bytes32:

    # @dev get the winner of the voting
    assert block.timestamp > self.voting_end_time, 'Voting is still on'
    assert msg.sender == self.anchor

    return self._determineWinner()













