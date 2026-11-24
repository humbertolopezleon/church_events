"""Genera los íconos de Mi Evento (Android y Windows) a partir del logotipo del diseño aprobado:
dos círculos que se tocan (blanco y naranja) sobre azul Esperanza, con una base blanca.
Uso:  python3 tools/make_icons.py   (requiere Pillow)"""
from PIL import Image, ImageDraw
import os

BLUE, ORANGE, WHITE = (29, 78, 137), (224, 122, 46), (255, 255, 255)
RES = 'android/app/src/main/res'
SS = 4  # supersampling para bordes suaves


def logo(size, rounded=True, glyph_scale=1.0):
    """Dibuja el logotipo en una cuadrícula de 72 unidades (como el SVG del diseño)."""
    s = size * SS
    u = s / 72.0
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if rounded:
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=20 * u, fill=BLUE)
    else:
        d.rectangle([0, 0, s, s], fill=BLUE)
    c = s / 2.0

    def pt(x, y):  # escala el glifo alrededor del centro
        return (c + (x * u - c) * glyph_scale, c + (y * u - c) * glyph_scale)

    r, w = 11 * u * glyph_scale, 5 * u * glyph_scale
    for cx, color in ((28, WHITE), (44, ORANGE)):
        x, y = pt(cx, 32)
        d.ellipse([x - r - w / 2, y - r - w / 2, x + r + w / 2, y + r + w / 2], outline=color, width=int(w))
    (x1, y1), (x2, y2) = pt(20, 54), pt(52, 54)
    d.line([x1, y1, x2, y2], fill=WHITE, width=int(w))
    for x, y in ((x1, y1), (x2, y2)):
        d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=WHITE)
    return img.resize((size, size), Image.LANCZOS)


# Windows: .ico con varios tamaños
os.makedirs('windows/runner/resources', exist_ok=True)
logo(256).save('windows/runner/resources/app_icon.ico', sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])

# Android: PNG heredados (mismo logotipo, cuadrado) para launchers que no usan el adaptativo
for folder, px in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
    p = f'{RES}/mipmap-{folder}/ic_launcher.png'
    logo(px, rounded=True).save(p)

# Android 8+ (minSdk 26): ícono adaptativo = fondo azul + glifo vectorial en la zona segura
os.makedirs(f'{RES}/mipmap-anydpi-v26', exist_ok=True)
os.makedirs(f'{RES}/drawable', exist_ok=True)
open(f'{RES}/values/ic_launcher_background.xml', 'w').write(
    '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">#1D4E89</color>\n</resources>\n')
open(f'{RES}/mipmap-anydpi-v26/ic_launcher.xml', 'w').write(
    '<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@color/ic_launcher_background"/>\n'
    '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n</adaptive-icon>\n')


def circle(cx, cy, r):
    return f'M{cx - r},{cy} a{r},{r} 0 1,0 {2 * r},0 a{r},{r} 0 1,0 {-2 * r},0'


# Lienzo de 108 dp; el glifo (cuadrícula de 72) se escala 0.95 y se centra: queda dentro de los 66 dp seguros.
k, ox, oy = 0.95, 54 - 36 * 0.95, 54 - 36 * 0.95
def T(x, y): return (round(ox + x * k, 2), round(oy + y * k, 2))
rr, ww = round(11 * k, 2), round(5 * k, 2)
(cx1, cy1), (cx2, cy2) = T(28, 32), T(44, 32)
(bx1, by1), (bx2, by2) = T(20, 54), T(52, 54)
open(f'{RES}/drawable/ic_launcher_foreground.xml', 'w').write(f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:pathData="{circle(cx1, cy1, rr)}" android:strokeColor="#FFFFFF" android:strokeWidth="{ww}" android:fillColor="#00000000"/>
    <path android:pathData="{circle(cx2, cy2, rr)}" android:strokeColor="#E07A2E" android:strokeWidth="{ww}" android:fillColor="#00000000"/>
    <path android:pathData="M{bx1},{by1} L{bx2},{by2}" android:strokeColor="#FFFFFF" android:strokeWidth="{ww}" android:strokeLineCap="round"/>
</vector>
''')

print('íconos generados')
