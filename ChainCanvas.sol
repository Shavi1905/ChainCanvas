// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title ChainCanvas
/// @notice Simple on-chain canvas where users claim/update pixels by paying a fee.
/// @dev Gas-focused minimal implementation for a rectangular canvas.
contract ChainCanvas {
    address public owner;
    uint256 public width;
    uint256 public height;
    uint256 public pricePerPixel; // in wei

    mapping(uint256 => address) public pixelOwner;
    mapping(uint256 => uint32) public pixelColor;
    mapping(uint256 => uint256) public pixelUpdatedAt;

    event PixelSet(address indexed setter, uint256 indexed x, uint256 indexed y, uint32 color, uint256 index);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
    event Withdrawn(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(uint256 _width, uint256 _height, uint256 _pricePerPixel) {
        require(_width > 0 && _height > 0, "Invalid dimensions");
        owner = msg.sender;
        width = _width;
        height = _height;
        pricePerPixel = _pricePerPixel;
    }

    /// @notice Set or purchase a pixel at (x,y) with a 24-bit color value (0xRRGGBB).
    /// @dev If caller already owns the pixel, no payment required. Otherwise msg.value must be >= pricePerPixel.
    function setPixel(uint256 x, uint256 y, uint32 color) external payable {
        require(x < width && y < height, "Out of bounds");
        uint256 index = _index(x, y);
        address prev = pixelOwner[index];

        if (prev != msg.sender) {
            require(msg.value >= pricePerPixel, "Insufficient payment");
            // attempt to forward payment to previous owner (ignore failure)
            if (prev != address(0)) {
                (bool sent, ) = payable(prev).call{value: msg.value}("");
                if (!sent) {
                    // funds remain in contract if transfer fails
                }
            }
        }

        pixelOwner[index] = msg.sender;
        pixelColor[index] = color;
        pixelUpdatedAt[index] = block.timestamp;

        emit PixelSet(msg.sender, x, y, color, index);
    }

    /// @notice Read pixel info for (x,y).
    function getPixel(uint256 x, uint256 y) external view returns (address setter, uint32 color, uint256 updatedAt) {
        require(x < width && y < height, "Out of bounds");
        uint256 index = _index(x, y);
        return (pixelOwner[index], pixelColor[index], pixelUpdatedAt[index]);
    }

    /// @notice Owner can withdraw accumulated contract balance.
    function withdraw(address payable to) external onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "No balance");
        (bool sent, ) = to.call{value: bal}("");
        require(sent, "Withdraw failed");
        emit Withdrawn(to, bal);
    }

    /// @notice Update price per pixel (owner only).
    function setPricePerPixel(uint256 newPrice) external onlyOwner {
        emit PriceUpdated(pricePerPixel, newPrice);
        pricePerPixel = newPrice;
    }

    function _index(uint256 x, uint256 y) internal view returns (uint256) {
        return x + y * width;
    }
}
