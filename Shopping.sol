pragma solidity ^0.5.0;

contract MyShop {

    address payable public manager;
    string shop_name;
    address[] product_list;
    mapping (address => address[]) public orders; // OrderOwner(Address) => Order[]

    modifier ifManager {
      if (msg.sender != manager)
          revert("Sender is Not a Manager");

      _;
    }

    modifier ifPaidExactly(address payable prod_addr, uint amount) {
      uint unit_price = MyProduct(prod_addr).unitPrice();
      if(msg.value != unit_price * amount)
        revert("Please pay correct ETH amount of the order.");

      _;
    }

    modifier ifProductEnough(address payable prod_addr, uint need_amount) {
      if(MyProduct(prod_addr).amount() < need_amount)
        revert("Prouduct amount is less than needed amount.");

      _;
    }

    constructor() public {
      manager = msg.sender;
    }

    function addProduct(string memory name, uint amount, uint unit_price) public ifManager {
      MyProduct mp = new MyProduct(name, amount, unit_price, msg.sender);
      product_list.push(address(mp));
    }

    function purchase(address payable prod_addr, uint need_amount) public payable
    ifProductEnough(prod_addr, need_amount) ifPaidExactly(prod_addr, need_amount) {
      MyProduct mp = MyProduct(prod_addr);
      mp.decrement(need_amount);

      MyOrder mo = new MyOrder(msg.sender, prod_addr, need_amount, mp.unitPrice());
      orders[msg.sender].push(address(mo));
    }

    function setShopName(string memory name) public ifManager {
      shop_name = name;
    }
    
    function getProds() public view returns (address[] memory) {
        return product_list;
    }
}

contract MyProduct {

    address payable shopAddr;
    address payable creator;

    string name;
    uint public amount;
    uint public unitPrice; // N ehter / 1 pc

    constructor(
        string memory initName,
        uint initAmount,
        uint initUnitPrice,
        address payable initCreator
    ) public {
      shopAddr = msg.sender;
      name = initName;
      amount = initAmount;
      unitPrice = initUnitPrice;
      creator = initCreator;
    }

    modifier ifMyShop {
      if (msg.sender != shopAddr)
          revert("Sender is Not My Shop");

      _;
    }

    function increment(uint n) public ifMyShop {
      amount += n;
    }

    function decrement(uint n) public ifMyShop {
      amount -= n;
    }

    function setPrice(uint n) public ifMyShop {
      unitPrice = n;
    }
}

contract MyOrder {

    address payable shopAddr;
    address payable buyer;

    address payable public product;
    uint public amount; // How many product that user bought.
    uint public unitPrice; // N ehter / 1 pc (How much user paid currently for 1 product)

    constructor(
        address payable order_buyer,
        address payable productAddr,
        uint gotAmount,
        uint paidUnitPrice
    ) public {
      shopAddr = msg.sender;
      buyer = order_buyer;
      product = productAddr;
      amount = gotAmount;
      unitPrice = paidUnitPrice;
    }

}