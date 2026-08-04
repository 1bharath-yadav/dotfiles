"""OCR pipeline: capture/select an image, then run tesseract over it."""
import os
import subprocess
from pathlib import Path
from rich.console import Console

console = Console()


def run_cmd(cmd: str) -> str:
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return res.stdout.strip() if res.returncode == 0 else ""


def _capture_to(source: str, dst: str, file: str | None = None) -> str | None:
    """
    Resolve ``source`` to an image path. Returns the path to OCR, or
    ``None`` if nothing was captured / the source was invalid.
    """
    if source == "file":
        if not file:
            console.print("[red]--file is required when source is 'file'.[/red]")
            return None
        return file
    if source == "region":
        os.system(f'grim -g "$(slurp)" {dst}')
    elif source == "clipboard":
        os.system(f'wl-paste > {dst}')
    elif source == "active":
        import hyprland
        win = hyprland.get_json("activewindow")
        if win and "at" in win and "size" in win:
            at, size = win["at"], win["size"]
            geom = f'{at[0]},{at[1]} {size[0]}x{size[1]}'
            os.system(f'grim -g "{geom}" {dst}')
        else:
            os.system(f'grim {dst}')
    else:
        console.print(f"[red]Unknown OCR source:[/red] {source}")
        return None
    return dst


def run_ocr(source: str = "region", file: str | None = None, boxes: bool = False):
    """
    Run OCR over ``source`` (``region``/``clipboard``/``active``/``file``).
    Returns the tesseract stdout text (plain or TSV when ``boxes=True``).
    """
    tmp_img = "/tmp/ocr_image.png"
    img = _capture_to(source, tmp_img, file=file)
    if not img or not os.path.exists(img):
        console.print("[red]Image source invalid or capture cancelled.[/red]")
        return ""

    if boxes:
        out = run_cmd(f'tesseract "{img}" stdout tsv')
        console.print(out)
    else:
        out = run_cmd(f'tesseract "{img}" stdout')
        console.print(out)

    # Clean up the temp capture, but never delete a user-supplied file.
    if source != "file" and img == tmp_img and os.path.exists(tmp_img):
        os.remove(tmp_img)
    return out


def handle_cli(args):
    run_ocr(source=args.source, file=args.file, boxes=args.boxes)
