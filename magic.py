import sys
from PIL import Image

def pad_opaque_areas(image_path):
    # Open the image
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size
    pixels = img.load()

    # Create a copy to modify
    padded_img = img.copy()
    padded_pixels = padded_img.load()

    # Directions for neighboring pixels (8-way connectivity)
    neighbors = [
        (-1, -1), (0, -1), (1, -1),  # Top-left, Top, Top-right
        (-1,  0),          (1,  0),  # Left,       Right
        (-1,  1), (0,  1), (1,  1),  # Bottom-left, Bottom, Bottom-right
    ]

    # Iterate over all pixels
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a == 0:  # If transparent
                # Check neighbors for opaque pixels
                for dx, dy in neighbors:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < width and 0 <= ny < height:  # Ensure within bounds
                        nr, ng, nb, na = pixels[nx, ny]
                        if na > 0:  # Opaque neighbor
                            padded_pixels[x, y] = (nr, ng, nb, 255)  # Use neighbor's color
                            break

    # Overwrite the input file
    padded_img.save(image_path, "PNG")
    print(f"Image updated and saved to {image_path}")

if __name__ == "__main__":
    # Ensure the script is called with an argument
    if len(sys.argv) != 2:
        print("Usage: python script.py <image_path>")
        sys.exit(1)

    # Get the image path from the command line
    input_file = sys.argv[1]

    # Process the image
    pad_opaque_areas(input_file)
