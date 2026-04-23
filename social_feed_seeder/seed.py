import os
import io
from PIL import Image
from supabase import create_client, Client

# ─────────────────────────────────────────
#  PASTE YOUR KEYS HERE
# ─────────────────────────────────────────
SUPABASE_URL = "https://beanmlpojuaaxkgahnsr.supabase.co"   # ← your project URL
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlYW5tbHBvanVhYXhrZ2FobnNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2MTA2NjYsImV4cCI6MjA5MjE4NjY2Nn0.tFkU_hUtuUpQldDTgikTQs1F1Vw3g5Ay9BHvghqUAiM"   # ← service_role key

BUCKET_NAME = "media"
INPUT_DIR = "input_images"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


def upload_to_storage(path, file_bytes, content_type="image/webp"):
    try:
        supabase.storage.from_(BUCKET_NAME).upload(
            path,
            file_bytes,
            {"content-type": content_type}
        )
        print(f"  ✓ Uploaded: {path}")
    except Exception as e:
        print(f"  ⚠ Skipping {path} - already exists or error: {e}")


def process_and_upload():
    # Check input folder exists
    if not os.path.exists(INPUT_DIR):
        print(f"ERROR: Create a folder named '{INPUT_DIR}' and add images!")
        return

    # Get list of images
    images = [
        f for f in os.listdir(INPUT_DIR)
        if f.lower().endswith(('.png', '.jpg', '.jpeg'))
    ]

    if len(images) == 0:
        print(f"ERROR: No images found in '{INPUT_DIR}' folder!")
        print("Add some .jpg or .png images and try again.")
        return

    print(f"Found {len(images)} images to process...\n")

    for filename in images:
        filepath = os.path.join(INPUT_DIR, filename)
        base_name = os.path.splitext(filename)[0]

        print(f"Processing: {filename}")

        try:
            with Image.open(filepath) as img:
                # Convert to RGB if needed (handles PNG with alpha)
                if img.mode in ('RGBA', 'P', 'LA'):
                    img = img.convert('RGB')

                original_format = "jpeg"

                # ── Tier 1: Thumbnail (300x300) ──────────────
                thumb = img.copy()
                thumb.thumbnail((300, 300), Image.Resampling.LANCZOS)
                thumb_bytes = io.BytesIO()
                thumb.save(thumb_bytes, format="webp", quality=70)
                thumb_path = f"{base_name}_thumb.webp"

                # ── Tier 2: Mobile (1080x1080) ────────────────
                mobile = img.copy()
                mobile.thumbnail((1080, 1080), Image.Resampling.LANCZOS)
                mobile_bytes = io.BytesIO()
                mobile.save(mobile_bytes, format="webp", quality=80)
                mobile_path = f"{base_name}_mobile.webp"

                # ── Tier 3: Raw (original size) ───────────────
                raw_bytes = io.BytesIO()
                img.save(raw_bytes, format="jpeg", quality=95)
                raw_path = f"{base_name}_raw.jpg"

            # ── Upload all 3 tiers ────────────────────────────
            upload_to_storage(thumb_path,  thumb_bytes.getvalue(),  "image/webp")
            upload_to_storage(mobile_path, mobile_bytes.getvalue(), "image/webp")
            upload_to_storage(raw_path,    raw_bytes.getvalue(),    "image/jpeg")

            # ── Get public URLs ───────────────────────────────
            thumb_url  = supabase.storage.from_(BUCKET_NAME).get_public_url(thumb_path)
            mobile_url = supabase.storage.from_(BUCKET_NAME).get_public_url(mobile_path)
            raw_url    = supabase.storage.from_(BUCKET_NAME).get_public_url(raw_path)

            # ── Insert into database ──────────────────────────
            result = supabase.table("posts").insert({
                "media_thumb_url":  thumb_url,
                "media_mobile_url": mobile_url,
                "media_raw_url":    raw_url,
                "like_count":       0,
            }).execute()

            print(f"  ✓ Database row inserted")
            print(f"  ✓ Thumb  : {thumb_url}")
            print(f"  ✓ Mobile : {mobile_url}")
            print(f"  ✓ Raw    : {raw_url}")
            print(f"  ✅ Done: {filename}\n")

        except Exception as e:
            print(f"  ❌ Failed to process {filename}: {e}\n")


if __name__ == "__main__":
    print("=" * 50)
    print("  Social Feed Image Seeder")
    print("=" * 50 + "\n")
    process_and_upload()
    print("=" * 50)
    print("  Pipeline Complete!")
    print("=" * 50)