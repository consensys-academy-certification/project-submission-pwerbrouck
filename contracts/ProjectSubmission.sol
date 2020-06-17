pragma solidity >=0.4.21 <0.6.0;

contract ProjectSubmission { // Step 1

    address payable public owner;  // Step 1 (state variable)

    // ...ownerBalance... // Step 4 (state variable)
    uint256 public ownerBalance=0;

    modifier onlyOwner() { // Step 1
      require( msg.sender == owner );
      _;
    }
    
    struct University { // Step 1ps.
        bool    available;
        uint256 balance;
    }

    mapping ( address => University ) public universities; // Step 1 (state variable)

    enum ProjectStatus {  Waiting, Rejected, Approved, Disabled } // Step 2
    
    struct Project { // Step 2
        address author;
        address university;
        ProjectStatus status;
        uint256 balance;
    }
    uint256 projectCount=0;

    mapping ( bytes32 => Project ) public projects; // Step 2 (state variable)

    event ProjectApproved( bytes32 docHash );
    event DonationAccepted( bytes32 docHash, uint256 amount );
    event DonationReceived( bytes32 docHash, uint256 amount );

    event UniversityFundsWithdrawn( address indexed university, uint amount );
    event OwnerFundsWithdrawn( address indexed owner, uint amount );
    event ProjectFundsWithdrawn( bytes32 indexed docHash, address indexed student, uint amount );
    event BadWithdrawalAttempt( bytes32 indexed docHash, address indexed attacker );
    


    constructor () public {
      owner = msg.sender;
    }


    function registerUniversity( address accountU ) public onlyOwner { // Step 1
      universities[accountU] = University( true, 0 );
    }
    
    function disableUniversity( address accountU ) public onlyOwner { // Step 1
      universities[accountU].available = false;
    }
    
    function submitProject (  bytes32 docHash, address universityA ) public payable returns( uint256 ) {  // Step 2 and 4
      require( msg.value == 1 ether );
      require( universities[universityA].available );
      projectCount++;
      projects[ docHash ] = Project(  msg.sender, universityA, ProjectStatus.Waiting, 0 );
      ownerBalance += msg.value;
      return( projectCount );
    }
    
    function disableProject( bytes32 docHash ) public onlyOwner { // Step 3
      projects[ docHash ].status = ProjectStatus.Disabled;
    }
    
    function reviewProject( bytes32 docHash, ProjectStatus newStatus ) public onlyOwner { // Step 3
      require( projects[ docHash ].status == ProjectStatus.Waiting );
      projects[ docHash ].status = newStatus;
    }
    
    function donate( bytes32  docHash ) public payable { // Step 4
      require( projects[ docHash ].status == ProjectStatus.Approved, 'Donation rejected: Project not approved' );
      uint don70 = (( msg.value * 7 ) / 10);
      uint don20 = (( msg.value * 2 ) / 10);
      projects[ docHash ].balance += don70;
      universities[ projects[ docHash ].university ].balance += don20 ;
      ownerBalance += (msg.value - don70 - don20 );
      emit DonationAccepted( docHash, msg.value );
    }
    
    function withdraw( bytes32 docHash ) public returns( uint256 amount ) {  // Step 5 (Overloading Function)
      // test that the project exists and has a non-negative balance
      require( projects[ docHash ].balance > 0, 'Withdrwal rejected: nothing to withdraw!' );
      if (msg.sender == projects[ docHash ].author) {
        // appropriate student withdrwal
        amount = projects[ docHash ].balance;
        projects[ docHash ].balance = 0;
        msg.sender.transfer( amount );
        emit ProjectFundsWithdrawn( docHash, msg.sender, amount );
      }
      else {
        // inappropriate student withdrwal attempt
        amount = 0;
        emit BadWithdrawalAttempt( docHash, msg.sender );
      }
    }

    function withdraw() public { // Step 5
      if( universities[ msg.sender ].balance > 0  ) {
        uint256 amount = universities[ msg.sender ].balance;
        universities[ msg.sender ].balance = 0;
        msg.sender.transfer( amount );
        emit UniversityFundsWithdrawn( msg.sender, amount );
      }
      if( msg.sender == owner ) {
        uint256 amount = ownerBalance;
        ownerBalance = 0;
        msg.sender.transfer( amount );
        emit OwnerFundsWithdrawn( msg.sender, amount );
      }
    }
}