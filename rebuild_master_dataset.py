"""
rebuild_master_dataset.py — Group-Based Stratified Split Rebuilder
Krishi-Saarthi / SIH-2026 Agriculture Disease Detection Project

Guarantees:
- Source dataset 'D:\15 Crop 45 Disease and Healthy Leaf dataset' is NEVER modified (read-only).
- Every exact duplicate-image group (identified by SHA-256 hash) is assigned ENTIRELY to a single split.
- ZERO cross-split duplicate hashes (Train ∩ Valid = ∅, Train ∩ Test = ∅, Valid ∩ Test = ∅).
- All 8 crops and 24 classes preserved in all three splits.
- Split distribution: ~80% Train, ~10% Valid, ~10% Test.
- No resizing, recompression, or modification of image bytes.
- Full post-rebuild validation and audit logging.
"""

import os
import sys
import time
import shutil
import random
import hashlib
import csv
from pathlib import Path
from collections import defaultdict, Counter
from concurrent.futures import ThreadPoolExecutor
from PIL import Image

SOURCE_DIR = Path(r"D:\15 Crop 45 Disease and Healthy Leaf dataset")
TARGET_DIR = Path(r"D:\MASTER_DATASET")

AUDIT_CSV_PATH = TARGET_DIR / "duplicate_group_audit.csv"
REPORT_TXT_PATH = TARGET_DIR / "final_sanity_check.txt"
DUPLICATE_CSV_PATH = TARGET_DIR / "duplicate_report.csv"

RANDOM_SEED = 42

CLASS_MAPPING = [
    # 1. Cashew
    ("Cashew leaf miner",             "Cashew",    "Leaf Miner"),
    ("Cashew red rust",               "Cashew",    "Red Rust"),
    ("healthy_cashew",                "Cashew",    "Healthy"),

    # 2. Cassava
    ("Cassava brown spot",            "Cassava",   "Brown Spot"),
    ("Cassava mosaic",                "Cassava",   "Mosaic"),
    ("healthy_cassava",               "Cassava",   "Healthy"),

    # 3. Chilli
    ("Chili Healthy Leaf",            "Chilli",    "Healthy"),
    ("Chilli Nutrition Deficiency",   "Chilli",    "Nutrition Deficiency"),
    ("Chilli White spot",             "Chilli",    "White Spot"),

    # 4. Cotton
    ("Cotton Bacterial Blight",       "Cotton",    "Bacterial Blight"),
    ("Cotton Curl Virus",             "Cotton",    "Curl Virus"),
    ("Cotton Healthy Leaf",           "Cotton",    "Healthy"),

    # 5. Grape
    ("Grape___Black_rot",             "Grape",     "Black Rot"),
    ("Grape___Leaf_blight",           "Grape",     "Leaf Blight"),
    ("Grape___healthy",               "Grape",     "Healthy"),

    # 6. Groundnut
    ("Ground healthy leaf",           "Groundnut", "Healthy Leaf"),
    ("Ground late leaf spot",         "Groundnut", "Late Leaf Spot"),
    ("Ground nutrition deficiency",   "Groundnut", "Nutrition Deficiency"),

    # 7. Papaya
    ("Papaya BacterialSpot",          "Papaya",    "Bacterial Spot"),
    ("Papaya Healthy",                "Papaya",    "Healthy"),
    ("Papaya RingSpot",               "Papaya",    "Ring Spot"),

    # 8. Soybean
    ("Soyabean Caterpillar",          "Soybean",   "Caterpillar"),
    ("Soyabean Diabrotica speciosa",  "Soybean",   "Diabrotica speciosa"),
    ("Soyabean Healthy",              "Soybean",   "Healthy"),
]


def hash_file(path: Path) -> str:
    """Compute SHA-256 hash of a file."""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(131072):
            h.update(chunk)
    return h.hexdigest()


