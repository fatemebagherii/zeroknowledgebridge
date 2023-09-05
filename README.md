# zeroknowledgebridge

`Bridge.sol` includes the bridge smart contract called `BridgeContract`. In order to create a test bridge, this smart contract has to be deployed on two different blockchains, e.g. sepolia and goerli.
Moreover, tokens have to be deployed on both chains. The smart contract `ERC20Token` in the same file can be used for this purpose. 
We can use Remix to do the compilation and deployment. Please copy the `Bridge.sol` code into a Remix page in two different browser windows. Deploy the bridge contract on two different chains. You can choose `Remix VM - Goerli fork` in one browser window and `Remix VM - Sepolia fork` in the other. Also, please deploy some tokens using the `ERC20Token` smart contract and insert them into the bridge using `addNativeToken` function in the bridge contract. 

After deploying the bridge and token smart contracts, we can start the bridging process. Using the `deposit` function, we can lock funds in one chain, and using the `withdraw` function, we can unlock them on the other chain. In this example, the relay entity's duty can be performed manually, by copying the new $\tau$ value from one bridge contract to the one on the other chain, using the `addTauPrime` function on the second chain's bridge contract. 

Before locking funds, in order to generate the proper inputs to the `deposit` function, we implement some calculations in Python and Zokrates. Follow the steps below:

```
python ./chi_generation/generate_VTA.py 'token_symbol' 'value' 'address'
```
For example, 
```
python3 ./chi_generation/generate_VTA.py 1 3 0x5B38Da6a701c568545dCfcB03FcB875f56
```
whose result looks like:
```
k:  (62215354699795608743855020188736731200, 217386241686911651285686821685923559305)
t:  (0, 1)
v:  (0, 3)
A:  (1530452586, 149020674686142704025204189025701649860)
```
where `k` is a random secret, `t` is the name and `v` is the value of the token, and `A` is the address to which the funds will be sent on the second chain. The values are broken into 128-bit-long chunks because that is the format accepted by Zokrates.

After this step, we need to generate the $\chi$ value. For this, we use `chi_generation/getChi.zok`. Run the following steps:
```
cd chi_generation
zokrates compile -i getChi.zok
zokrates compute-witness -a 62215354699795608743855020188736731200 217386241686911651285686821685923559305 0 3 0 1 1530452586 149020674686142704025204189025701649860 --verbose

```
the result will look like this:
```
Computing witness...

Witness: 
["21591113692954993657853886667655461095","306288164242889760895667704211559176772"]

Witness file written to 'witness'
```
The witness value returned by this command is in fact the $\chi$ that we need to feed into `deposit` function. We first need to convert these two 128-bit-long integers into a proper hash value. We use `chi_generation/convert_128bit_ints_to_hash.py` to do this conversion. 
```
python3 convert_128bit_ints_to_hash.py 21591113692954993657853886667655461095 306288164242889760895667704211559176772
```
which gives us the result in the form of a 32-byte-long hash value:
```
0x103e4c17e180933cc24e1bf4ec4fb8e7e66cf4680ccfe67f2db0a02ce3a05a44
```
Now, we can call the `deposit` function. So, we go back to Remix and call the `deposit` function with inputs `v`, `t`, and $\chi$. 
