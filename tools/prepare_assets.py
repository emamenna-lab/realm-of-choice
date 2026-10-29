"""Prepara gli asset grafici a partire dalle immagini generate (assets/raw/).

Uso: python3 tools/prepare_assets.py
Scrive in assets/: sfondi, emblemi dei focolai scontornati, Cortigiano e regina senza sfondo verde.
Va rilanciato solo quando cambiano le immagini in assets/raw/.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "assets" / "raw"
OUT = ROOT / "assets"

# Ordine degli emblemi nel foglio: due colonne, l'ultimo centrato in basso.
OUTBREAK_IDS = [
    "rivolta_pane", "sciopero_gilde",
    "complotto_nobiliare", "setta_fanatica",
    "epidemia", "diserzione_guardia",
    "rancore",
]
ICON_SIZE = 256


def warm_mask(img: Image.Image) -> np.ndarray:
    """Pixel caldi (bronzo, oro, fuoco): distinguono gli emblemi dal fondo grigio-blu e dalle scritte bianche."""
    a = np.asarray(img.convert("RGB")).astype(int)
    return (a[:, :, 0] - a[:, :, 2]) > 30


def find_emblems(img: Image.Image) -> list[tuple[int, int, int]]:
    """Trova centro e raggio di ogni emblema: fasce orizzontali di pixel caldi, poi colonne dentro ogni fascia."""
    mask = warm_mask(img)
    rows = mask.sum(axis=1) > 20
    bands, start = [], None
    for y, on in enumerate(rows):
        if on and start is None:
            start = y
        elif not on and start is not None:
            if y - start > 100:
                bands.append((start, y))
            start = None
    circles = []
    for top, bottom in bands:
        cols = mask[top:bottom].sum(axis=0) > 10
        x, spans = 0, []
        while x < len(cols):
            if cols[x]:
                s = x
                while x < len(cols) and cols[x]:
                    x += 1
                if x - s > 100:
                    spans.append((s, x))
            x += 1
        for left, right in spans:
            # La larghezza è affidabile; in basso il bordo in ombra non risulta "caldo",
            # quindi il centro verticale si ricava dal bordo superiore.
            half = (right - left) // 2
            circles.append(((left + right) // 2, top + half, half - 6))
    return circles


def cut_circle(img: Image.Image, cx: int, cy: int, r: int) -> Image.Image:
    box = (cx - r, cy - r, cx + r, cy + r)
    crop = img.crop(box).convert("RGBA")
    alpha = Image.new("L", crop.size, 0)
    ImageDraw.Draw(alpha).ellipse((1, 1, crop.size[0] - 2, crop.size[1] - 2), fill=255)
    crop.putalpha(alpha.filter(ImageFilter.GaussianBlur(1)))
    return crop.resize((ICON_SIZE, ICON_SIZE), Image.LANCZOS)


def chroma_key(img: Image.Image) -> Image.Image:
    """Toglie lo sfondo verde e attenua l'alone verde sui bordi."""
    a = np.asarray(img.convert("RGB")).astype(float)
    r, g, b = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    greenness = g - np.maximum(r, b)
    alpha = np.clip(1.0 - (greenness - 40) / 80, 0, 1)
    # Despill: il verde non può superare il massimo tra rosso e blu.
    a[:, :, 1] = np.minimum(g, np.maximum(r, b) * 1.05)
    rgba = np.dstack([a, alpha * 255]).astype(np.uint8)
    out = Image.fromarray(rgba, "RGBA")
    return out.crop(out.getbbox())


def main() -> None:
    OUT.mkdir(exist_ok=True)

    Image.open(RAW / "map.jpg").convert("RGB").save(OUT / "bg_map.jpg", quality=88)

    sheet = Image.open(RAW / "outbreak_sheet.jpg")
    circles = find_emblems(sheet)
    if len(circles) != len(OUTBREAK_IDS):
        raise SystemExit(f"trovati {len(circles)} emblemi invece di {len(OUTBREAK_IDS)}: {circles}")
    for type_id, (cx, cy, r) in zip(OUTBREAK_IDS, circles):
        cut_circle(sheet, cx, cy, r).save(OUT / f"outbreak_{type_id}.png")

    court = Image.open(RAW / "court_sheet.jpg").convert("RGB")
    # Il foglio contiene la sala in alto (fino a y=690) e il Cortigiano su verde sotto.
    court.crop((0, 0, court.width, 688)).save(OUT / "bg_court.jpg", quality=88)
    chroma_key(court.crop((0, 730, court.width, 1325))).save(OUT / "courtier.png")
    queen = chroma_key(Image.open(RAW / "queen_green.jpg"))
    # Sullo schermo occupa al massimo ~550 px di altezza: 700 bastano anche per schermi densi.
    queen = queen.resize((round(queen.width * 700 / queen.height), 700), Image.LANCZOS)
    queen.save(OUT / "queen.png")
    print("emblemi:", circles)


if __name__ == "__main__":
    main()