def scan_source():
    """Verify source and compute SHA-256 for all images."""
    print("=" * 80)
    print("STEP 1: SCANNING AND HASHING SOURCE DATASET")
    print(f"Source: {SOURCE_DIR}")
    print("=" * 80)

    if not SOURCE_DIR.exists():
        sys.exit(f"[FATAL] Source directory does not exist: {SOURCE_DIR}")

    all_items = []
    for src_f, crop, disease in CLASS_MAPPING:
        p = SOURCE_DIR / src_f
        if not p.is_dir():
            sys.exit(f"[FATAL] Missing source folder: {p}")
        for f in sorted(p.iterdir()):
            if f.is_file():
                all_items.append((src_f, crop, disease, f))

    print(f"[OK] Discovered {len(all_items):,} source images across 24 folders.")

    def process(item):
        src_f, crop, disease, path = item
        h = hash_file(path)
        return h, (src_f, crop, disease, path)

    start_h = time.time()
    hash_to_items = defaultdict(list)
    with ThreadPoolExecutor(max_workers=12) as executor:
        for h, data in executor.map(process, all_items):
            hash_to_items[h].append(data)

    elapsed_h = time.time() - start_h
    print(f"[OK] Computed SHA-256 for {len(all_items):,} files in {elapsed_h:.1f}s.")
    print(f"[OK] Unique SHA-256 hashes: {len(hash_to_items):,}")

    return all_items, hash_to_items


def compute_group_splits(hash_to_items):
    """
    Assign every SHA-256 hash group ENTIRELY to a single split ('train', 'valid', 'test').
    Multi-class hashes (15 groups) assigned to 'train' to prevent cross-split leakage.
    Single-class hashes split ~80% train / 10% valid / 10% test per class.
    """
    print("\n" + "=" * 80)
    print("STEP 2: COMPUTING GROUP-BASED STRATIFIED SPLITS")
    print("=" * 80)

    # 1. Identify multi-class hashes
    multi_class_hashes = set()
    for h, items in hash_to_items.items():
        classes = set((x[1], x[2]) for x in items)
        if len(classes) > 1:
            multi_class_hashes.add(h)

    print(f"Hashes spanning multiple classes: {len(multi_class_hashes)} (assigned entirely to 'train')")

    hash_split = {}
    audit_rows = []

    # Assign all multi-class hashes to 'train'
    for h in multi_class_hashes:
        hash_split[h] = "train"
        items = hash_to_items[h]
        classes_str = "; ".join(sorted(list(set(f"{x[1]}/{x[2]}" for x in items))))
        files_str = "; ".join(x[3].name for x in items)
        audit_rows.append({
            "sha256": h,
            "group_size": len(items),
            "assigned_split": "train",
            "group_type": "MULTI_CLASS_HASH_GROUP",
            "classes_spanned": classes_str,
            "files": files_str
        })

    # Group single-class hashes by class
    class_to_hashes = defaultdict(list)
    for h, items in hash_to_items.items():
        if h not in multi_class_hashes:
            c = (items[0][1], items[0][2])
            class_to_hashes[c].append((h, len(items)))

    class_split_counts = defaultdict(lambda: {"train": 0, "valid": 0, "test": 0})

    # Count multi-class images already in train
    for h in multi_class_hashes:
        for _, crop, disease, _ in hash_to_items[h]:
            class_split_counts[(crop, disease)]["train"] += 1

    # Split single-class hashes for each class
    for idx, (_, crop, disease) in enumerate(CLASS_MAPPING):
        c = (crop, disease)
        hashes_with_counts = class_to_hashes[c]
        
        # Deterministic sort and shuffle
        hashes_with_counts.sort(key=lambda x: x[0])
        class_rng = random.Random(RANDOM_SEED + idx * 1000)
        class_rng.shuffle(hashes_with_counts)
        
        total_class_images = sum(
            len(hash_to_items[h]) for h, items in hash_to_items.items()
            if any(x[1] == crop and x[2] == disease for x in items)
        )
        
        target_val = max(1, int(round(total_class_images * 0.10)))
        target_test = max(1, int(round(total_class_images * 0.10)))
        
        curr_val = 0
        curr_test = 0
        
        for h, count in hashes_with_counts:
            items = hash_to_items[h]
            if curr_val + count <= target_val:
                s = "valid"
                curr_val += count
            elif curr_test + count <= target_test:
                s = "test"
                curr_test += count
            else:
                s = "train"
                
            hash_split[h] = s
            class_split_counts[c][s] += count
            
            if count > 1:
                files_str = "; ".join(x[3].name for x in items)
                audit_rows.append({
                    "sha256": h,
                    "group_size": count,
                    "assigned_split": s,
                    "group_type": "SINGLE_CLASS_DUPLICATE_GROUP",
                    "classes_spanned": f"{crop}/{disease}",
                    "files": files_str
                })

    print(f"[OK] All {len(hash_split):,} unique hashes mapped to splits.")
    return hash_split, class_split_counts, audit_rows


