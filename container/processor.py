"""parcial_ajlg — procesador de miniaturas (corre en ECS Fargate).

Contrato con la Lambda (requisito de la materia):
  La Lambda activa este contenedor vía ecs:RunTask y le pasa la ruta
  de la imagen POR VARIABLE DE ENTORNO:
    SOURCE_BUCKET : bucket origen (parcial-ajlg-originales-*)
    SOURCE_KEY    : key del objeto subido (p.ej. uploads/foto.jpg)
    DEST_BUCKET   : bucket destino (parcial-ajlg-miniaturas-*)
    THUMB_SIZE    : lado mayor del thumbnail en px (default 200)
    DEST_PREFIX   : prefijo en destino (default "thumbs/")
    IMAGE_URI     : alias opcional "s3://bucket/key" (si viene, se usa)

Flujo: GetObject origen -> Pillow thumbnail -> PutObject destino.
"""
import io
import logging
import os
import sys
import urllib.parse

import boto3
from botocore.exceptions import ClientError
from PIL import Image, UnidentifiedImageError

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger("parcial_ajlg_processor")


def resolve_source():
    """Lee SOURCE_BUCKET/SOURCE_KEY o el alias IMAGE_URI."""
    image_uri = os.environ.get("IMAGE_URI", "").strip()
    if image_uri.startswith("s3://"):
        no_scheme = image_uri[5:]
        bucket, _, key = no_scheme.partition("/")
        return bucket, urllib.parse.unquote_plus(key)
    bucket = os.environ.get("SOURCE_BUCKET", "").strip()
    key = urllib.parse.unquote_plus(os.environ.get("SOURCE_KEY", "").strip())
    if not bucket or not key:
        raise ValueError(
            "Faltan variables: define SOURCE_BUCKET + SOURCE_KEY o IMAGE_URI=s3://bucket/key"
        )
    return bucket, key


def main() -> int:
    try:
        src_bucket, src_key = resolve_source()
    except ValueError as e:
        log.error(str(e))
        return 2

    dest_bucket = os.environ.get("DEST_BUCKET", "").strip()
    if not dest_bucket:
        log.error("Falta variable DEST_BUCKET")
        return 2
    try:
        size = int(os.environ.get("THUMB_SIZE", "200"))
    except ValueError:
        size = 200
    prefix = os.environ.get("DEST_PREFIX", "thumbs/")
    filename = src_key.rsplit("/", 1)[-1] or "imagen"
    dest_key = f"{prefix}thumb-{filename}"

    log.info("Origen: s3://%s/%s -> Destino: s3://%s/%s (size=%d)",
             src_bucket, src_key, dest_bucket, dest_key, size)

    s3 = boto3.client("s3")
    try:
        obj = s3.get_object(Bucket=src_bucket, Key=src_key)
        raw = obj["Body"].read()
        content_type = obj.get("ContentType", "image/jpeg")
    except ClientError as e:
        log.error("No se pudo descargar el original: %s", e)
        return 3

    try:
        with Image.open(io.BytesIO(raw)) as img:
            img = img.convert("RGB")
            img.thumbnail((size, size))
            buf = io.BytesIO()
            fmt = "PNG" if filename.lower().endswith(".png") else "JPEG"
            img.save(buf, fmt)
            buf.seek(0)
            out_ct = "image/png" if fmt == "PNG" else "image/jpeg"
            s3.put_object(Bucket=dest_bucket, Key=dest_key,
                          Body=buf.getvalue(), ContentType=out_ct or content_type)
    except UnidentifiedImageError:
        log.error("El objeto no es una imagen válida: %s", src_key)
        return 4
    except ClientError as e:
        log.error("No se pudo subir la miniatura: %s", e)
        return 3

    log.info("OK miniatura: s3://%s/%s", dest_bucket, dest_key)
    return 0


if __name__ == "__main__":
    sys.exit(main())
