"""
Convert the chunked PyTorch checkpoint directory into a single .pth file.

The folder ai_module/best_model_final/phase3_full_best/ is a standard
torch.save() payload that was split by a serialisation library: data.pkl holds
the pickle stream, and the tensor bytes live in data/0, data/1, ... .

torch.load() cannot open it directly because:
  * data.pkl alone -> "A load persistent id instruction was encountered"
  * the folder      -> PermissionError (it is a directory, not an archive)

So we rebuild it: read data.pkl, and resolve every tensor storage out of the
data/ chunk files by offset, then save one clean single-file checkpoint.
"""
import os
import pickle
import struct
import sys

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FOLDER = os.path.join(BASE_DIR, "best_model_final", "phase3_full_best")
OUT = os.path.join(BASE_DIR, "best_model_final.pth")


class _Unpickler(pickle.Unpickler):
    """Resolves persistent tensor ids against the data/ chunk files."""

    def __init__(self, f, chunks):
        super().__init__(f)
        self._chunks = chunks

    def persistent_load(self, pid):
        # pid looks like: ('storage', FloatStorage, '0', 'cuda:0', size)
        if isinstance(pid, tuple) and pid and pid[0] == "storage":
            _, storage_type, key, location, numel = pid[0], pid[1], pid[2], pid[3], pid[4]
            if key in self._chunks:
                return storage_type.from_file(self._chunks[key], False, int(numel))
        raise pickle.UnpicklingError(f"unsupported persistent id: {pid!r}")


def load_chunked(folder):
    chunks = {}
    data_dir = os.path.join(folder, "data")
    for name in os.listdir(data_dir):
        chunks[name] = os.path.join(data_dir, name)

    with open(os.path.join(folder, "data.pkl"), "rb") as f:
        return _Unpickler(f, chunks).load()


def strip_prefixes(state_dict):
    """Remove Lightning 'model.' / 'module.' / DataParallel 'module.' prefixes."""
    cleaned = {}
    for k, v in state_dict.items():
        nk = k
        for p in ("module.", "model."):
            if nk.startswith(p):
                nk = nk[len(p):]
        cleaned[nk] = v
    return cleaned


def main():
    if not os.path.isdir(FOLDER):
        sys.exit(f"checkpoint folder not found: {FOLDER}")

    print(f"reading checkpoint from: {FOLDER}")
    ckpt = load_chunked(FOLDER)
    print("loaded type:", type(ckpt).__name__)
    print("top-level keys:", list(ckpt)[:20] if isinstance(ckpt, dict) else "n/a")

    if isinstance(ckpt, dict):
        for key in ("model_state", "state_dict", "model_state_dict"):
            if key in ckpt and isinstance(ckpt[key], dict):
                state_dict = ckpt[key]
                print(f"extracted '{key}' with {len(state_dict)} tensors")
                break
        else:
            state_dict = ckpt
            print(f"no wrapper key; using all {len(state_dict)} entries")

        meta = {k: v for k, v in ckpt.items() if k not in ("model_state", "state_dict", "model_state_dict")}
    else:
        state_dict = ckpt
        meta = {}

    prefixed = sum(1 for k in state_dict if k.startswith(("model.", "module.")))
    print(f"keys with model./module. prefix: {prefixed}/{len(state_dict)}")

    state_dict = strip_prefixes(state_dict)

    total = sum(v.numel() for v in state_dict.values() if hasattr(v, "numel"))
    print(f"total parameters: {total:,}")

    head = [k for k in state_dict if any(s in k for s in ("classifier", "fc", "head", "linear", "features"))]
    print("head/feature keys sample:", head[:6], "..." if len(head) > 6 else "")

    # Save exactly the format predict.py expects: a bare state_dict, which it
    # reads via ckpt.get("model_state", ckpt).
    torch_out = {"model_state": strip_prefixes(state_dict)}
    import torch
    torch.save(torch_out, OUT)

    size_mb = os.path.getsize(OUT) / (1024 * 1024)
    print(f"\nSAVED -> {OUT}  ({size_mb:.2f} MB)")
    if meta:
        print("metadata also present in original:", list(meta))


if __name__ == "__main__":
    main()
