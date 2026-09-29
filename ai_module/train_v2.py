"""
train_v2.py — V2 MobileNetV3-Large Crop Disease Training & Evaluation Pipeline
Krishi-Saarthi / SIH-2026 Agriculture Disease Detection Project

Dataset: D:\MASTER_DATASET (train, valid, test)
Architecture: torchvision.models.mobilenet_v3_large (ImageNet Pretrained)
Classes: 24 classes across 8 crops
Target: ai_module/models/v2/
"""

import os
import sys
import time
import json
import argparse
from pathlib import Path
from collections import defaultdict, Counter

# Ensure UTF-8 output on Windows consoles/pipes to prevent cp1252 charmap encode crashes
try:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms, models
from torchvision.models import MobileNet_V3_Large_Weights
from PIL import Image

import matplotlib
matplotlib.use("Agg")  # Headless backend
import matplotlib.pyplot as plt


# -----------------------------------------------------------------------------
# DATASET CLASS WITH CROP -> DISEASE HIERARCHY
# -----------------------------------------------------------------------------
class MasterDataset(Dataset):
    """
    Loads images from the D:\MASTER_DATASET\<split>\<Crop>\<Disease>\*.jpg hierarchy.
    """
    def __init__(self, split_dir: Path, class_to_idx: dict, transform=None):
        self.split_dir = split_dir
        self.transform = transform
        self.samples = []  # List of (filepath, class_idx, crop_name, disease_name)
        self.class_counts = Counter()

        for crop_dir in sorted(split_dir.iterdir()):
            if not crop_dir.is_dir():
                continue
            crop_name = crop_dir.name
            for disease_dir in sorted(crop_dir.iterdir()):
                if not disease_dir.is_dir():
                    continue
                disease_name = disease_dir.name
                tag = f"{crop_name}___{disease_name.replace(' ', '_')}"
                if tag not in class_to_idx:
                    continue
                class_idx = class_to_idx[tag]

                for f in sorted(disease_dir.iterdir()):
                    if f.is_file() and f.suffix.lower() in [".jpg", ".jpeg", ".png", ".webp"]:
                        self.samples.append((f, class_idx, crop_name, disease_name))
                        self.class_counts[class_idx] += 1

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        path, label, _, _ = self.samples[idx]
        with Image.open(path) as img:
            img = img.convert("RGB")
        if self.transform:
            img = self.transform(img)
        return img, label


# -----------------------------------------------------------------------------
# CLASS DISCOVERY & MAPPING
# -----------------------------------------------------------------------------
def build_class_mapping(dataset_root: Path):
    """
    Discover all 8 crops and 24 classes from train split deterministically.
    """
    train_dir = dataset_root / "train"
    crops = sorted([d.name for d in train_dir.iterdir() if d.is_dir()])

    classes = []
    crop_to_classes = defaultdict(list)
    plant_indices = {}

    for crop in crops:
        diseases = sorted([d.name for d in (train_dir / crop).iterdir() if d.is_dir()])
        crop_indices = []
        for disease in diseases:
            tag = f"{crop}___{disease.replace(' ', '_')}"
            classes.append(tag)
            crop_to_classes[crop].append(tag)

    classes = sorted(classes)
    class_to_idx = {tag: i for i, tag in enumerate(classes)}
    idx_to_class = {str(i): tag for i, tag in enumerate(classes)}

    # Map plant indices for crop-scoped filtering
    for crop in crops:
        c_indices = [class_to_idx[t] for t in crop_to_classes[crop]]
        plant_indices[crop.lower()] = (crop, c_indices)

    return classes, class_to_idx, idx_to_class, crops, crop_to_classes, plant_indices


