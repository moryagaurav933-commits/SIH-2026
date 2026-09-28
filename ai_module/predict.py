"""
predict.py — Agri-Saarthi disease prediction
Usage: python predict.py <image_path>
"""
import os, sys, json
import numpy as np
from PIL import Image

BASE       = os.path.dirname(os.path.abspath(__file__))
PT_CKPT    = os.path.join(BASE, 'models', 'finetune_v1', 'best_model_final.pth')
if not os.path.isfile(PT_CKPT):
    PT_CKPT = os.path.join(BASE, 'best_model_final.pth')

PT_CLASSES = os.path.join(BASE, 'models', 'finetune_v1', 'class_names.json')
if not os.path.isfile(PT_CLASSES):
    PT_CLASSES = os.path.join(BASE, 'class_names.json')
TF_MODEL   = os.path.join(BASE, 'exported', 'model.tflite')
TF_LABELS  = os.path.join(BASE, 'models', 'plant_disease_v1', 'class_labels.json')
IMG_SIZE   = 224
# Below this confidence the prediction is treated as "uncertain".
LOW_CONFIDENCE_THRESHOLD = 0.50
# When the user picks a crop we restrict the softmax to that crop's classes and
# renormalise, which always yields a high top score even when the model puts
# almost no mass on that crop. So we ALSO require this much raw probability mass
# on the selected crop before we trust the renormalised confidence; otherwise a
# potato photo read as "potato" would be reported as 81% Late Blight while the
# model actually assigned it 0.2%.
MIN_CROP_MASS_THRESHOLD = 0.35

PLANT_INDICES = {
    '1': ('Tomato',  list(range(11, 21))),
    '2': ('Potato',  list(range(8, 11))),
    '3': ('Maize',   list(range(4, 8))),
    '4': ('Apple',   list(range(0, 4))),
}

def _preprocess_image(pil_img):
    """Validated inference preprocessing (Variant B — center crop 80%).
    Tested: same accuracy as baseline, higher confidence on borderline images.
    Flutter-compatible: crop + resize only."""
    w, h   = pil_img.size
    mw, mh = int(w * 0.10), int(h * 0.10)
    cropped = pil_img.crop((mw, mh, w - mw, h - mh))
    return cropped.resize((IMG_SIZE, IMG_SIZE), Image.BILINEAR)


def _load_image(image_path):
    """Open an image as RGB, with a friendly error for unreadable input."""
    try:
        return Image.open(image_path).convert('RGB')
    except Exception as e:
        raise ValueError(
            f'Cannot read image {os.path.basename(image_path)!r}: '
            f'{type(e).__name__}. Use a valid .jpg/.png/.webp/.avif file.'
        ) from e


def select_plant():
    print('\n  Select your crop/plant:')
    for k, (name, _) in PLANT_INDICES.items():
        print(f'    {k}. {name}')
    while True:
        c = input('\n  Enter number (1-4): ').strip()
        if c in PLANT_INDICES:
            return c
        print('  Invalid.')

def predict_pytorch(image_path, plant_key):
    import torch
    from torchvision import transforms, models
    import torch.nn as nn

    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

    with open(PT_CLASSES) as f:
        cfg = json.load(f)
    class_names = cfg['class_names']

    model = models.mobilenet_v3_large(weights=None)
    model.classifier[3] = nn.Linear(model.classifier[3].in_features, len(class_names))
    ckpt = torch.load(PT_CKPT, map_location=device, weights_only=False)
    state_dict = ckpt.get('model_state', ckpt) if isinstance(ckpt, dict) else ckpt
    model.load_state_dict(state_dict)
    model.eval().to(device)

    tf = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
    ])
    img    = tf(_preprocess_image(_load_image(image_path))).unsqueeze(0).to(device)
    with torch.no_grad():
        logits = model(img)[0]
        probs  = torch.softmax(logits, dim=0).cpu().numpy()

    _, indices = PLANT_INDICES[plant_key]
    plant_p = np.array([probs[i] for i in indices])
    crop_mass = float(plant_p.sum())
    denom    = plant_p.sum()
    norm     = plant_p / denom if denom > 0 else plant_p
    order    = np.argsort(norm)[::-1]
    return class_names, indices, norm, order, 'PyTorch', crop_mass