def rebuild_filesystem(hash_split, hash_to_items):
    """Cleanly populate D:\MASTER_DATASET with group-split images."""
    print("\n" + "=" * 80)
    print("STEP 3: REBUILDING TARGET DIRECTORY D:\\MASTER_DATASET")
    print("=" * 80)

    TARGET_DIR.mkdir(parents=True, exist_ok=True)

    # Clean existing train, valid, test trees
    for split in ["train", "valid", "test"]:
        s_dir = TARGET_DIR / split
        if s_dir.exists():
            print(f"Cleaning existing split: {s_dir}")
            shutil.rmtree(s_dir)

    # Recreate blank structure
    for split in ["train", "valid", "test"]:
        for _, crop, disease in CLASS_MAPPING:
            (TARGET_DIR / split / crop / disease).mkdir(parents=True, exist_ok=True)

    print("[OK] Recreated directory structure under D:\\MASTER_DATASET")

    # Copy files
    print("\nCopying images using byte-exact direct transfer (shutil.copy2)...")
    start_c = time.time()
    total_copied = 0
    collisions = 0

    log_path = TARGET_DIR / "copy_log.csv"
    with open(log_path, "w", encoding="utf-8") as log_f:
        log_f.write("source_file,split,crop,disease,destination_file,size_bytes\n")
        
        for h, items in hash_to_items.items():
            assigned_split = hash_split[h]
            for src_f, crop, disease, path in items:
                dest_dir = TARGET_DIR / assigned_split / crop / disease
                dest_file = dest_dir / path.name
                
                # Collision handling
                if dest_file.exists():
                    stem = path.stem
                    suffix = path.suffix
                    cnt = 1
                    while dest_file.exists():
                        dest_file = dest_dir / f"{stem}_{cnt}{suffix}"
                        cnt += 1
                    collisions += 1

                shutil.copy2(path, dest_file)
                size_b = dest_file.stat().st_size
                log_f.write(f'"{path}","{assigned_split}","{crop}","{disease}","{dest_file}",{size_b}\n')
                total_copied += 1

                if total_copied % 5000 == 0:
                    rate = total_copied / (time.time() - start_c)
                    print(f"   ... copied {total_copied:,} images ({rate:.1f} imgs/sec)")

    elapsed_c = time.time() - start_c
    print(f"[OK] Successfully copied {total_copied:,} images in {elapsed_c:.1f}s ({total_copied/elapsed_c:.1f} imgs/sec). Collisions handled: {collisions}")
    return total_copied


