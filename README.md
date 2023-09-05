# Zero Knowledge Bridge

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

By doing this, a new $\tau$ value will be added to the `taus` array and an event is thrown containing this new $\tau$. Now, it is time for the relayer to catch this event and relay this new value to the destination chain. In this case, you are the relayer. From the log events on the first chain, find the new $\tau$ value. Then, go to the second chain and using `addTauPrime` function, transfer this value to the second chain. Now, the bridge on the second chain is ready to redeem the transferred funds. To this end, we need to call the `withdraw` function. Inputs to this function include the `A`, `B`, and `C` values that constitute the proof in a `Groth16` zero-knowledge protocol plus public values including `v`, `t`, `A`, $\tau[n]$, and $\tau[n-1]$ where `n` is the index in the $\tau$ array from which we are redeeming. 

To generate the proof, we use the `proof_generation/getProof.zok` file. The inputs required to generate a proof include `k`, `v`, `t`, `A`, $\tau[n]$, and $\tau[n-1]$. First, we need to make sure we have these values in the correct format supported by Zokrates which is chunks of 128-bit-long integers. We get $\tau[n]$ and $\tau[n-1]$ values from the destination bridge smart contract. In this case, since we have only locked once, `n` is equal to `1`. So, we call `getTauPrime` with input `0` and `1` and get the following values:
```
0xc6481e22c5ff4164af680b8cfaa5e8ed3120eeff89c4f307c4a6faaae059ce10
```
and 
```
0x0c21360b1b5cecf60b9660e7b65026f972be093383692e94a04b7ced4571d638
```
Then, using `chi_generation/break_hash_to_128_bits.py`, we break them into 128-bit-long integers:
```
python3 break_hash_to_128_bits.py 0xc6481e22c5ff4164af680b8cfaa5e8ed3120eeff89c4f307c4a6faaae059ce10
263561599766550617289250058199814760685 65303172752238645975888084098459749904
```
and 
```
python3 break_hash_to_128_bits.py 0x0c21360b1b5cecf60b9660e7b65026f972be093383692e94a04b7ced4571d638
16123177875847460091502621220479706873 152518714545594441321152369977334027832
```
Now, using these values, we can generate the proof:
```
cd proof_generation
zokrates compile -i getProof.zok
zokrates setup
zokrates compute-witness -a 62215354699795608743855020188736731200 217386241686911651285686821685923559305 0 3 0 1 1530452586 149020674686142704025204189025701649860 263561599766550617289250058199814760685 65303172752238645975888084098459749904 16123177875847460091502621220479706873 152518714545594441321152369977334027832 --verbose
zokrates generate-proof
```
After these steps, a new file `proof.json` containing the proof is generated. The main fields in this JSON file include `a`, `b`, `c`, and `input`. We copy them into the respective inputs in the withdraw function along with the proper index of $\tau^{\prime}$ from which we want to withdraw. This function checks the correctness of the proof and if everything is correct and there is no fraud intended, the funds will be redeemed. 
