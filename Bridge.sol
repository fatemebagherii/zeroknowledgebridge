//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ERC20Token {

    // --- ERC20 Data ---
    string  public name;
    string  public symbol;
    string  public version;
    uint8   public decimals;
    uint256 public totalSupply;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint)                      public nonces;

    // event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Mint(address indexed addr, uint wad);
    event Burn(address indexed addr, uint wad);

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    constructor(string memory _name, string memory _symbol, string memory _version, uint8 _decimal) {
        name = _name;
        symbol = _symbol;
        version = _version;
        decimals = _decimal;
        // Initialize totalSupply here
        totalSupply = 1000000 * 10**uint256(decimals);

        // Assign total supply to the contract deployer
        balanceOf[msg.sender] = totalSupply;

        // Emit transfer event to reflect the initial allocation
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // --- Token ---
    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    
    function transferFrom(address src, address dst, uint wad)
        public returns (bool){
        require(balanceOf[src] >= wad, "Insufficient balance");
        // require(src == msg.sender || allowance[src][msg.sender] >= wad, "Insufficient allowance");
        
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        
        // if (src != msg.sender){
        //     allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        // }
        emit Transfer(src, dst, wad);
        
        return true;
    }
    
    function mint(address usr, uint wad) external {
        balanceOf[usr] += wad;
        totalSupply    += wad;
        emit Mint(usr, wad);
    }
    
    function burn(address usr, uint wad) external {
        require(balanceOf[usr] >= wad, "Insufficient balance");
        balanceOf[usr] -= wad;
        totalSupply    -= wad;
        
        emit Burn(usr, wad);
    }


}

interface ERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function burn(address usr, uint wad) external;
    function mint(address usr, uint wad) external;
}

library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
    
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x17682dd81cbe0df980c2ec1939c2e97e3efd67ea2775593248457e046e7a6271), uint256(0x28e8a20ac944bb27c5ca34ca493f0d2cf1f8fd526c618d882f63235d8fc50563));
        vk.beta = Pairing.G2Point([uint256(0x0ef652a47e12600f5fe14b11caa893c07107f9d845ea9f573e5a27800ae61795), uint256(0x0761c5a1bcfda30572a3b0e9d9afdfbee7ed74950172d8c5bba6b025c0d532a5)], [uint256(0x0956937c0fc55ec8ccd5ed584afd321debf6355bd47f0174f2c2c7c42c2375b6), uint256(0x1365ac764138153c5241b45380a30da544259339dad57a1927e3128d3e55fbc5)]);
        vk.gamma = Pairing.G2Point([uint256(0x2bb0dc006332f0e38ddf8791c866089a993821e2072817f4e35cd2e5010efca2), uint256(0x133b902687cd0e2276549508988e73e4355d1366be8d1718da1addf24b37fd81)], [uint256(0x2c84c41d9e45a8ed924a6ff6f06f9959881ddd3816deb6499491979251cdf457), uint256(0x02fadae9a699fa404be4b12df4f966078c0c170cf91c3c2c80b9c4a6c39f960e)]);
        vk.delta = Pairing.G2Point([uint256(0x1da23eacf72c51b3cb0dace1c756b2e0be0476b05edadef7d1572144d7b26b28), uint256(0x1caa5f4497763295f69554a3801fc89b4f8507e14a596bab150c65dd55c21798)], [uint256(0x2068c13a5c79346837cdd1723a9f08c457e33fae0745fc139fa7c28160510b57), uint256(0x2905ab35296936d7e657869ab5d64929e745b3e10f4b94b4eb3b91745209cc9e)]);
        vk.gamma_abc = new Pairing.G1Point[](11);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x2a9509663e734d408541f1019ac318d61bb3f12ab380bd04618f2a98a032cbc9), uint256(0x1e2fc937f0c54b09cdbb9503a104e283a6af165e0a88ff6276fa2669ad43971f));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x2540cd8bf46d7b1f0557f36ccd9d61d86f62f3030a07bde9f52e973651dcf0f7), uint256(0x2f453dbe3af01c771c3f16cec633d924a704684a46af400eb1e2fccfc127ab53));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x0a0b6ea59a55db5488fe6eccd9d2307b2400cce9f72c9d4b2d3f27380f12b825), uint256(0x2929a64de20121eb406750f72deaa524ba1cb6df12c22f97475d6609f19d5933));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x0e5f1bdfdb1a90adb7bf4eed358ee3c9fa49a75f1122c57dbe14ce15b968bbfe), uint256(0x002a012888e5d6e162d5b247d40149b1f410e388e7ab92db4743f82c3d460618));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x2b3fc3cf8fac4edb01c7221e709fa64bfee80ff6e19c5c96be8d4eb240d8e24f), uint256(0x0e009dc4ab9fc138d241440b51b49f0a82f38d2a7efc675be823b44a395a0b7b));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x2e7cec4434f4000252540c71c84f0ca1f46343b27b748641148e476111a24b1f), uint256(0x1656acb03941a095c06faa4e7fdba912372f0f65e34c34b3d48385bb5c1a5eb6));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x23f45f6d0134436d57089657b2387ac9d934d316e00119372ddcac831a97154c), uint256(0x22956a20ed5b0ac6bcb7c27ee2d90b5da17bf1f2931a4c85e880f5d2c27d90d9));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x2654fc1c675da0b2920e69652fc6a6ddbbe67de4685306b0f70c4673b3b4923c), uint256(0x1bae9b2c7197254554adb5e8fe1f3e926276dfcaf05efc3c0f5a4fbf2872e44c));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x30327b46bc4df5954acd91084bcbf9ed46554e9f412ed64449b39f10582313b1), uint256(0x1f0d8c86bcccdb7ea1921ce29dd61acd4bdfe946be344f1b24fa268e46c457d1));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x22b5561fcde3d99f8c4b6b3101f8ce7a83462eb2631ffb9488de940781364f75), uint256(0x1a3e659b31ad3a987cb9a447c7189515f687b60edc6a419015e89fdcf8f77df8));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x0923ff47ad24111f2da53d7b378a3cf4c61cde3435f78d81f0f36ef73c3d26c7), uint256(0x1b99ff1a695489e20f98a4e138ddec2907c066443e0707f391e4adcd7a584db8));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[10] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](10);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}