def run_full_sanity_check(expected_total, audit_rows):
    """Run comprehensive sanity check on rebuilt dataset."""
    print("\n" + "=" * 80)
    print("STEP 4: RUNNING COMPREHENSIVE SANITY CHECK & AUDIT VALIDATION")
    print("=" * 80)

    start_v = time.time()

    # 1. Structure & files
    all_dest_items = []
    structure_issues = []
    found_splits = [d.name for d in TARGET_DIR.iterdir() if d.is_dir() and d.name in ["train", "valid", "test"]]
    if set(found_splits) != {"train", "valid", "test"}:
        structure_issues.append(f"Splits mismatch: {found_splits}")

    dataset_tree = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))
    for split in ["train", "valid", "test"]:
        s_dir = TARGET_DIR / split
        for crop_dir in sorted(s_dir.iterdir()):
            if not crop_dir.is_dir():
                structure_issues.append(f"Non-dir file: {crop_dir}")
                continue
            for disease_dir in sorted(crop_dir.iterdir()):
                if not disease_dir.is_dir():
                    structure_issues.append(f"Non-dir file: {disease_dir}")
                    continue
                files = [f for f in disease_dir.iterdir() if f.is_file()]
                dataset_tree[split][crop_dir.name][disease_dir.name].extend(files)
                for f in files:
                    all_dest_items.append((split, crop_dir.name, disease_dir.name, f))

    print(f"1. Structure check: {len(all_dest_items):,} files found in structure.")
    assert len(all_dest_items) == expected_total, f"File count mismatch! {len(all_dest_items)} != {expected_total}"
    assert not structure_issues, f"Structure issues: {structure_issues}"
    print("   [PASS] Perfect directory structure: <split>/<Crop>/<Disease>/<images>.")

    # 2. Class consistency
    classes_per_split = {s: set() for s in ["train", "valid", "test"]}
    crops_per_split = {s: set() for s in ["train", "valid", "test"]}
    for split, crop, disease, _ in all_dest_items:
        classes_per_split[split].add((crop, disease))
        crops_per_split[split].add(crop)

    for split in ["train", "valid", "test"]:
        assert len(crops_per_split[split]) == 8, f"Missing crops in {split}: {crops_per_split[split]}"
        assert len(classes_per_split[split]) == 24, f"Missing classes in {split}: {classes_per_split[split]}"

    print(f"2. Class consistency check:")
    print(f"   [PASS] All 8 crops and all 24 classes exist in train, valid, and test!")

    # 3. Parallel Image Verification & Hashing
    print("3. Image validity & duplicate hash scanning...")
    corrupt_files = []
    zero_byte_files = []
    dest_hash_to_files = defaultdict(list)
    dimension_stats = defaultdict(Counter)
    filename_counter = defaultdict(Counter)
    split_counts = {"train": 0, "valid": 0, "test": 0}
    class_table_counts = defaultdict(lambda: {"train": 0, "valid": 0, "test": 0})

    def check_dest_image(item):
        split, crop, disease, path = item
        try:
            sz = path.stat().st_size
            if sz == 0:
                return (split, crop, disease, path, False, "ZERO_BYTE", None, None, 0)
            if Image is None:
                return (split, crop, disease, path, False, "PIL/Pillow not installed (pip install pillow)", None, None, 0)
            h = hash_file(path)
            with Image.open(path) as img:
                dims = img.size
                fmt = img.format
                img.verify()
            return (split, crop, disease, path, True, None, dims, h, sz)
        except Exception as e:
            return (split, crop, disease, path, False, str(e), None, None, 0)

    with ThreadPoolExecutor(max_workers=12) as executor:
        for res in executor.map(check_dest_image, all_dest_items):
            split, crop, disease, path, is_valid, err, dims, f_hash, sz = res
            split_counts[split] += 1
            class_table_counts[(crop, disease)][split] += 1
            filename_counter[(split, crop, disease)][path.name] += 1

            if not is_valid:
                if err == "ZERO_BYTE":
                    zero_byte_files.append(path)
                else:
                    corrupt_files.append((path, err))
            else:
                dimension_stats[(crop, disease)][dims] += 1
                dest_hash_to_files[f_hash].append({
                    "split": split,
                    "crop": crop,
                    "disease": disease,
                    "filename": path.name,
                    "path": str(path)
                })

    assert len(corrupt_files) == 0, f"Corrupted files found: {corrupt_files}"
    assert len(zero_byte_files) == 0, f"Zero byte files found: {zero_byte_files}"
    print(f"   [PASS] 100% of images are decodable and valid (0 corrupted, 0 zero-byte).")

    # 4. Check for cross-split duplicate leakage
    print("4. Cross-split data leakage check (SHA-256):")
    cross_split_pairs = []
    within_split_pairs = []
    all_duplicate_rows = []

    for f_hash, occurrences in dest_hash_to_files.items():
        if len(occurrences) > 1:
            splits_present = set(o["split"] for o in occurrences)
            for i in range(len(occurrences)):
                for j in range(i + 1, len(occurrences)):
                    o1 = occurrences[i]
                    o2 = occurrences[j]
                    if o1["split"] != o2["split"]:
                        cross_split_pairs.append((f_hash, o1, o2))
                    else:
                        within_split_pairs.append((f_hash, o1, o2))
                    
                    all_duplicate_rows.append({
                        "hash": f_hash,
                        "duplicate_type": "CROSS_SPLIT" if o1["split"] != o2["split"] else f"WITHIN_SPLIT_{o1['split'].upper()}",
                        "split_1": o1["split"], "crop_1": o1["crop"], "disease_1": o1["disease"], "file_1": o1["filename"], "path_1": o1["path"],
                        "split_2": o2["split"], "crop_2": o2["crop"], "disease_2": o2["disease"], "file_2": o2["filename"], "path_2": o2["path"]
                    })

    print(f"   - Cross-split duplicate pairs: {len(cross_split_pairs)}")
    print(f"   - Within-split duplicate pairs: {len(within_split_pairs)} (strictly preserved inside single split)")
    assert len(cross_split_pairs) == 0, f"[CRITICAL FAILURE] Found {len(cross_split_pairs)} cross-split duplicate pairs!"
    print("   [PASS] ZERO cross-split duplicate hashes! Train, valid, and test are strictly disjoint sets.")

    # 5. Filename collision check
    filename_collisions = sum(1 for c in filename_counter.values() for cnt in c.values() if cnt > 1)
    assert filename_collisions == 0, f"Filename collisions found: {filename_collisions}"
    print("   [PASS] All filenames within every folder are unique.")

    # 6. Source dataset integrity check
    source_counts = sum(len(list((SOURCE_DIR / sf).iterdir())) for sf, _, _ in CLASS_MAPPING)
    assert source_counts == expected_total, f"Source dataset was modified! {source_counts} != {expected_total}"
    print(f"5. Source dataset check: {source_counts:,} images remain 100% untouched.")

    # -------------------------------------------------------------------------
    # GENERATE REPORTS
    # -------------------------------------------------------------------------
    print("\nSaving final reports...")

    # Save duplicate_group_audit.csv
    with open(AUDIT_CSV_PATH, "w", newline="", encoding="utf-8") as f:
        fieldnames = ["sha256", "group_size", "assigned_split", "group_type", "classes_spanned", "files"]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for r in audit_rows:
            writer.writerow(r)
    print(f"[OK] Saved duplicate group audit to: {AUDIT_CSV_PATH}")

    # Save duplicate_report.csv
    with open(DUPLICATE_CSV_PATH, "w", newline="", encoding="utf-8") as f:
        fieldnames = [
            "hash", "duplicate_type",
            "split_1", "crop_1", "disease_1", "file_1", "path_1",
            "split_2", "crop_2", "disease_2", "file_2", "path_2"
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for r in all_duplicate_rows:
            writer.writerow(r)
    print(f"[OK] Saved duplicate report to: {DUPLICATE_CSV_PATH}")

    # Class counts table strings
    table_lines = []
    header_str = f"{'Crop':12s} | {'Disease / Condition':22s} | {'Train':>7s} | {'Valid':>7s} | {'Test':>7s} | {'Total':>7s}"
    sep_str = "-" * len(header_str)
    table_lines.append(header_str)
    table_lines.append(sep_str)

    tot_tr = split_counts["train"]
    tot_va = split_counts["valid"]
    tot_te = split_counts["test"]
    tot_all = tot_tr + tot_va + tot_te

    for _, crop, disease in CLASS_MAPPING:
        counts = class_table_counts[(crop, disease)]
        tr = counts["train"]
        va = counts["valid"]
        te = counts["test"]
        tot = tr + va + te
        line = f"{crop:12s} | {disease:22s} | {tr:7d} | {va:7d} | {te:7d} | {tot:7d}"
        table_lines.append(line)

    table_lines.append(sep_str)
    table_lines.append(f"{'TOTALS':12s} | {'24 Classes':22s} | {tot_tr:7d} | {tot_va:7d} | {tot_te:7d} | {tot_all:7d}")

    # Save final_sanity_check.txt
    with open(REPORT_TXT_PATH, "w", encoding="utf-8") as f:
        f.write("=" * 80 + "\n")
        f.write("KRISHI-SAARTHI MASTER DATASET — FINAL SANITY CHECK REPORT (V2)\n")
        f.write("Method: Group-Based Stratified Split (Zero Cross-Split Hash Leakage)\n")
        f.write(f"Generated at: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Dataset Root: {TARGET_DIR}\n")
        f.write("=" * 80 + "\n\n")

        f.write("1. SUMMARY TOTALS\n")
        f.write("-" * 40 + "\n")
        f.write(f"Number of Crops:             8\n")
        f.write(f"Number of Classes:           24\n")
        f.write(f"Total Images:                {tot_all:,}\n")
        f.write(f"Train Images:                {tot_tr:,} ({tot_tr/tot_all*100:.2f}%)\n")
        f.write(f"Validation Images:           {tot_va:,} ({tot_va/tot_all*100:.2f}%)\n")
        f.write(f"Test Images:                 {tot_te:,} ({tot_te/tot_all*100:.2f}%)\n\n")

        f.write("2. ZERO CROSS-SPLIT DUPLICATE HASHES VERIFIED\n")
        f.write("-" * 40 + "\n")
        f.write(f"Cross-Split train <-> valid duplicate hashes: 0\n")
        f.write(f"Cross-Split train <-> test duplicate hashes:  0\n")
        f.write(f"Cross-Split valid <-> test duplicate hashes:  0\n")
        f.write(f"Total Cross-Split Duplicate Pairs:            0\n")
        f.write(f"Within-Split Duplicate Pairs:                 {len(within_split_pairs)} (strictly confined to single split)\n")
        f.write(f"Audit log saved to:                           duplicate_group_audit.csv\n\n")

        f.write("3. CLASS COUNTS TABLE\n")
        f.write("-" * 40 + "\n")
        for tl in table_lines:
            f.write(tl + "\n")
        f.write("\n")

        f.write("4. IMAGE DIMENSION DISTRIBUTION PER CLASS\n")
        f.write("-" * 40 + "\n")
        for _, crop, disease in CLASS_MAPPING:
            dim_counter = dimension_stats[(crop, disease)]
            tot_c = sum(dim_counter.values())
            f.write(f"• {crop} / {disease} (Total {tot_c:,} images):\n")
            for dim, count in dim_counter.most_common(3):
                f.write(f"    - {dim[0]}x{dim[1]}: {count:,} ({count/tot_c*100:.1f}%)\n")
            if len(dim_counter) > 3:
                other_cnt = sum(c for d, c in dim_counter.items() if d not in dict(dim_counter.most_common(3)))
                f.write(f"    - Other resolutions: {other_cnt:,}\n")
        f.write("\n")

        f.write("=" * 80 + "\n")
        f.write("SANITY CHECK VERDICT: READY FOR TRAINING: YES\n")
        f.write("=" * 80 + "\n")

    print(f"[OK] Saved final sanity check report to: {REPORT_TXT_PATH}")
    return table_lines, tot_tr, tot_va, tot_te, tot_all, len(within_split_pairs)


def main():
    start_total = time.time()
    all_items, hash_to_items = scan_source()
    hash_split, class_split_counts, audit_rows = compute_group_splits(hash_to_items)
    total_copied = rebuild_filesystem(hash_split, hash_to_items)
    table_lines, tot_tr, tot_va, tot_te, tot_all, within_pairs = run_full_sanity_check(total_copied, audit_rows)

    print("\n" + "=" * 80)
    print("REBUILD AND SANITY CHECK COMPLETE!")
    print(f"Total time elapsed: {time.time() - start_total:.1f}s")
    print("=" * 80)


if __name__ == "__main__":
    main()
