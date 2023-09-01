from hashlib import sha256

def calculate_sha256_hash(hex_input):
    
    hash = sha256(bytes.fromhex(hex_input))
    hx = hash.hexdigest()
    print('hx: ', hx)

def main():
    try:
        user_input = input("Enter hex: ")
        calculate_sha256_hash(user_input)
    except ValueError:
        print("Invalid input. Please enter a valid integer.")

if __name__ == "__main__":
    main()