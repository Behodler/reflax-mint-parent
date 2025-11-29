
### OpenZeppelin Standards

**ALWAYS use OpenZeppelin contracts for standard implementations.** This is a mandatory security requirement.

#### Required Standards
- **Always use OpenZeppelin** for standard interfaces (ERC20, ERC721, Ownable, etc.)
- **Custom implementations are prohibited** unless explicitly justified
- **Third-party audited providers** like OpenZeppelin are preferred over custom code
- **Replace in-situ implementations** with OpenZeppelin versions immediately
- **Document any deviation** from OpenZeppelin with clear reasoning and approval

#### Security Rationale
- Custom implementations unnecessarily expand the exploit surface area
- OpenZeppelin contracts are battle-tested and audited by security experts
- Standard implementations reduce maintenance burden and improve interoperability
- Industry standard patterns improve code readability and developer confidence

#### Common OpenZeppelin Imports
```solidity
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
```

#### Implementation Priority
1. **First Priority**: Replace any custom Ownable implementations
2. **Second Priority**: Replace any custom IERC20/IERC721 interfaces
3. **Third Priority**: Replace other security-critical contracts
4. **Document all changes**: List replaced contracts in commit messages