contract BridgeContract{

    using Pairing for *;

    function verifyProof(uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint[10] memory input) internal view returns (bool r){

        Pairing.Proof memory proof;
        proof.a = Pairing.G1Point(a[0], a[1]);
        proof.b = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.c = Pairing.G1Point(c[0], c[1]);

        return Pairing.verifyTx(proof, input);
    }

    bytes32[] taus;

    uint public n;
    uint public nPrime;

    struct TauPrime {
        bytes32 tau;
        bool spent;
    }
    
    TauPrime[] tauPrimes;

    function getTauPrime(uint x) public view returns (TauPrime memory) {
        return tauPrimes[x];
    }

    function addTauPrime(bytes32 new_tau) public {
        tauPrimes.push(TauPrime(new_tau, false));
        nPrime = nPrime + 1;
    }


    function createNewSmartContract(string memory _name, string memory _symbol, string memory _version, uint8 _decimal) internal returns (address) {
        ERC20Token new_token = new ERC20Token(_name, _symbol, _version, _decimal);
        address newContract = address(new_token);
        return newContract;
    }

    mapping (string => address) public native_tokens;
    mapping (string => address) public wrapped_tokens;
    mapping (string => address) public temp_tokens;

    function addNativeToken(uint t, string memory token_sym, address token_address) public {
        native_tokens[token_sym] = token_address;
        token_sym_index[t] = token_sym;
    }

    // function sumStringCharAsciiCodes(string memory inputString) internal pure returns (uint256) {
    //     uint256 unicodeSum = 0;
    //     for (uint256 i = 0; i < bytes(inputString).length; i++) {
    //         unicodeSum += uint256(uint8(bytes(inputString)[i]));
    //     }
    //     return unicodeSum;
    // }

    function splitUint256(uint256 value) internal pure returns (uint128[2] memory) {
        uint128 part1 = uint128(value >> 128);
        uint128 part2 = uint128(value);
        return [part1, part2];
    }


    function checkTauWithInput( 
            uint index, uint256[10] memory input) internal view returns (bool){
        bytes32 current_tau = tauPrimes[index].tau;
        uint128[2] memory parts = splitUint256(uint256(current_tau));
        bool tauChecked = (bytes32(uint256(parts[0])) == bytes32(input[8]) && 
                bytes32(uint256(parts[1])) == bytes32(input[9]));
        return tauChecked;

    }


    function intFromBytes(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x << 128) + y;
    }

    function addressFromInt(uint256 x) internal pure returns (address) {
        return address(uint160(x));
    }

    mapping (uint256 => string) public token_sym_index;

    function addTokenSymIndex(uint256 index, string memory sym) public {
        token_sym_index[index] = sym;
    }

    event newWrappedToken(string token_nam, address token_address);
    event proofCorrect(string message);
    event check(bool);
    event varValue(string name, uint256 value);
    
    function withdraw(uint index, 
        uint256[2] memory proof_A,
        uint256[2][2] memory proof_B,
        uint256[2] memory proof_C,
        uint256[10] memory input) public {
        uint256 v = input[1];//intFromBytes(input[0], input[1]);
        uint256 t = input[3];//intFromBytes(input[2], input[3]);
        emit varValue("t: ", t);
        string memory token_sym = token_sym_index[t];
        // string memory taken_sym = "CAT";
        emit proofCorrect(string.concat("token sym: ", token_sym));
        address A = addressFromInt(intFromBytes(input[4], input[5]));
        TauPrime memory currentTauPrime = tauPrimes[index];
        emit check(checkTauWithInput(index, input));
        emit check(verifyProof(proof_A, proof_B, proof_C, input));
        emit check(!currentTauPrime.spent);

        if (checkTauWithInput(index, input) && verifyProof(proof_A, proof_B, proof_C, input) && !currentTauPrime.spent) {
            emit proofCorrect("the zk proof is valid");
            currentTauPrime.spent = true;
            if (native_tokens[token_sym] != 0x0000000000000000000000000000000000000000) {
                ERC20 native_erc_token = ERC20(native_tokens[token_sym]);
                if (native_erc_token.balanceOf(address(this)) > v) {
                    native_erc_token.transferFrom(address(this), A, v);
                }
                else {
                    string memory token_nam = string.concat(token_sym, "CoinTemp");
                    address new_temp_token_address = createNewSmartContract(token_nam, token_sym, "1", 18);
                    temp_tokens[token_nam] = new_temp_token_address;
                    ERC20 new_temp_token = ERC20(new_temp_token_address);
                    new_temp_token.mint(A, v);
                }
            }
            else if (wrapped_tokens[string.concat(token_sym, "CoinWrap")] != 0x0000000000000000000000000000000000000000) {
                ERC20 wrapped_token = ERC20(wrapped_tokens[string.concat(token_sym, "CoinWrap")]);
                wrapped_token.mint(A, v);
            }
            else {
                string memory token_nam = string.concat(token_sym, "CoinWrap");
                address new_wrapped_token_address = createNewSmartContract(token_nam, token_sym, "1", 18);
                wrapped_tokens[token_nam] = new_wrapped_token_address; 
                ERC20 new_wrapped_token = ERC20(new_wrapped_token_address);
                emit newWrappedToken(token_nam, new_wrapped_token_address);
                new_wrapped_token.mint(A, v);
            }
        }
    }

    function redeemTemp(uint v, string memory token_sym, address A) public {
        string memory temp_token_name = string.concat(token_sym, "coinTemp");
        if (native_tokens[token_sym] != 0x0000000000000000000000000000000000000000 && temp_tokens[temp_token_name] != 0x0000000000000000000000000000000000000000) {
            ERC20 native_erc_token = ERC20(native_tokens[token_sym]);
            uint thisBalance = native_erc_token.balanceOf(address(this));
            ERC20 temp_token = ERC20(temp_tokens[temp_token_name]);
            uint userBalance = temp_token.balanceOf(msg.sender);
            if (thisBalance > v && userBalance > v) {
                native_erc_token.transferFrom(address(this), A, v);
                temp_token.burn(msg.sender, v);
            }

        }
    }

    event NewSourceTau(uint new_n, bytes32 new_tau);

    function sha256Packed(bytes32[2] memory input) internal pure returns (bytes32) {
        bytes memory packedData = abi.encodePacked(input);
        return sha256(packedData);
    }

    function deposit(uint v, uint t, bytes32 chi) public returns (uint) {
        string memory token_sym = token_sym_index[t];
        if (native_tokens[token_sym] != 0x0000000000000000000000000000000000000000) {
            ERC20 native_erc_token = ERC20(native_tokens[token_sym]);
            native_erc_token.transferFrom(msg.sender, address(this), v);
        }
        else if (wrapped_tokens[token_sym] != 0x0000000000000000000000000000000000000000) {
                ERC20 wrapped_token = ERC20(wrapped_tokens[token_sym]);
                wrapped_token.burn(msg.sender, v);
            }
        else if (temp_tokens[token_sym] != 0x0000000000000000000000000000000000000000) {
                ERC20 temp_token = ERC20(temp_tokens[token_sym]);
                temp_token.burn(msg.sender, v);
            }


        bytes32 latest_tau = taus[n-1];
        bytes32 new_tau = sha256Packed([latest_tau, chi]);
        taus.push(new_tau);
        n = n+1;
        emit NewSourceTau(n, new_tau);
        return n;
    }

    constructor() {
        bytes memory data = abi.encodePacked([0x00, 0x05]);
        tauPrimes.push(TauPrime(sha256(data), false));
        taus.push(sha256(data));
        n = 1;
        nPrime = 1;
    }

    function balanceOfIssuedTokens(string memory token_sym) public view returns (uint256 e) {
        if (native_tokens[token_sym] != 0x0000000000000000000000000000000000000000) {
            ERC20 native_erc_token = ERC20(native_tokens[token_sym]);
            return native_erc_token.balanceOf(msg.sender);
        }
        else if (wrapped_tokens[token_sym] != 0x0000000000000000000000000000000000000000) {
                ERC20 wrapped_token = ERC20(wrapped_tokens[token_sym]);
                return wrapped_token.balanceOf(msg.sender);
            }
        else if (temp_tokens[token_sym] != 0x0000000000000000000000000000000000000000) {
                ERC20 temp_token = ERC20(temp_tokens[token_sym]);
                return temp_token.balanceOf(msg.sender);
            }
    }

}