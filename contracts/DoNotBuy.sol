// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {uint256 c = a + b; if(c < a) return(false, 0); return(true, c);}}

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b > a) return(false, 0); return(true, a - b);}}

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if (a == 0) return(true, 0); uint256 c = a * b;
        if(c / a != b) return(false, 0); return(true, c);}}

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a / b);}}

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a % b);}}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); return a - b;}}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a / b;}}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a % b;}}}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

struct route {
    address from;
    address to;
    bool stable;
}

interface IFactory {
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
    function getPair(address tokenA, address tokenB, bool stable) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function wETH() external pure returns (address);
    function getAmountsOut(uint amountIn, route[] calldata routes) external view returns (uint[] memory amounts);
    function addLiquidityETH(
        address token,
        bool stable,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    route[] calldata routes,
    address to,
    uint deadline
   ) external;
}

contract DoNotBuy is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = 'Do Not Buy';
    string private constant _symbol = 'DNB';
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 100000000 * (10 ** _decimals);
    uint256 private _maxTxAmount = ( _totalSupply * 25 ) / 10000;
    uint256 private _maxSellAmount = ( _totalSupply * 25 ) / 10000;
    uint256 private _maxWalletToken = ( _totalSupply * 200 ) / 10000;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) private isBot;
    IRouter router;
    address public pair;
    bool private tradingAllowed = false;
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 2000;
    uint256 private rewardsFee = 7000;
    uint256 private developmentFee = 1000;
    uint256 private burnFee = 0;
    uint256 private totalFee = 1000;
    uint256 private sellFee = 1500;
    uint256 private transferFee = 200;
    uint256 private denominator = 10000;
    bool private swapEnabled = true;
    uint256 private swapTimes;
    bool private swapping; 
    uint256 private swapThreshold = ( _totalSupply * 250 ) / 100000;
    uint256 private _minTokenAmount = ( _totalSupply * 10 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    address public reward = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 internal dividendsPerShare;
    uint256 internal dividendsPerShareAccuracyFactor = 10 ** 36;
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    struct Share {uint256 amount; uint256 totalExcluded; uint256 totalRealised; }
    mapping (address => Share) public shares;
    uint256 internal currentIndex;
    uint256 public minPeriod = 1 minutes;
    uint256 public minDistribution = 1 * (10 ** 5);
    uint256 public distributorGas = 350000;
    function _claimDividend() external {distributeDividend(msg.sender);}


    // Mutable receiver addresses
    address internal marketing_receiver = 0x27DFbEC90EEa392446f71638b70193c6F558c001;
    address internal development_receiver = 0x0F245A7D374388CD76fC8139Dd900E9B02bF69d7;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal constant liquidity_receiver = 0xd53686b4298Ac78B1d182E95FeAC1A4DD1D780bD;

    constructor() Ownable(msg.sender) {
        isFeeExempt[address(this)] = true;
        isFeeExempt[liquidity_receiver] = true;
        isFeeExempt[marketing_receiver] = true;
        isFeeExempt[msg.sender] = true;
        isDividendExempt[address(msg.sender)] = true;        
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(DEAD)] = true;
        isDividendExempt[address(0)] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }




    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function getOwner() external view override returns (address) { return owner; }
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function isCont(address addr) internal view returns (bool) {uint size; assembly { size := extcodesize(addr) } return size > 0; }
    function setisExempt(address _address, bool _enabled) external onlyOwner {isFeeExempt[_address] = _enabled;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function circulatingSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function startTrading() external onlyOwner {
        require(!tradingAllowed,"trading is already open");
        tradingAllowed = true;
    }

    function setPair(address _routerAddress) external onlyOwner {
        require(_routerAddress != address(0), "Router cannot be zero address");
        router = IRouter(_routerAddress);
        pair = IFactory(router.factory()).getPair(address(this), router.wETH(), false);
        if (pair == address(0)) {
            pair = IFactory(router.factory()).createPair(address(this), router.wETH(), false);
        }
        isDividendExempt[pair] = true;
    }

    function preTxCheck(address sender, address recipient, uint256 amount) internal view {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > uint256(0), "Transfer amount must be greater than zero");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
    }

