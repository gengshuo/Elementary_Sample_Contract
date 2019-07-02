pragma solidity ^0.5.0;

contract PiggyBankVendor {

    address payable owner; // 攤販老闆
    mapping (address => address) public ownedPiggyBank; // 擁有紀錄 (Owner => PiggyBank)

    // 修飾器：是不是老闆
    modifier ifOwner {
      if (msg.sender != owner)
          revert("Sender is Not the Owner");
      _;
    }

    // 修飾器：是不是沒有撲滿
    modifier ifHasNoPiggyBank {
      if (ownedPiggyBank[msg.sender] != address(0))
          revert("Sender has one PiggyBank");
      _;
    }

    // 修飾器：是不是付了足夠的錢
    modifier ifPaidEnough {
      if (msg.value != 1e15) // 1 finney
          revert("Paid amount is not exactly.");
      _;
    }

    // 事件：已建立撲滿
    event PiggyBankCreated(address buyer, address piggyBankAddr);
    // 事件：合約內的錢被取出
    event Withdrawn(uint howMany);

    // 建構式：合約建立時設定擁有者
    constructor() public {
        owner = msg.sender;
    }

    // 取回攤販合約內的錢
    function withdraw() public ifOwner {
      // 一口氣領光
      owner.transfer(address(this).balance);
      // 觸發取錢的事件
      emit Withdrawn(address(this).balance);
    }

    // 跟老闆買一個撲滿合約
    // 一人限購一個，而且要付足夠的ETH
    function buyPiggyBank(string memory name, uint goal) public payable ifHasNoPiggyBank ifPaidEnough {
        // 建立撲滿合約
        PiggyBank pb = new PiggyBank(name, goal);
        // 將建立的撲滿合約地址寫入擁有紀錄
        ownedPiggyBank[msg.sender] = address(pb);
        // 觸發建立事件
        emit PiggyBankCreated(msg.sender, address(pb));
    }

}

contract PiggyBank {

    address payable owner; // 擁有者
    string name; // 替撲滿設定的名稱
    uint goal; // 存錢目標

    // 修飾器：是不是擁有人
    modifier ifOwner {
      if (msg.sender != owner)
          revert("Sender is Not the Owner");
      _;
    }

    // 修飾器：是不是達成目標存款
    modifier ifAchievedGoal {
      if (address(this).balance < goal)
          revert("Goal is Not Achieved");
      _;
    }

    // 事件：有錢存進來了
    event Deposited(address who, uint howMany);
    // 事件：把錢領走了
    event Withdrawn(address who, uint howMany);

    // 看看豬養得多大了
    function getBalance() public view returns (uint) {
      return address(this).balance;
    }

    // 存款餵豬
    function deposit() public payable {
      // 觸發存錢的事件
      emit Deposited(msg.sender, msg.value);
    }

    // 宰殺撲滿： 如果是擁有者而且已經達到設定的存款目標
    function withdraw() public ifOwner ifAchievedGoal {
      // 一口氣領光
      owner.transfer(address(this).balance);
      // 觸發領錢的事件
      emit Withdrawn(msg.sender, address(this).balance);
    }

    // 建構式 （建立時需要設定名稱）
    constructor(
        string memory initName,
        uint initGoal
        ) public {
        name = initName;
        goal = initGoal;
    }

    // Fallback function
    // 只要錢轉進來，就代表是存錢拉
    function() external payable {
        deposit(); // 觸發存款函式，但其實他裡面也只是觸發存款事件
    }

}
