contract OracleReader {
    /**
    * @notice The Chronicle oracle to read from.
    * Chronicle_ETH_USD_3:0xdd6D76262Fd7BdDe428dcfCd94386EbAe0151603
    * Network: Base Sepolia
    */
    IChronicle public chronicle = IChronicle(address(0xCf2aF249b2d71B33339B9613E78f8D1B7F9eeE83));

    /** 
    * @notice The SelfKisser granting access to Chronicle oracles.
    * SelfKisser_1:0x0Dcc19657007713483A5cA76e6A7bbe5f56EA37d
    * Network: Base Sepolia
    */
    ISelfKisser public selfKisser = ISelfKisser(address(0x70E58b7A1c884fFFE7dbce5249337603a28b8422));

    constructor() {
        // Note to add address(this) to chronicle oracle's whitelist.
        // This allows the contract to read from the chronicle oracle.
        selfKisser.selfKiss(address(chronicle));
    }

    /** 
    * @notice Function to read the latest data from the Chronicle oracle.
    * @return val The current value returned by the oracle.
    * @return age The timestamp of the last update from the oracle.
    */
    function read() external view returns (uint256 val, uint256 age) {
        (val, age) = chronicle.readWithAge();
    }
}

// Interest-bearing stablecoin contract that integrates with Chronicle
contract InterestBearingStablecoin is Ownable {
    struct Deposit {
        uint256 stethAmount;
        uint256 depositTime;
    }

    IERC20 public usdc;
    IERC20 public steth;
    OracleReader public oracleReader;
    IDEX public dex;

    mapping(address => Deposit) public deposits;

    event Deposited(address indexed user, uint256 usdcAmount, uint256 stethAmount);
    event Withdrawn(address indexed user, uint256 usdcAmount, uint256 interest);

    constructor(
        address _usdc,
        address _steth,
        address _oracleReader,
        address _dex
    ) Ownable(msg.sender) {
        usdc = IERC20(_usdc);
        steth = IERC20(_steth);
        oracleReader = OracleReader(_oracleReader);
        dex = IDEX(_dex);
    }

    function depositUSDC(uint256 usdcAmount) external {
        require(usdcAmount > 0, "Amount must be greater than zero");

        require(usdc.transferFrom(msg.sender, address(this), usdcAmount), "USDC transfer failed");

        uint256 stethAmount = dex.swapTokens(address(usdc), address(steth), usdcAmount);

        deposits[msg.sender] = Deposit({
            stethAmount: stethAmount,
            depositTime: block.timestamp
        });

        emit Deposited(msg.sender, usdcAmount, stethAmount);
    }

    function withdraw() external {
        Deposit storage userDeposit = deposits[msg.sender];
        require(userDeposit.stethAmount > 0, "No active deposit");

        uint256 timeElapsed = block.timestamp - userDeposit.depositTime;

        (uint256 interestRate, ) = oracleReader.read();
        uint256 interest = calculateInterest(userDeposit.stethAmount, timeElapsed, interestRate);

        uint256 usdcAmount = dex.swapTokens(address(steth), address(usdc), userDeposit.stethAmount);

        uint256 totalPayout = usdcAmount + interest;

        delete deposits[msg.sender];

        require(usdc.transfer(msg.sender, totalPayout), "USDC transfer failed");

        emit Withdrawn(msg.sender, usdcAmount, interest);
    }

    function calculateInterest(
        uint256 principal,
        uint256 timeElapsed,
        uint256 annualRate
    ) public pure returns (uint256) {
        uint256 timeInYears = timeElapsed * 1e18 / 365 days;
        uint256 rate = annualRate * 1e12 / 10_000;
        return (principal * rate * timeInYears) / 1e18;
    }

    function setOracleReader(address _oracleReader) external onlyOwner {
        oracleReader = OracleReader(_oracleReader);
    }

    function setDex(address _dex) external onlyOwner {
        dex = IDEX(_dex);
    }
}
