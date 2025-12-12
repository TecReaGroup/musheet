#!/usr/bin/env python3
"""
SVG to PNG converter for Flutter app icons.
Converts an SVG file to PNG with customizable padding and ensures the icon is centered.
dart run flutter_launcher_icons
"""

import os
import sys

# ============== Configuration ==============
SVG_PATH = "assets/icons/app_icon.svg"
OUTPUT_DIR = "assets/icons/generated_icons"
PADDING_PERCENT = 0
BACKGROUND_COLOR = "#FFFFFF"
# ===========================================

try:
    from PIL import Image
    import cairosvg
except ImportError:
    print("Required packages not installed. Please run:")
    print("  pip install pillow cairosvg")
    sys.exit(1)


def svg_to_png_with_padding(
    svg_path: str,
    output_path: str,
    size: int = 1024,
    padding_percent: float = 10.0,
    background_color: str = "#FFFFFF"
):
    """
    Convert SVG to PNG with the icon centered and padding applied.

    Args:
        svg_path: Path to the input SVG file
        output_path: Path for the output PNG file
        size: Output image size (square, in pixels)
        padding_percent: Padding as percentage of image size (0-50)
        background_color: Background color in hex format (e.g., '#FFFFFF')
    """
    import io

    # Validate padding
    if padding_percent < 0 or padding_percent >= 50:
        raise ValueError("Padding must be between 0 and 50 percent")

    # Calculate the content area size after applying padding
    padding_pixels = int(size * (padding_percent / 100.0))
    content_size = size - (2 * padding_pixels)

    if content_size <= 0:
        raise ValueError("Padding is too large, no space left for content")

    # Convert SVG to PNG at the content size
    png_data = cairosvg.svg2png(
        url=svg_path,
        output_width=content_size,
        output_height=content_size
    )

    # Open the rendered PNG
    icon_image = Image.open(io.BytesIO(png_data)).convert("RGBA")

    # Get the actual bounds of the non-transparent content
    bbox = icon_image.getbbox()
    if bbox:
        # Crop to content bounds
        cropped = icon_image.crop(bbox)

        # Calculate scale to fit within content area while maintaining aspect ratio
        crop_width, crop_height = cropped.size
        scale = min(content_size / crop_width, content_size / crop_height)

        new_width = int(crop_width * scale)
        new_height = int(crop_height * scale)

        # Resize with high quality
        resized = cropped.resize((new_width, new_height), Image.Resampling.LANCZOS)
    else:
        resized = icon_image
        new_width, new_height = icon_image.size

    # Create the final image with the specified size and background color
    bg_color = background_color.lstrip('#')
    if len(bg_color) == 6:
        r, g, b = tuple(int(bg_color[i:i+2], 16) for i in (0, 2, 4))
        final_image = Image.new("RGBA", (size, size), (r, g, b, 255))
    elif len(bg_color) == 8:
        r, g, b, a = tuple(int(bg_color[i:i+2], 16) for i in (0, 2, 4, 6))
        final_image = Image.new("RGBA", (size, size), (r, g, b, a))
    else:
        raise ValueError(f"Invalid background color format: {background_color}")

    # Calculate position to center the icon
    x = (size - new_width) // 2
    y = (size - new_height) // 2

    # Paste the icon onto the final image
    final_image.paste(resized, (x, y), resized)

    # Ensure output directory exists
    output_dir = os.path.dirname(output_path)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    # Save the final image
    final_image.save(output_path, "PNG")
    print(f"Created: {output_path} ({size}x{size}, padding: {padding_percent}%)")

    return final_image


def generate_flutter_icons(svg_path: str, output_dir: str, padding_percent: float = 10.0, background_color: str = "#FFFFFF"):
    """
    Generate all required icon sizes for Flutter app icon.

    Args:
        svg_path: Path to the input SVG file
        output_dir: Directory to save the generated icons
        padding_percent: Padding as percentage of image size
        background_color: Background color in hex format
    """
    os.makedirs(output_dir, exist_ok=True)

    # Standard sizes needed for Flutter app icons
    sizes = {
        "app_icon.png": 1024,           # Main icon (for flutter_launcher_icons)
        "app_icon_512.png": 512,        # Large icon
        "app_icon_192.png": 192,        # Android adaptive icon
        "app_icon_144.png": 144,
        "app_icon_96.png": 96,
        "app_icon_72.png": 72,
        "app_icon_48.png": 48,
        "app_icon_36.png": 36,
    }

    for filename, size in sizes.items():
        output_path = os.path.join(output_dir, filename)
        svg_to_png_with_padding(
            svg_path=svg_path,
            output_path=output_path,
            size=size,
            padding_percent=padding_percent,
            background_color=background_color
        )

    print(f"\nAll icons generated in: {output_dir}")


def main():
    # Get the project root directory (parent of scripts folder)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)

    # Build full paths
    svg_full_path = os.path.join(project_root, SVG_PATH)
    output_full_dir = os.path.join(project_root, OUTPUT_DIR)

    # Validate input file exists
    if not os.path.exists(svg_full_path):
        print(f"Error: SVG file not found: {svg_full_path}")
        sys.exit(1)

    print(f"SVG: {svg_full_path}")
    print(f"Output: {output_full_dir}")
    print(f"Padding: {PADDING_PERCENT}%")
    print(f"Background: {BACKGROUND_COLOR}")
    print()

    generate_flutter_icons(svg_full_path, output_full_dir, PADDING_PERCENT, BACKGROUND_COLOR)


if __name__ == "__main__":
    main()
