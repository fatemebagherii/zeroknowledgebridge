# zeroknowledgebridge

Bridge.sol includes the bridge smart contract called `BridgeContract`. In order to create a test bridge, this smart contract has to be deployed on two different blockchains, e.g. sepolia and goeli.
Moreover, tokens have to be deployed on both chains. The smart contract `ERC20Token` in the same file can be used for this purpose. 

After deploying the bridge and token smart contracts, we can start the bridging process. 