def predict_tflite(image_path, plant_key):
    from ai_edge_litert.interpreter import Interpreter
    with open(TF_LABELS) as f:
        class_names = json.load(f)['class_names']
    interp = Interpreter(model_path=TF_MODEL)
    interp.allocate_tensors()
    inp = interp.get_input_details()[0]
    out = interp.get_output_details()[0]
    img = _load_image(image_path)
    img = _preprocess_image(img)
    arr = (np.array(img, dtype=np.float32) / 127.5) - 1.0
    interp.set_tensor(inp['index'], arr[None])
    interp.invoke()
    probs = interp.get_tensor(out['index'])[0]
    _, indices = PLANT_INDICES[plant_key]
    plant_p = np.array([probs[i] for i in indices])
    crop_mass = float(plant_p.sum())
    denom    = plant_p.sum()
    norm     = plant_p / denom if denom > 0 else plant_p
    order    = np.argsort(norm)[::-1]
    return class_names, indices, norm, order, 'TFLite', crop_mass

def main():
    if len(sys.argv) < 2:
        print('Usage: python predict.py <image_path>')
        sys.exit(1)
    image_path = sys.argv[1]
    if not os.path.isfile(image_path):
        print(f'ERROR: File not found: {image_path}')
        sys.exit(1)

    if len(sys.argv) >= 3:
        arg = sys.argv[2].strip().lower()
        if arg in PLANT_INDICES:
            plant_key = arg
        elif arg in ('tomato', 'potato', 'maize', 'apple'):
            name_to_k = {'tomato': '1', 'potato': '2', 'maize': '3', 'apple': '4'}
            plant_key = name_to_k[arg]
        else:
            plant_key = select_plant()
    else:
        plant_key = select_plant()
    plant_name = PLANT_INDICES[plant_key][0]

    # Use PyTorch model if available, else TFLite
    try:
        if os.path.isfile(PT_CKPT):
            class_names, indices, norm, order, backend, crop_mass = predict_pytorch(image_path, plant_key)
        else:
            class_names, indices, norm, order, backend, crop_mass = predict_tflite(image_path, plant_key)
    except ValueError as e:
        print(f'ERROR: {e}')
        sys.exit(1)

    sep = '=' * 58
    print(f'\n{sep}')
    print(f'  PLANT DISEASE PREDICTION ({backend})')
    print(sep)
    print(f'  Image  : {os.path.basename(image_path)}')
    print(f'  Plant  : {plant_name}')
    print()
    top_idx  = indices[order[0]]
    top_conf = norm[order[0]]
    crop_mismatch = crop_mass < MIN_CROP_MASS_THRESHOLD
    if crop_mismatch:
        print('  Result : Uncertain - image does not look like the selected crop')
        print(f'  Conf   : {top_conf*100:.2f}% (within {plant_name})')
        print(f'  Match  : only {crop_mass*100:.2f}% model confidence that this is {plant_name}')
        print(f'  WARNING: Re-select the correct crop before trusting this result.')
    elif top_conf < LOW_CONFIDENCE_THRESHOLD:
        print('  Result : Uncertain - low confidence')
        print(f'  Conf   : {top_conf*100:.2f}%')
        print('  WARNING: Image is ambiguous; retake in good light / in close-up and retry.')
    else:
        print(f'  Result : {class_names[top_idx]}')
        print(f'  Conf   : {top_conf*100:.2f}%')
    print()
    print(f'  Top-3 {plant_name} predictions:')
    for r in range(min(3, len(indices))):
        bar = '#' * int(norm[order[r]] * 30)
        print(f'    #{r+1}  {norm[order[r]]*100:6.2f}%  {bar:<30}  {class_names[indices[order[r]]]}')
    print(sep)

if __name__ == '__main__':
    main()