# -----------------------------------------------------------------------------
# CONFUSION MATRIX PLOTTING
# -----------------------------------------------------------------------------
def plot_confusion_matrix(cm, class_names, save_path: Path):
    """
    Plot and save a high-resolution 24x24 confusion matrix.
    """
    fig, ax = plt.subplots(figsize=(16, 14), dpi=150)

    # Normalize by true class counts for clear heatmap shading
    cm_norm = cm.astype(float) / (cm.sum(axis=1, keepdims=True) + 1e-9)
    im = ax.imshow(cm_norm, interpolation='nearest', cmap=plt.cm.Blues)
    ax.figure.colorbar(im, ax=ax, fraction=0.046, pad=0.04)

    # Clean short labels for axes
    short_labels = [c.replace("___", " ") for c in class_names]
    ax.set(
        xticks=np.arange(cm.shape[1]),
        yticks=np.arange(cm.shape[0]),
        xticklabels=short_labels,
        yticklabels=short_labels,
        title="MobileNetV3-Large V2 — 24-Class Confusion Matrix (Test Set)",
        ylabel="True Disease Label",
        xlabel="Predicted Disease Label"
    )

    plt.setp(ax.get_xticklabels(), rotation=45, ha="right", rotation_mode="anchor", fontsize=8)
    plt.setp(ax.get_yticklabels(), fontsize=8)

    # Print numbers in cells
    thresh = cm_norm.max() / 2.
    for i in range(cm.shape[0]):
        for j in range(cm.shape[1]):
            val = cm[i, j]
            if val > 0:
                ax.text(
                    j, i, f"{val:d}",
                    ha="center", va="center",
                    color="white" if cm_norm[i, j] > thresh else "black",
                    fontsize=7
                )

    fig.tight_layout()
    plt.savefig(save_path, bbox_inches="tight")
    plt.close()
    print(f"[OK] Saved confusion matrix image to: {save_path}")


# -----------------------------------------------------------------------------
# EVALUATION ROUTINE
# -----------------------------------------------------------------------------
def evaluate_model(model, dataloader, criterion, device, class_names):
    """
    Evaluates model on dataloader, returning loss, accuracy, and predictions.
    """
    model.eval()
    running_loss = 0.0
    correct = 0
    total = 0

    all_preds = []
    all_targets = []

    with torch.no_grad():
        for inputs, targets in dataloader:
            inputs = inputs.to(device)
            targets = targets.to(device)

            outputs = model(inputs)
            loss = criterion(outputs, targets)

            running_loss += loss.item() * inputs.size(0)
            _, predicted = outputs.max(1)

            correct += predicted.eq(targets).sum().item()
            total += targets.size(0)

            all_preds.extend(predicted.cpu().numpy())
            all_targets.extend(targets.cpu().numpy())

    epoch_loss = running_loss / total
    epoch_acc = correct / total
    return epoch_loss, epoch_acc, np.array(all_targets), np.array(all_preds)


