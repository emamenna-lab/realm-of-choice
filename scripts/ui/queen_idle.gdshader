shader_type canvas_item;
// La regina viva su un'unica immagine: respiro, mantello mosso dal vento, testa che si volge piano.
// Tutto avviene spostando le coordinate di lettura della texture, senza tagliarla in pezzi.

uniform float breath = 0.006;     // allungamento verticale massimo del respiro
uniform float sway = 0.012;       // ampiezza dell'ondeggiare del mantello, in frazioni di larghezza
uniform vec2 neck = vec2(0.53, 0.165); // perno della testa, in UV
uniform float head_angle = 0.04;  // rotazione massima della testa, in radianti
uniform float aspect = 0.566;     // larghezza / altezza dell'immagine

void fragment() {
	vec2 uv = UV;
	float t = TIME;
	// Respiro: si allunga appena verso l'alto, i piedi restano fermi.
	uv.y = 1.0 - (1.0 - uv.y) / (1.0 + breath * sin(t * 1.6));
	// Mantello: l'onda scende dalle spalle all'orlo e cresce verso il basso.
	float cape = smoothstep(0.3, 1.0, uv.y);
	uv.x += cape * sway * sin(t * 1.1 - uv.y * 4.0);
	// Testa: ruota attorno al collo, lentamente, con una sfumatura sotto il mento.
	float head = 1.0 - smoothstep(neck.y - 0.02, neck.y + 0.03, uv.y);
	float a = head_angle * sin(t * 0.37) * head;
	vec2 d = (uv - neck) * vec2(aspect, 1.0);
	d = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * d;
	uv = neck + d / vec2(aspect, 1.0);
	COLOR = texture(TEXTURE, uv);
}
