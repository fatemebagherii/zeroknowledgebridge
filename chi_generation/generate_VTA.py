import sys
import os

def generate_random_int256():
    random_bytes = os.urandom(32)
    random_int = int.from_bytes(random_bytes, byteorder='big', signed=False)
    random_int &= (1 << 256) - 1
    return random_int

def split_uint256(value):
    mask = (1 << 128) - 1
    part1 = value >> 128
    part2 = value & mask
    return part1, part2

def main():
    if len(sys.argv) != 4:
        print("Usage: python generate_VTA.py 'token_symbol' 'value' 'address'")
        return

    token_symbol = int(sys.argv[1])
    value = int(sys.argv[2])
    address = sys.argv[3]
    address_decimal = int(address, 16)

    k = generate_random_int256()
    print("k: ", split_uint256(k))
    print("t: ", split_uint256(token_symbol))
    print("v: ", split_uint256(value))
    print("A: ", split_uint256(address_decimal))


if __name__ == "__main__":
    main()
