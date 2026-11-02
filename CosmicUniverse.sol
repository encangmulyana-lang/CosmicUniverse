// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CosmicUniverse is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant MINT_PRICE = 0.0005 ether;
    uint256 public constant MAX_MINT_PER_TX = 10;
    uint256 public totalMinted;
    bool public mintPaused;
    string private _customBaseURI;
    mapping(address => uint256) public mintedByWallet;
    event Minted(address indexed to, uint256 indexed tokenId);
    event BaseURISet(string baseURI);
    event MintPausedChanged(bool paused);
    constructor(string memory baseURI_) ERC721("CosmicUniverse", "COSMIC") Ownable(msg.sender) {
        _customBaseURI = baseURI_;
    }
    function _baseURI() internal view override returns (string memory) { return _customBaseURI; }
    function currentPrice() public pure returns (uint256) { return MINT_PRICE; }
    function mint(uint256 quantity) external payable nonReentrant {
        require(!mintPaused, "CosmicUniverse: mint is paused");
        require(quantity > 0 && quantity <= MAX_MINT_PER_TX, "CosmicUniverse: quantity 1-10 per tx");
        require(totalMinted + quantity <= MAX_SUPPLY, "CosmicUniverse: exceeds supply");
        require(msg.value == MINT_PRICE * quantity, "CosmicUniverse: wrong value");
        for (uint256 i = 0; i < quantity; i++) {
            totalMinted += 1;
            uint256 tokenId = totalMinted;
            _safeMint(msg.sender, tokenId);
            emit Minted(msg.sender, tokenId);
        }
        mintedByWallet[msg.sender] += quantity;
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "CosmicUniverse: token does not exist");
        string memory base = _baseURI();
        if (bytes(base).length == 0) return "";
        return string(abi.encodePacked(base, tokenId.toString(), ".json"));
    }
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _customBaseURI = baseURI_;
        emit BaseURISet(baseURI_);
    }
    function setMintPaused(bool paused) external onlyOwner {
        mintPaused = paused;
        emit MintPausedChanged(paused);
    }
    function withdraw() external onlyOwner {
        (bool ok, ) = payable(owner()).call{value: address(this).balance}("");
        require(ok, "CosmicUniverse: withdraw failed");
    }
}