# -----------------------------------------------------------------------------
# MAIN TRAINING PIPELINE
# -----------------------------------------------------------------------------
def train_v2(args):
    print("=" * 80)
    print("STARTING V2 MOBILENETV3-LARGE TRAINING PIPELINE")
    print(f"Dataset Root: {args.dataset_dir}")
    print(f"Output Dir:   {args.output_dir}")
    print("=" * 80)

    dataset_root = Path(args.dataset_dir)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # 1. Device selection
    device = torch.device(args.device if (args.device == "cuda" and torch.cuda.is_available()) else "cpu")
    print(f"[OK] Training Device: {device}")

    # Set threads on CPU for maximum throughput
    if device.type == "cpu":
        torch.set_num_threads(8)
        print(f"[OK] Set PyTorch CPU threads: {torch.get_num_threads()}")

    # 2. Build and save V2 class mapping
    class_names, class_to_idx, idx_to_class, crops, crop_to_classes, plant_indices = build_class_mapping(dataset_root)
    num_classes = len(class_names)
    print(f"[OK] Discovered {len(crops)} crops and {num_classes} classes.")

    mapping_payload = {
        "class_names": class_names,
        "class_to_idx": class_to_idx,
        "idx_to_class": idx_to_class,
        "crops": crops,
        "crop_to_classes": crop_to_classes,
        "plant_indices": plant_indices,
        "total_classes": num_classes,
        "created_at": time.strftime("%Y-%m-%d %H:%M:%S")
    }
    class_mapping_path = output_dir / "class_names_v2.json"
    with open(class_mapping_path, "w", encoding="utf-8") as f:
        json.dump(mapping_payload, f, indent=2)
    print(f"[OK] Saved V2 class mapping to: {class_mapping_path}")

    # 3. Define transforms
    train_transform = transforms.Compose([
        transforms.RandomResizedCrop(224, scale=(0.8, 1.0)),
        transforms.RandomHorizontalFlip(),
        transforms.RandomRotation(15),
        transforms.ColorJitter(brightness=0.1, contrast=0.1),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

    val_test_transform = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

    # 4. Datasets and DataLoaders
    train_dataset = MasterDataset(dataset_root / "train", class_to_idx, transform=train_transform)
    valid_dataset = MasterDataset(dataset_root / "valid", class_to_idx, transform=val_test_transform)
    test_dataset  = MasterDataset(dataset_root / "test",  class_to_idx, transform=val_test_transform)

    print(f"[OK] Loaded Datasets: Train={len(train_dataset):,}, Valid={len(valid_dataset):,}, Test={len(test_dataset):,}")

    train_loader = DataLoader(train_dataset, batch_size=args.batch_size, shuffle=True, num_workers=0, pin_memory=False)
    valid_loader = DataLoader(valid_dataset, batch_size=args.batch_size, shuffle=False, num_workers=0, pin_memory=False)
    test_loader  = DataLoader(test_dataset,  batch_size=args.batch_size, shuffle=False, num_workers=0, pin_memory=False)

    # 5. Compute class-weighted loss to handle imbalance
    total_train = len(train_dataset)
    weights_list = []
    for i in range(num_classes):
        cnt = train_dataset.class_counts[i]
        w = total_train / (num_classes * cnt) if cnt > 0 else 1.0
        weights_list.append(w)
    weights_tensor = torch.tensor(weights_list, dtype=torch.float32).to(device)
    criterion = nn.CrossEntropyLoss(weight=weights_tensor)
    print(f"[OK] Initialized Class-Weighted CrossEntropyLoss (min weight={min(weights_list):.2f}, max={max(weights_list):.2f})")

    # 6. Initialize MobileNetV3-Large with ImageNet Pretrained Weights
    print("\nLoading torchvision MobileNetV3-Large (ImageNet pretrained)...")
    model = models.mobilenet_v3_large(weights=MobileNet_V3_Large_Weights.DEFAULT)

    # Replace final classification head (1280 -> 24)
    in_features = model.classifier[3].in_features
    model.classifier[3] = nn.Linear(in_features, num_classes)
    model = model.to(device)
    print(f"[OK] Replaced classifier[3] with Linear({in_features} -> {num_classes})")

    # 7. Training Strategy: Two-Phase Transfer Learning
    # Phase 1: Freeze features, train classifier head
    # Phase 2: Unfreeze top layers for fine-tuning
    print("\nTraining Schedule:")
    print(f"  • Total Epochs: {args.epochs}")
    print(f"  • Batch Size:   {args.batch_size}")
    print(f"  • Optimizer:    AdamW (lr={args.lr}, weight_decay={args.weight_decay})")

    optimizer = torch.optim.AdamW(
        filter(lambda p: p.requires_grad, model.parameters()),
        lr=args.lr,
        weight_decay=args.weight_decay
    )
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=args.epochs, eta_min=1e-5)

    best_val_acc = 0.0
    best_val_loss = float("inf")
    best_epoch = -1
    best_model_path = output_dir / "best_model_v2.pth"

    start_epoch = 1
    # Auto-resume from existing checkpoint if available
    if best_model_path.exists():
        try:
            prev_ckpt = torch.load(best_model_path, map_location=device, weights_only=False)
            model.load_state_dict(prev_ckpt["model_state"])
            best_val_acc = prev_ckpt.get("val_acc", 0.0)
            best_val_loss = prev_ckpt.get("val_loss", float("inf"))
            best_epoch = prev_ckpt.get("epoch", 1)
            start_epoch = best_epoch + 1
            print(f"[OK] Resuming from existing checkpoint: Epoch {best_epoch} (Val Acc: {best_val_acc*100:.2f}%)")
        except Exception as e:
            print(f"[WARN] Could not resume from {best_model_path}: {e}")

    training_history = []
    # Load previous history if present
    hist_path = output_dir / "training_history.json"
    if hist_path.exists():
        try:
            with open(hist_path, "r", encoding="utf-8") as f:
                training_history = json.load(f)
        except Exception:
            pass

    pipeline_start = time.time()

    for epoch in range(start_epoch, args.epochs + 1):
        epoch_start = time.time()

        # In last epoch, unfreeze top feature blocks for semantic adaptation
        if epoch == args.epochs and args.epochs > 1:
            print("\n[Phase 2] Unfreezing top feature layers for fine-tuning...")
            for param in model.features[-3:].parameters():
                param.requires_grad = True
            optimizer = torch.optim.AdamW(
                [
                    {"params": model.features[-3:].parameters(), "lr": args.lr * 0.1},
                    {"params": model.classifier.parameters(), "lr": args.lr * 0.5}
                ],
                weight_decay=args.weight_decay
            )
        elif epoch == 1:
            # Freeze features for fast, stable initial head alignment
            for param in model.features.parameters():
                param.requires_grad = False
            for param in model.classifier.parameters():
                param.requires_grad = True

        # TRAIN
        model.train()
        train_loss = 0.0
        train_correct = 0
        train_total = 0

        for batch_idx, (inputs, targets) in enumerate(train_loader, 1):
            inputs = inputs.to(device)
            targets = targets.to(device)

            optimizer.zero_grad()
            outputs = model(inputs)
            loss = criterion(outputs, targets)
            loss.backward()
            optimizer.step()

            train_loss += loss.item() * inputs.size(0)
            _, predicted = outputs.max(1)
            train_correct += predicted.eq(targets).sum().item()
            train_total += targets.size(0)

            if batch_idx % 70 == 0 or batch_idx == len(train_loader):
                elapsed = time.time() - epoch_start
                rate = train_total / elapsed if elapsed > 0 else 0
                print(f"   Epoch [{epoch}/{args.epochs}] Batch [{batch_idx}/{len(train_loader)}] Loss: {loss.item():.4f} ({rate:.1f} imgs/sec)")

        scheduler.step()
        train_loss /= train_total
        train_acc = train_correct / train_total

        # VALIDATE
        val_loss, val_acc, _, _ = evaluate_model(model, valid_loader, criterion, device, class_names)
        epoch_time = time.time() - epoch_start

        print(f"\n>> Epoch [{epoch}/{args.epochs}] Completed in {epoch_time:.1f}s:")
        print(f"   Train Loss: {train_loss:.4f} | Train Acc: {train_acc*100:.2f}%")
        print(f"   Valid Loss: {val_loss:.4f} | Valid Acc: {val_acc*100:.2f}%")

        record = {
            "epoch": epoch,
            "train_loss": round(train_loss, 4),
            "train_acc": round(train_acc, 4),
            "val_loss": round(val_loss, 4),
            "val_acc": round(val_acc, 4),
            "time_seconds": round(epoch_time, 1)
        }
        training_history.append(record)

        # Model selection based on validation accuracy
        if val_acc > best_val_acc or (val_acc == best_val_acc and val_loss < best_val_loss):
            best_val_acc = val_acc
            best_val_loss = val_loss
            best_epoch = epoch

            # Save full checkpoint compatible with inference
            checkpoint = {
                "epoch": epoch,
                "model_state": model.state_dict(),
                "val_acc": val_acc,
                "val_loss": val_loss,
                "class_names": class_names,
                "class_to_idx": class_to_idx,
                "num_classes": num_classes,
                "architecture": "mobilenet_v3_large"
            }
            torch.save(checkpoint, best_model_path)
            print(f"   [* BEST MODEL SAVED] Validation Accuracy improved to: {val_acc*100:.2f}% (Loss: {val_loss:.4f})")

    total_training_time = time.time() - pipeline_start
    print("\n" + "=" * 80)
    print(f"TRAINING COMPLETE in {total_training_time/60:.2f} minutes!")
    print(f"Best Validation Accuracy: {best_val_acc*100:.2f}% at Epoch {best_epoch}")
    print("=" * 80)

    # Save training history and config
    with open(output_dir / "training_history.json", "w", encoding="utf-8") as f:
        json.dump(training_history, f, indent=2)

    config_payload = {
        "model_name": "MobileNetV3-Large V2",
        "architecture": "mobilenet_v3_large",
        "weights": "ImageNet Pretrained (Transfer Learning)",
        "input_size": 224,
        "num_classes": num_classes,
        "epochs": args.epochs,
        "batch_size": args.batch_size,
        "optimizer": "AdamW",
        "learning_rate": args.lr,
        "weight_decay": args.weight_decay,
        "loss_function": "Weighted CrossEntropyLoss",
        "device": str(device),
        "best_epoch": best_epoch,
        "best_val_accuracy": round(best_val_acc, 4),
        "best_val_loss": round(best_val_loss, 4),
        "total_training_time_seconds": round(total_training_time, 1)
    }
    with open(output_dir / "training_config.json", "w", encoding="utf-8") as f:
        json.dump(config_payload, f, indent=2)

    # -------------------------------------------------------------------------
    # 8. POST-TRAINING TEST EVALUATION ON UNTOUCHED TEST SET
    # -------------------------------------------------------------------------
    print("\n" + "=" * 80)
    print("EVALUATING BEST MODEL ON UNTOUCHED TEST SET (D:\\MASTER_DATASET\\test)")
    print("=" * 80)

    # Reload best checkpoint
    print(f"Loading checkpoint: {best_model_path}")
    best_ckpt = torch.load(best_model_path, map_location=device, weights_only=False)
    eval_model = models.mobilenet_v3_large(weights=None)
    eval_model.classifier[3] = nn.Linear(in_features, num_classes)
    eval_model.load_state_dict(best_ckpt["model_state"])
    eval_model = eval_model.to(device)
    eval_model.eval()

    test_loss, test_acc, y_true, y_pred = evaluate_model(eval_model, test_loader, criterion, device, class_names)
    print(f"\n[TEST RESULTS] Overall Test Accuracy: {test_acc*100:.2f}% | Test Loss: {test_loss:.4f}")

    # Compute Confusion Matrix (24x24)
    cm = np.zeros((num_classes, num_classes), dtype=int)
    for t, p in zip(y_true, y_pred):
        cm[t, p] += 1

    # Save Confusion Matrix Plot
    cm_img_path = output_dir / "confusion_matrix.png"
    plot_confusion_matrix(cm, class_names, cm_img_path)

    # Compute Per-Class Precision, Recall, F1, Support
    precisions = []
    recalls = []
    f1_scores = []
    supports = []

    per_class_metrics = {}

    for c in range(num_classes):
        tp = cm[c, c]
        fp = cm[:, c].sum() - tp
        fn = cm[c, :].sum() - tp
        sup = cm[c, :].sum()

        prec = tp / (tp + fp) if (tp + fp) > 0 else 0.0
        rec  = tp / (tp + fn) if (tp + fn) > 0 else 0.0
        f1   = 2 * prec * rec / (prec + rec) if (prec + rec) > 0 else 0.0

        precisions.append(prec)
        recalls.append(rec)
        f1_scores.append(f1)
        supports.append(sup)

        per_class_metrics[class_names[c]] = {
            "precision": round(prec, 4),
            "recall": round(rec, 4),
            "f1": round(f1, 4),
            "support": int(sup)
        }

    macro_precision = float(np.mean(precisions))
    macro_recall    = float(np.mean(recalls))
    macro_f1        = float(np.mean(f1_scores))

    print(f"Macro Precision: {macro_precision*100:.2f}%")
    print(f"Macro Recall:    {macro_recall*100:.2f}%")
    print(f"Macro F1 Score:  {macro_f1*100:.2f}%")

    # Verify that all 24 classes appear in test evaluation
    classes_in_test = sum(1 for s in supports if s > 0)
    print(f"Classes with test support: {classes_in_test}/{num_classes}")
    assert classes_in_test == 24, "Not all 24 classes were present in test evaluation!"

    # Top 10 Most Confused Class Pairs
    confused_pairs = []
    for i in range(num_classes):
        for j in range(num_classes):
            if i != j and cm[i, j] > 0:
                confused_pairs.append((class_names[i], class_names[j], int(cm[i, j])))

    confused_pairs.sort(key=lambda x: x[2], reverse=True)
    top_10_confused = confused_pairs[:10]

    # Build and Save evaluation_report.txt
    eval_report_path = output_dir / "evaluation_report.txt"
    with open(eval_report_path, "w", encoding="utf-8") as f:
        f.write("=" * 80 + "\n")
        f.write("MOBILENETV3-LARGE V2 — TEST EVALUATION REPORT\n")
        f.write(f"Generated at: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Model Checkpoint: {best_model_path}\n")
        f.write("=" * 80 + "\n\n")

        f.write("1. GLOBAL PERFORMANCE METRICS (UNTOUCHED TEST SET)\n")
        f.write("-" * 50 + "\n")
        f.write(f"Overall Test Accuracy:       {test_acc*100:.2f}%\n")
        f.write(f"Test Loss:                   {test_loss:.4f}\n")
        f.write(f"Macro Precision:             {macro_precision*100:.2f}%\n")
        f.write(f"Macro Recall:                {macro_recall*100:.2f}%\n")
        f.write(f"Macro F1 Score:              {macro_f1*100:.2f}%\n")
        f.write(f"Total Test Images Evaluated: {len(test_dataset):,}\n")
        f.write(f"Total Classes Represented:   {classes_in_test} / {num_classes}\n\n")

        f.write("2. PER-CLASS EVALUATION METRICS TABLE\n")
        f.write("-" * 80 + "\n")
        f.write(f"{'Class Name':35s} | {'Precision':>9s} | {'Recall':>9s} | {'F1-Score':>9s} | {'Support':>7s}\n")
        f.write("-" * 80 + "\n")
        for c in range(num_classes):
            name = class_names[c]
            f.write(f"{name:35s} | {precisions[c]*100:8.2f}% | {recalls[c]*100:8.2f}% | {f1_scores[c]*100:8.2f}% | {supports[c]:7d}\n")
        f.write("-" * 80 + "\n")
        f.write(f"{'MACRO AVERAGE':35s} | {macro_precision*100:8.2f}% | {macro_recall*100:8.2f}% | {macro_f1*100:8.2f}% | {len(test_dataset):7d}\n\n")

        f.write("3. TOP 10 MOST CONFUSED CLASS PAIRS\n")
        f.write("-" * 60 + "\n")
        if top_10_confused:
            for rank, (true_cls, pred_cls, count) in enumerate(top_10_confused, 1):
                f.write(f"  #{rank:2d}: {true_cls}  --->  misclassified as  --->  {pred_cls} ({count} images)\n")
        else:
            f.write("  Zero misclassifications detected on test set!\n")
        f.write("\n")

        f.write("4. ARTIFACTS SAVED\n")
        f.write("-" * 50 + "\n")
        f.write(f"• Model Weights:      {best_model_path}\n")
        f.write(f"• Class Mapping:      {class_mapping_path}\n")
        f.write(f"• Confusion Matrix:   {cm_img_path}\n")
        f.write(f"• Metrics JSON:       {output_dir / 'test_metrics.json'}\n")
        f.write(f"• Training History:   {output_dir / 'training_history.json'}\n")
        f.write(f"• Training Config:    {output_dir / 'training_config.json'}\n\n")
        f.write("=" * 80 + "\n")
        f.write("READY FOR REAL-IMAGE PREDICTION TESTING: YES\n")
        f.write("=" * 80 + "\n")

    print(f"[OK] Saved evaluation report to: {eval_report_path}")

    # Save test metrics JSON
    test_metrics_payload = {
        "overall_test_accuracy": round(test_acc, 4),
        "test_loss": round(test_loss, 4),
        "macro_precision": round(macro_precision, 4),
        "macro_recall": round(macro_recall, 4),
        "macro_f1": round(macro_f1, 4),
        "total_test_images": len(test_dataset),
        "classes_represented": classes_in_test,
        "per_class": per_class_metrics,
        "top_10_confused_pairs": top_10_confused
    }
    with open(output_dir / "test_metrics.json", "w", encoding="utf-8") as f:
        json.dump(test_metrics_payload, f, indent=2)

    return best_val_acc, best_val_loss, test_acc, macro_f1, best_model_path, class_mapping_path, eval_report_path, cm_img_path


def main():
    parser = argparse.ArgumentParser(description="V2 MobileNetV3-Large Training Pipeline")
    parser.add_argument("--dataset_dir", type=str, default=r"D:\MASTER_DATASET", help="Dataset root directory")
    parser.add_argument("--output_dir", type=str, default=str(Path(__file__).parent / "models" / "v2"), help="Output directory")
    parser.add_argument("--epochs", type=int, default=3, help="Number of training epochs")
    parser.add_argument("--batch_size", type=int, default=64, help="Batch size")
    parser.add_argument("--lr", type=float, default=1e-3, help="Learning rate")
    parser.add_argument("--weight_decay", type=float, default=1e-2, help="Weight decay")
    parser.add_argument("--seed", type=int, default=42, help="Random seed")
    parser.add_argument("--device", type=str, default="cuda", help="Target device (cuda or cpu)")
    args = parser.parse_args()

    train_v2(args)


if __name__ == "__main__":
    main()
