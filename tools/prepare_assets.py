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


def checker_mask(img: Image.Image) -> Image.Image:
    """Pixel del finto sfondo a scacchi (grigio chiaro e bianco, senza colore): 255 dove c'è scacchiera."""
    a = np.asarray(img.convert("RGB")).astype(int)
    neutral = (a.max(axis=2) - a.min(axis=2)) <= 14
    bright = a.min(axis=2) >= 170
    return Image.fromarray(((neutral & bright) * 255).astype(np.uint8), "L")


def checker_key(img: Image.Image, from_top: bool) -> Image.Image:
    """Toglie la scacchiera disegnata dentro il JPG. Con from_top tiene solo la scacchiera collegata
    al bordo alto (il cielo), così i riflessi chiari dentro il soggetto restano."""
    mask = checker_mask(img)
    # Chiude i buchi tra quadri: le linee di confine tra i quadri non sono né bianche né grigie.
    mask = mask.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(5))
    if from_top:
        filled = mask.copy()
        for x in range(0, filled.width, 8):
            if filled.getpixel((x, 0)) == 255:
                ImageDraw.floodfill(filled, (x, 0), 128)
        sky = filled.point(lambda v: 255 if v == 128 else 0)
        # Le finestre del castello mostrano la scacchiera ma non toccano il bordo:
        # sopra l'orizzonte si toglie anche quella racchiusa, se occupa più di qualche pixel.
        horizon = int(img.height * 0.3)
        enclosed = mask.filter(ImageFilter.MinFilter(5)).filter(ImageFilter.MaxFilter(5))
        top = Image.new("L", mask.size, 0)
        top.paste(enclosed.crop((0, 0, mask.width, horizon)), (0, 0))
        mask = Image.fromarray(np.maximum(np.asarray(sky), np.asarray(top)))
    else:
        # Solo le zone ampie: piccoli riflessi chiari nel legno non sono scacchiera.
        mask = mask.filter(ImageFilter.MinFilter(9)).filter(ImageFilter.MaxFilter(9))
    # Allarga un poco il trasparente per mangiare il bordo chiaro, poi sfuma.
    hole = mask.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(1.2))
    out = img.convert("RGBA")
    out.putalpha(hole.point(lambda v: 255 - v))
    return out


def balustrade_only(img: Image.Image) -> Image.Image:
    """Dal balcone col tavolo tiene solo la balaustra: il tavolo, a tutta larghezza, coprirebbe
    metà della città. Il bordo superiore della balaustra è un arco leggero; sopra si cancella."""
    a = np.asarray(img).astype(float)
    h, w = a.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    crest = 806 + 38 * np.sin(np.pi * xx / (w - 1))
    keep = np.clip((yy - crest + 1) / 3, 0, 1)
    a[:, :, 3] *= keep
    out = Image.fromarray(a.astype(np.uint8), "RGBA")
    return out.crop((0, 790, w, h))


def main() -> None:
    OUT.mkdir(exist_ok=True)

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

    # Livelli per la parallasse: cielo, città senza cielo, balaustra in primo piano.
    Image.open(RAW / "sky.jpg").convert("RGB").save(OUT / "bg_sky.jpg", quality=85)
    checker_key(Image.open(RAW / "city_checker.jpg"), from_top=True).save(OUT / "bg_city.png")
    balustrade_only(checker_key(Image.open(RAW / "balcony_checker.jpg"), from_top=False)).save(OUT / "bg_balcony.png")
    print("emblemi:", circles)


if __name__ == "__main__":
    main()
