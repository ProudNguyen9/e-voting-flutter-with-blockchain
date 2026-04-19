// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FoodTraceability - Hệ thống Truy xuất nguồn gốc thực phẩm
 * @author Lê Nhật Tùng - Đại học Công Nghệ Đồng Nai
 * @notice Smart Contract quản lý chuỗi cung ứng thực phẩm minh bạch
 * @dev Dự án học tập - Blockchain Programming Course
 */

contract FoodTraceability {
    // ========================================
    // PHẦN 1: ĐỊNH NGHĨA CẤU TRÚC DỮ LIỆU
    // ========================================
    
    /**
     * @dev Enum định nghĩa các vai trò trong hệ thống
     * Mỗi người tham gia sẽ được gán một vai trò cụ thể
     */
    enum Role { 
        Admin,          // 0 - Quản trị viên (cấp quyền)
        Farmer,         // 1 - Nông dân (trồng trọt)
        Manufacturer,   // 2 - Nhà máy (chế biến)
        Distributor,    // 3 - Nhà phân phối (vận chuyển)
        Retailer        // 4 - Siêu thị (bán lẻ)
    }
    
    /**
     * @dev Enum trạng thái sản phẩm qua từng giai đoạn
     * Trạng thái chỉ có thể đi theo một chiều (không quay lại)
     */
    enum State {
        Planted,        // 0 - Đã gieo trồng
        Harvested,      // 1 - Đã thu hoạch
        Processed,      // 2 - Đã chế biến
        Shipped,        // 3 - Đang vận chuyển
        Received,       // 4 - Đã nhận hàng
        ForSale         // 5 - Đang bán (sẵn sàng cho người tiêu dùng)
    }
    
    /**
     * @dev Struct lưu thông tin người tham gia
     * Mỗi address sẽ có một profile với vai trò và tên
     */
    struct Participant {
        address account;        // Địa chỉ ví Ethereum
        string name;            // Tên công ty hoặc cá nhân
        Role role;              // Vai trò trong hệ thống
        bool isActive;          // Còn hoạt động hay không
    }
    
    /**
     * @dev Struct lưu thông tin sản phẩm hoàn chỉnh
     * Ghi nhận tất cả các bước trong chuỗi cung ứng
     */
    struct Product {
        uint256 id;                     // Mã sản phẩm duy nhất
        string name;                    // Tên sản phẩm (VD: "Cà phê Arabica")
        State currentState;             // Trạng thái hiện tại
        
        // ===== THÔNG TIN GIAI ĐOẠN TRỒNG TRỌT =====
        address farmer;                 // Địa chỉ nông dân
        uint256 plantedDate;            // Thời điểm gieo trồng (Unix timestamp)
        string farmLocation;            // Vị trí trang trại (tọa độ GPS hoặc địa chỉ)
        
        // ===== THÔNG TIN GIAI ĐOẠN CHẾ BIẾN =====
        address manufacturer;           // Địa chỉ nhà máy
        uint256 processedDate;          // Thời điểm chế biến
        
        // ===== THÔNG TIN GIAI ĐOẠN VẬN CHUYỂN =====
        address distributor;            // Địa chỉ nhà phân phối
        uint256 shippedDate;            // Thời điểm bắt đầu vận chuyển
        
        // ===== THÔNG TIN GIAI ĐOẠN BÁN LẺ =====
        address retailer;               // Địa chỉ siêu thị
        uint256 receivedDate;           // Thời điểm nhận hàng
        uint256 price;                  // Giá bán (tính bằng Wei)
    }

    // ========================================
    // PHẦN 2: BIẾN TRẠNG THÁI (STATE VARIABLES)
    // ========================================
    
    address public admin;               // Địa chỉ quản trị viên hệ thống
    uint256 public productCounter = 0;  // Bộ đếm sản phẩm (tự động tăng)
    
    // Mapping lưu thông tin người tham gia
    mapping(address => Participant) public participants;
    
    // Mapping lưu thông tin sản phẩm
    mapping(uint256 => Product) public products;
    
    // ========================================
    // PHẦN 3: EVENTS (SỰ KIỆN)
    // ========================================
    
    /**
     * @dev Sự kiện khi thêm người tham gia mới
     * Frontend có thể lắng nghe để cập nhật danh sách
     */
    event ParticipantAdded(
        address indexed account, 
        string name, 
        Role role
    );
    
    /**
     * @dev Sự kiện khi xóa người tham gia
     */
    event ParticipantRemoved(address indexed account);
    
    /**
     * @dev Sự kiện khi tạo sản phẩm mới
     */
    event ProductCreated(
        uint256 indexed productId, 
        string name, 
        address indexed farmer,
        uint256 timestamp
    );
    
    /**
     * @dev Sự kiện khi thu hoạch
     */
    event ProductHarvested(
        uint256 indexed productId, 
        uint256 timestamp
    );
    
    /**
     * @dev Sự kiện khi chế biến
     */
    event ProductProcessed(
        uint256 indexed productId, 
        address indexed manufacturer,
        uint256 timestamp
    );
    
    /**
     * @dev Sự kiện khi vận chuyển
     */
    event ProductShipped(
        uint256 indexed productId, 
        address indexed distributor,
        uint256 timestamp
    );
    
    /**
     * @dev Sự kiện khi nhận hàng và đặt giá
     */
    event ProductReceived(
        uint256 indexed productId, 
        address indexed retailer,
        uint256 price,
        uint256 timestamp
    );

    // ========================================
    // PHẦN 4: MODIFIERS (KIỂM TRA QUYỀN)
    // ========================================
    
    /**
     * @dev Chỉ Admin mới được thực hiện
     */
    modifier onlyAdmin() {
        require(
            msg.sender == admin, 
            "Chi admin moi duoc thuc hien hanh dong nay"
        );
        _;
    }
    
    /**
     * @dev Kiểm tra vai trò của người gọi hàm
     * @param _role Vai trò cần kiểm tra
     */
    modifier onlyRole(Role _role) {
        require(
            participants[msg.sender].isActive, 
            "Tai khoan chua duoc kich hoat"
        );
        require(
            participants[msg.sender].role == _role,
            "Ban khong co quyen thuc hien hanh dong nay"
        );
        _;
    }
    
    /**
     * @dev Kiểm tra sản phẩm có tồn tại không
     * @param _productId ID sản phẩm cần kiểm tra
     */
    modifier productExists(uint256 _productId) {
        require(
            _productId > 0 && _productId <= productCounter,
            "San pham khong ton tai"
        );
        _;
    }
    
    // ========================================
    // PHẦN 5: CONSTRUCTOR
    // ========================================
    
    /**
     * @dev Constructor - Khởi tạo admin khi deploy contract
     * Người deploy contract sẽ tự động trở thành admin
     */
    constructor() {
        admin = msg.sender;
        
        // Tự động thêm admin vào danh sách participants
        participants[admin] = Participant({
            account: admin,
            name: "System Administrator",
            role: Role.Admin,
            isActive: true
        });
        
        emit ParticipantAdded(admin, "System Administrator", Role.Admin);
    }

    // ========================================
    // PHẦN 6: QUẢN LÝ NGƯỜI THAM GIA
    // ========================================
    
    /**
     * @dev Admin thêm người tham gia mới vào hệ thống
     * @param _account Địa chỉ ví của người tham gia
     * @param _name Tên công ty hoặc cá nhân
     * @param _role Vai trò được gán
     */
    function addParticipant(
        address _account,
        string memory _name,
        Role _role
    ) public onlyAdmin {
        require(
            _account != address(0),
            "Dia chi khong hop le"
        );
        require(
            !participants[_account].isActive,
            "Nguoi nay da ton tai trong he thong"
        );
        
        participants[_account] = Participant({
            account: _account,
            name: _name,
            role: _role,
            isActive: true
        });
        
        emit ParticipantAdded(_account, _name, _role);
    }
    
    /**
     * @dev Admin xóa người tham gia khỏi hệ thống
     * @param _account Địa chỉ cần xóa
     */
    function removeParticipant(address _account) public onlyAdmin {
        require(
            participants[_account].isActive,
            "Nguoi nay khong ton tai"
        );
        require(
            _account != admin,
            "Khong the xoa admin"
        );
        
        participants[_account].isActive = false;
        emit ParticipantRemoved(_account);
    }
    
    /**
     * @dev Kiểm tra thông tin người tham gia
     * @param _account Địa chỉ cần kiểm tra
     */
    function getParticipant(address _account) 
        public 
        view 
        returns (
            string memory name,
            Role role,
            bool isActive
        ) 
    {
        Participant memory p = participants[_account];
        return (p.name, p.role, p.isActive);
    }

    // ========================================
    // PHẦN 7: QUẢN LÝ SẢN PHẨM
    // ========================================
    
    /**
     * @dev FARMER: Tạo sản phẩm mới (giai đoạn gieo trồng)
     * @param _name Tên sản phẩm
     * @param _farmLocation Vị trí trang trại
     * @return productId ID của sản phẩm vừa tạo
     */
    function createProduct(
        string memory _name,
        string memory _farmLocation
    ) public onlyRole(Role.Farmer) returns (uint256) {
        
        productCounter++;
        
        products[productCounter] = Product({
            id: productCounter,
            name: _name,
            currentState: State.Planted,
            farmer: msg.sender,
            plantedDate: block.timestamp,
            farmLocation: _farmLocation,
            manufacturer: address(0),
            processedDate: 0,
            distributor: address(0),
            shippedDate: 0,
            retailer: address(0),
            receivedDate: 0,
            price: 0
        });
        
        emit ProductCreated(
            productCounter, 
            _name, 
            msg.sender,
            block.timestamp
        );
        
        return productCounter;
    }
    
    /**
     * @dev FARMER: Đánh dấu sản phẩm đã thu hoạch
     * @param _productId ID sản phẩm
     */
    function harvestProduct(uint256 _productId) 
        public 
        onlyRole(Role.Farmer)
        productExists(_productId)
    {
        Product storage product = products[_productId];
        
        require(
            product.farmer == msg.sender,
            "Ban khong phai nguoi trong san pham nay"
        );
        require(
            product.currentState == State.Planted,
            "San pham khong o trang thai Planted"
        );
        
        product.currentState = State.Harvested;
        emit ProductHarvested(_productId, block.timestamp);
    }
    
    /**
     * @dev MANUFACTURER: Nhận và chế biến sản phẩm
     * @param _productId ID sản phẩm
     */
    function processProduct(uint256 _productId) 
        public 
        onlyRole(Role.Manufacturer)
        productExists(_productId)
    {
        Product storage product = products[_productId];
        
        require(
            product.currentState == State.Harvested,
            "San pham chua thu hoach"
        );
        
        product.manufacturer = msg.sender;
        product.processedDate = block.timestamp;
        product.currentState = State.Processed;
        
        emit ProductProcessed(_productId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev DISTRIBUTOR: Vận chuyển sản phẩm
     * @param _productId ID sản phẩm
     */
    function shipProduct(uint256 _productId) 
        public 
        onlyRole(Role.Distributor)
        productExists(_productId)
    {
        Product storage product = products[_productId];
        
        require(
            product.currentState == State.Processed,
            "San pham chua che bien"
        );
        
        product.distributor = msg.sender;
        product.shippedDate = block.timestamp;
        product.currentState = State.Shipped;
        
        emit ProductShipped(_productId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev RETAILER: Nhận hàng và đặt giá bán
     * @param _productId ID sản phẩm
     * @param _price Giá bán (tính bằng Wei)
     */
    function receiveProduct(
        uint256 _productId,
        uint256 _price
    ) 
        public 
        onlyRole(Role.Retailer)
        productExists(_productId)
    {
        Product storage product = products[_productId];
        
        require(
            product.currentState == State.Shipped,
            "San pham chua van chuyen"
        );
        require(
            _price > 0,
            "Gia phai lon hon 0"
        );
        
        product.retailer = msg.sender;
        product.receivedDate = block.timestamp;
        product.price = _price;
        product.currentState = State.ForSale;
        
        emit ProductReceived(_productId, msg.sender, _price, block.timestamp);
    }
    
    // ========================================
    // PHẦN 8: XEM LỊCH SỬ SẢN PHẨM (PUBLIC)
    // ========================================
    
    /**
     * @dev Xem toàn bộ lịch sử sản phẩm - CÔNG KHAI cho người tiêu dùng
     * @param _productId ID sản phẩm cần tra cứu
     * @return name Tên sản phẩm
     * @return currentState Trạng thái hiện tại
     * @return farmerName Tên nông dân
     * @return farmLocation Vị trí trang trại
     * @return plantedDate Ngày gieo trồng
     * @return manufacturerName Tên nhà máy
     * @return processedDate Ngày chế biến
     * @return distributorName Tên nhà phân phối
     * @return shippedDate Ngày vận chuyển
     * @return retailerName Tên siêu thị
     * @return receivedDate Ngày nhận hàng
     * @return price Giá bán
     */
    function getProductHistory(uint256 _productId) 
        public 
        view 
        productExists(_productId)
        returns (
            string memory name,
            State currentState,
            string memory farmerName,
            string memory farmLocation,
            uint256 plantedDate,
            string memory manufacturerName,
            uint256 processedDate,
            string memory distributorName,
            uint256 shippedDate,
            string memory retailerName,
            uint256 receivedDate,
            uint256 price
        ) 
    {
        Product memory product = products[_productId];
        
        return (
            product.name,
            product.currentState,
            participants[product.farmer].name,
            product.farmLocation,
            product.plantedDate,
            participants[product.manufacturer].name,
            product.processedDate,
            participants[product.distributor].name,
            product.shippedDate,
            participants[product.retailer].name,
            product.receivedDate,
            product.price
        );
    }
    
    /**
     * @dev Lấy trạng thái hiện tại của sản phẩm
     * @param _productId ID sản phẩm
     */
    function getProductState(uint256 _productId) 
        public 
        view 
        productExists(_productId)
        returns (State) 
    {
        return products[_productId].currentState;
    }
    
    /**
     * @dev Đếm tổng số sản phẩm trong hệ thống
     */
    function getTotalProducts() public view returns (uint256) {
        return productCounter;
    }
    
    // ========================================
    // PHẦN 9: HELPER FUNCTIONS
    // ========================================
    
    /**
     * @dev Chuyển đổi State enum sang chuỗi văn bản
     * @param _state Trạng thái cần chuyển đổi
     */
    function stateToString(State _state) 
        public 
        pure 
        returns (string memory) 
    {
        if (_state == State.Planted) return "Da gieo trong";
        if (_state == State.Harvested) return "Da thu hoach";
        if (_state == State.Processed) return "Da che bien";
        if (_state == State.Shipped) return "Dang van chuyen";
        if (_state == State.Received) return "Da nhan hang";
        if (_state == State.ForSale) return "Dang ban";
        return "Khong xac dinh";
    }
    
    /**
     * @dev Chuyển đổi Role enum sang chuỗi văn bản
     * @param _role Vai trò cần chuyển đổi
     */
    function roleToString(Role _role) 
        public 
        pure 
        returns (string memory) 
    {
        if (_role == Role.Admin) return "Quan tri vien";
        if (_role == Role.Farmer) return "Nong dan";
        if (_role == Role.Manufacturer) return "Nha may";
        if (_role == Role.Distributor) return "Nha phan phoi";
        if (_role == Role.Retailer) return "Sieu thi";
        return "Khong xac dinh";
    }
}