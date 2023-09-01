import sys


def main():
    if len(sys.argv) != 3:
        print("Usage: python convert_128bit_ints_to_hash.py 'left_int' 'right_int'")
        return

    int_left = int(sys.argv[1])
    int_right = int(sys.argv[2])
    result = (int_left << 128) + int_right
    print(hex(result))


if __name__ == "__main__":
    main()