import os

_limit_gb = float(os.environ.get("VRAM_LIMIT_GB", "0"))
if _limit_gb > 0:
    try:
        import torch
        if torch.cuda.is_available():
            total = torch.cuda.get_device_properties(0).total_memory
            fraction = (_limit_gb * 1024 ** 3) / total
            torch.cuda.set_per_process_memory_fraction(min(fraction, 1.0))
    except ImportError:
        pass
