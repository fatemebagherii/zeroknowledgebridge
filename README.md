# zeroknowledgebridge

`Bridge.sol` includes the bridge smart contract called `BridgeContract`. In order to create a test bridge, this smart contract has to be deployed on two different blockchains, e.g. sepolia and goeli.
Moreover, tokens have to be deployed on both chains. The smart contract `ERC20Token` in the same file can be used for this purpose. 

After deploying the bridge and token smart contracts, we can start the bridging process. Using the `deposit` function, we can lock funds in one chain and using the `withdraw` function, we can unlock them on the other chain. In this example, the relay entity's duty can be performed manually, by copying the new `\tua` value from one bridge contract to the one on the other chain.
