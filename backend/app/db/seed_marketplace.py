"""
Seed script to extract and maintain marketplace products catalog in sync with mobile app.
"""
import re
import json
from pathlib import Path

def extract_products():
    dart_path = Path("/Users/gauravmoriya/12pcropSIH/SIH-2026-fresh/mobile_app/lib/screens/marketplace/marketplace_model.dart")
    if not dart_path.exists():
        print(f"Error: {dart_path} does not exist")
        return []

    content = dart_path.read_text(encoding="utf-8")
    pattern = re.compile(r'ProductItem\((.*?)\),', re.DOTALL)
    items = []

    for block in pattern.findall(content):
        def get_str(field):
            m = re.search(r'\b' + field + r":\s*'([^']*)'", block)
            return m.group(1) if m else ''

        def get_num(field, is_float=True):
            m = re.search(r'\b' + field + r':\s*([0-9.]+)', block)
            if m:
                return float(m.group(1)) if is_float else int(m.group(1))
            return 0.0 if is_float else 0

        def get_bool(field):
            m = re.search(r'\b' + field + r':\s*(true|false)', block)
            return m.group(1) == 'true' if m else False

        def get_list(field):
            m = re.search(r'\b' + field + r':\s*\[(.*?)\]', block, re.DOTALL)
            if m:
                raw_items = m.group(1).split(',')
                cleaned = []
                for x in raw_items:
                    s = x.strip().strip("'").strip('"')
                    if s:
                        cleaned.append(s)
                return cleaned
            return []

        pid = get_str('id')
        if not pid:
            continue

        cat_m = re.search(r'category:\s*ProductCategory\.(\w+)', block)
        category = cat_m.group(1) if cat_m else 'fungicides'

        items.append({
            'id': pid,
            'title': get_str('title'),
            'scientific_name': get_str('scientificName'),
            'brand': get_str('brand'),
            'category': category,
            'pack_size': get_str('packSize'),
            'price': get_num('price', True),
            'mrp': get_num('mrp', True),
            'discount_percent': get_num('discountPercent', True),
            'image_asset': get_str('imageAsset'),
            'is_assured': get_bool('isAssured'),
            'offer_tag': get_str('offerTag') or None,
            'rating': get_num('rating', True) or 4.8,
            'rating_count': get_num('ratingCount', False) or 120,
            'suitable_crops': get_list('suitableCrops'),
            'target_diseases': get_list('targetDiseases'),
            'dosage': get_str('dosage'),
            'application_method': get_str('applicationMethod'),
            'safety_wait_period': get_str('safetyWaitPeriod'),
        })

    json_path = Path("/Users/gauravmoriya/12pcropSIH/SIH-2026-fresh/backend/app/db/marketplace_products.json")
    json_path.write_text(json.dumps(items, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Extracted {len(items)} products and saved to {json_path}")
    return items

if __name__ == "__main__":
    extract_products()
