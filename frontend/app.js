// parcial_ajlg — web 100% estática, sin SDK ni credenciales.
// Los buckets son públicos (solo para el parcial): subida con PUT anónimo
// y galería leyendo el listado XML público de S3.
const $ = (id) => document.getElementById(id);
const cfg = window.PARCIAL_AJLG;
const url = (bucket, key) => `https://${bucket}.s3.amazonaws.com/${key.split("/").map(encodeURIComponent).join("/")}`;

$("btn").onclick = async () => {
  const f = $("file").files[0];
  if (!f) return ($("status").textContent = "Elige una imagen primero.");
  const key = "uploads/" + f.name;
  try {
    $("status").textContent = "Subiendo a S3 originales: " + key;
    const r = await fetch(url(cfg.srcBucket, key), {
      method: "PUT", body: f,
      headers: { "Content-Type": f.type || "image/jpeg" },
    });
    if (!r.ok) throw new Error("PUT " + r.status);
    $("status").textContent = "✔ Subida OK. Lambda activa el contenedor y genera la miniatura (~30-90s).";
    setTimeout(refresh, 20000);
  } catch (e) { $("status").textContent = "✖ " + (e.message || e); }
};

function card(bucket, key) {
  const d = document.createElement("div");
  const link = url(bucket, key);
  const img = document.createElement("img");
  img.src = link; img.loading = "lazy";
  const a = document.createElement("a");
  a.href = link; a.target = "_blank"; a.textContent = key;
  d.append(img, a);
  return d;
}

async function list(bucket, prefix) {
  const r = await fetch(`https://${bucket}.s3.amazonaws.com/?list-type=2&prefix=${encodeURIComponent(prefix)}`);
  if (!r.ok) throw new Error("list " + r.status);
  const xml = new DOMParser().parseFromString(await r.text(), "application/xml");
  return [...xml.getElementsByTagName("Key")]
    .map((k) => k.textContent)
    .filter((k) => !k.endsWith("/"));
}

async function refresh() {
  try {
    const [orig, thumbs] = await Promise.all([
      list(cfg.srcBucket, "uploads/"),
      list(cfg.dstBucket, "thumbs/"),
    ]);
    $("orig").replaceChildren(...orig.map((k) => card(cfg.srcBucket, k)));
    $("thumbs").replaceChildren(...thumbs.map((k) => card(cfg.dstBucket, k)));
    $("status").textContent = `Originales: ${orig.length} · Miniaturas: ${thumbs.length}`;
  } catch (e) { $("status").textContent = "✖ " + (e.message || e); }
}
$("refresh").onclick = refresh;
refresh();
