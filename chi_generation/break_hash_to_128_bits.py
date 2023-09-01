import sys

def split_uint256(value):
    mask = (1 << 128) - 1
    part1 = value >> 128
    part2 = value & mask
    return part1, part2

def main():
    if len(sys.argv) != 2:
        print("Usage: python break_hash_to_128_bits.py 'hash_value'")
        return

    hash_value = int(sys.argv[1], 16)
    k1, k2 = split_uint256(hash_value)
    print(hash_value)
    print(k1, k2)


if __name__ == "__main__":
    main()