function _transfer(address sender, address recipient, uint256 amount) private {
    require(sender != address(0), "ERC20: transfer from zero address");
    require(recipient != address(0), "ERC20: transfer to zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    require(amount <= _balances[sender], "Insufficient balance");

    bool isSenderExempt = isFeeExempt[sender];
    bool isRecipientExempt = isFeeExempt[recipient];
    bool isSell = recipient == pair;
    bool isBuy = sender == pair;

    if (!isSenderExempt && !isRecipientExempt) {
        require(tradingAllowed, "Trading not allowed");
        if (!isSell && recipient != address(DEAD)) {
            require(_balances[recipient] + amount <= _maxWalletToken, "Exceeds max wallet");
        }
        require(amount <= _maxTxAmount, "Exceeds max tx amount");
        if (!isBuy) {
            require(amount <= _maxSellAmount, "Exceeds max sell amount");
        }
    }

    if (isSell && !isSenderExempt) {
        swapTimes++;
    }

    uint256 contractBalance = _balances[address(this)];
    bool shouldSwap = !swapping && swapEnabled && tradingAllowed && !isSenderExempt && isSell &&
                      swapTimes >= 2 && amount >= _minTokenAmount && contractBalance >= swapThreshold;
    if (shouldSwap) {
        swapandreward(swapThreshold);
        swapTimes = 0;
    }

    _balances[sender] -= amount;
    uint256 amountReceived = (isSenderExempt || isRecipientExempt) ? amount : takeFee(sender, recipient, amount);
    _balances[recipient] += amountReceived;

    emit Transfer(sender, recipient, amountReceived);

    bool senderHasShares = !isDividendExempt[sender];
    bool recipientHasShares = !isDividendExempt[recipient];

    if (senderHasShares || recipientHasShares) {
        if (senderHasShares && !isCont(sender)) {
            if (isSell && shouldSwap) {
                distributeDividend(sender); // Sender only on sell with swap
            } else if (!isSell && !isBuy) {
                distributeDividend(sender); // Sender on transfer
            }
            setShare(sender, _balances[sender]);
        }
        if (recipientHasShares && !isCont(recipient)) {
           if (isBuy) {
               distributeDividend(recipient);
           } else if (!isSell && !shouldSwap && !isBuy) {
                distributeDividend(recipient); // Recipient on transfer
            }
            setShare(recipient, _balances[recipient]);
        }
    }
}



    

  function setStructure(
    uint256 _liquidity,
    uint256 _marketing,
    uint256 _burn,
    uint256 _rewards,
    uint256 _development,
    uint256 _total,
    uint256 _sell,
    uint256 _trans
) external onlyOwner {
    liquidityFee = _liquidity;
    marketingFee = _marketing;
    burnFee = _burn;
    rewardsFee = _rewards;
    developmentFee = _development;
    totalFee = _total;
    sellFee = _sell;
    transferFee = _trans;
    require(
        totalFee <= denominator.mul(30).div(100) &&
        sellFee <= denominator.mul(30).div(100) &&
        transferFee <= denominator.mul(30).div(100),
        "Fees cannot exceed 30%"
    );
}

function getCurrentFeesAsPercent() public view returns (
    uint256 liquidity,
    uint256 marketing,
    uint256 burn,
    uint256 rewards,
    uint256 development,
    uint256 total,
    uint256 sell,
    uint256 transfersFee
) {
    return (
        liquidityFee.div(100),
        marketingFee.div(100),
        burnFee.div(100),
        rewardsFee.div(100),
        developmentFee.div(100),
        totalFee.div(100),
        sellFee.div(100),
        transferFee.div(100)
    );
}


/// @notice Sets a new swap threshold for triggering token-to-ETH swaps.
/// @param _newThreshold The new threshold in tokens (must be at least 0.1% of total supply).
/// @dev Only callable by the owner. Emits no event as state change is trackable via transaction logs.
function setSwapThreshold(uint256 _newThreshold) external onlyOwner {
    require(_newThreshold >= (_totalSupply * 100) / 100000, "Threshold cannot be less than 0.1% of total supply");
    require(_newThreshold <= (_totalSupply * 1000) / 100000, "Threshold cannot exceed 1% of total supply");
    swapThreshold = _newThreshold;
    emit SwapThresholdUpdated(_newThreshold);
}


/// @notice Emitted when the marketing receiver address is updated.
/// @param newReceiver The new marketing receiver address.
event MarketingReceiverUpdated(address indexed newReceiver);


/// @notice Emitted when the development receiver address is updated.
/// @param newReceiver The new development receiver address.
event DevelopmentReceiverUpdated(address indexed newReceiver);


/// @notice Emitted when tokens are swapped for ETH in the swap and reward system.
/// @param tokenAmount The amount of tokens swapped.
/// @param ethReceived The amount of ETH received from the swap.
event SwapTriggered(uint256 indexed tokenAmount, uint256 ethReceived);


/// @notice Emitted when the swap threshold is updated.
/// @param newThreshold The new swap threshold in tokens.
event SwapThresholdUpdated(uint256 newThreshold);

/// @notice Sets a new marketing receiver address.
/// @param _newReceiver The new address to receive marketing fees.
/// @dev Only callable by the owner. The new address cannot be the zero address.
function setMarketingReceiver(address _newReceiver) external onlyOwner {
    require(_newReceiver != address(0), "Cannot set to zero address");
    isFeeExempt[marketing_receiver] = false; // Remove exemption from old receiver
    marketing_receiver = _newReceiver;
    isFeeExempt[_newReceiver] = true; // Add exemption to new receiver
    emit MarketingReceiverUpdated(_newReceiver);
}

/// @notice Sets a new development receiver address.
/// @param _newReceiver The new address to receive development fees.
/// @dev Only callable by the owner. The new address cannot be the zero address.
function setDevelopmentReceiver(address _newReceiver) external onlyOwner {
    require(_newReceiver != address(0), "Cannot set to zero address");
    development_receiver = _newReceiver;
    emit DevelopmentReceiverUpdated(_newReceiver);
}



    function setisBot(address _address, bool _enabled) external onlyOwner {
        require(_address != address(pair) && _address != address(router) && _address != address(this), "Ineligible Address");
        isBot[_address] = _enabled;
    }

    function setParameters(uint256 _buy, uint256 _trans, uint256 _wallet) external onlyOwner {
    require(_buy <= 200 && _trans <= 200 && _wallet <= 200, "Cannot exceed 2%");
    uint256 newTx = (totalSupply() * _buy) / 10000;
    uint256 newTransfer = (totalSupply() * _trans) / 10000;
    uint256 newWallet = (totalSupply() * _wallet) / 10000;
    _maxTxAmount = newTx;
    _maxSellAmount = newTransfer;
    _maxWalletToken = newWallet;
    uint256 limit = totalSupply().mul(25).div(10000); // 0.25%
    require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than 0.25%");
}



function getMaxTxAmount() public view returns (uint256 amount, uint256 percentage) {
    return (_maxTxAmount, (_maxTxAmount * 10000) / totalSupply());
}
function getMaxSellAmount() public view returns (uint256 amount, uint256 percentage) {
    return (_maxSellAmount, (_maxSellAmount * 10000) / totalSupply());
}
function getMaxWalletAmount() public view returns (uint256 amount, uint256 percentage) {
    return (_maxWalletToken, (_maxWalletToken * 10000) / totalSupply());
}

    function checkTradingAllowed(address sender, address recipient) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){require(tradingAllowed, "tradingAllowed");}
    }
    
    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient] && recipient != address(pair) && recipient != address(DEAD)){
            require((_balances[recipient].add(amount)) <= _maxWalletToken, "Exceeds maximum wallet amount.");}
    }

    function swapbackCounters(address sender, address recipient) internal {
        if(recipient == pair && !isFeeExempt[sender]){swapTimes += uint256(1);}
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        if(sender != pair){require(amount <= _maxSellAmount || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxAmount || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");
    }

    

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            false,
            tokenAmount,
            0,
            0,
            liquidity_receiver,
            block.timestamp);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        route[] memory routes = new route[](1);
        routes[0] = route({
            from: address(this),
            to: router.wETH(),
            stable: false
        });
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            routes,
            address(this),
            block.timestamp);
    }

    function swapETHForRewardToken(uint256 ethAmount) external onlyOwner {
        route[] memory routes = new route[](1);
        routes[0] = route({
            from: router.wETH(),
            to: reward,
            stable: true
        });
       
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0,
            routes,
            address(this),
            block.timestamp);
    }


    function shouldSwapBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minTokenAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && tradingAllowed && aboveMin && !isFeeExempt[sender] && recipient == pair && swapTimes >= uint256(2) && aboveThreshold;
    }

function depositreward(uint256 amount) private {
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

function swapandreward(uint256 tokens) private lockTheSwap {
    uint256 _denominator = marketingFee + developmentFee + rewardsFee;

    // Swap tokens for ETH
    uint256 initialBalance = address(this).balance;
    swapTokensForETH(tokens);
    uint256 deltaBalance = address(this).balance - initialBalance;

    emit SwapTriggered(tokens, deltaBalance);

    // Calculate unit ETH per fee weight
    uint256 unitBalance = deltaBalance / _denominator;

    // Distribute ETH based on fee allocations
    uint256 rewardsAmount = unitBalance * rewardsFee;
    if (rewardsAmount > 0) {
        depositreward(rewardsAmount); // Assumes deposit handles ETH distribution for rewards
    }

    uint256 marketingAmount = unitBalance * marketingFee;
    if (marketingAmount > 0) {
        payable(marketing_receiver).transfer(marketingAmount);
    }

    // Calculate the remaining balance after rewards and marketing
    uint256 usedBalance = rewardsAmount + marketingAmount;
    uint256 remaining = deltaBalance > usedBalance ? deltaBalance - usedBalance : 0;

    if (remaining > 0) {
        payable(development_receiver).transfer(remaining);
    }
}

    function swapBack(address sender, address recipient, uint256 amount) internal {
        if(shouldSwapBack(sender, recipient, amount)){swapandreward(swapThreshold); swapTimes = uint256(0);}
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(isBot[sender] || isBot[recipient]){return denominator.sub(uint256(100));}
        if(recipient == pair){return sellFee;}
        if(sender == pair){return totalFee;}
        return transferFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(getTotalFee(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0)){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function triggerSwap(uint256 tokens) external onlyOwner {
        swapandreward(tokens);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setisDividendExempt(address holder, bool exempt) external onlyOwner {
        isDividendExempt[holder] = exempt;
        if(exempt){setShare(holder, 0);}
        else{setShare(holder, balanceOf(holder)); }
    }

    function setShare(address shareholder, uint256 amount) internal {
        if(amount > 0 && shares[shareholder].amount == 0){addShareholder(shareholder);}
        else if(amount == 0 && shares[shareholder].amount > 0){removeShareholder(shareholder); }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    

    function processDistribution(uint256 gas) external {
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0) { return; }
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){currentIndex = 0;}
            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);}
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

   function rescueERC20(address _address, uint256 _amount) external onlyOwner {
    IERC20(_address).transfer(marketing_receiver, _amount);

    }

function getExcessETH() public view returns (uint256) {
    uint256 contractBalance = address(this).balance;
    uint256 pendingDividends = totalDividends - totalDistributed;

    // Safety check: totalDividends should always be >= totalDistributed
    if (pendingDividends > contractBalance) return 0;

    return contractBalance - pendingDividends;
}

function rescueExcessETH(address to) external onlyOwner {
    uint256 excess = getExcessETH();
    require(excess > 0, "No excess ETH");
    (bool success, ) = payable(to).call{value: excess}("");
    require(success, "Transfer failed");
}

function forceDistributeExcessETH() external onlyOwner {
    uint256 unallocated = getExcessETH();
    require(unallocated > 0, "No unallocated ETH");
    totalDividends += unallocated;
    dividendsPerShare += (unallocated * dividendsPerShareAccuracyFactor) / totalShares;
}
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function totalRewardsDistributed(address _wallet) external view returns (uint256) {
        address shareholder = _wallet;
        return uint256(shares[shareholder].totalRealised);
    }

function distributeDividend(address shareholder) private {
    Share storage share = shares[shareholder];
    uint256 amount = getUnpaidEarnings(shareholder);

    if (share.amount == 0 || amount == 0) return;

    totalDistributed += amount;
    
    // Use transfer instead of call
    payable(shareholder).transfer(amount);

    shareholderClaims[shareholder] = block.timestamp;
    share.totalRealised += amount;
    share.totalExcluded = getCumulativeDividends(share.amount);
}

    

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _distributorGas) external onlyOwner {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        distributorGas = _distributorGas;
    }
}
