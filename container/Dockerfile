# parcial_ajlg — imagen del contenedor de miniaturas (ECS Fargate)
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    THUMB_SIZE=200 \
    DEST_PREFIX=thumbs/

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY processor.py .

# Las variables SOURCE_BUCKET / SOURCE_KEY / DEST_BUCKET / IMAGE_URI
# las inyecta la Lambda parcial_ajlg_trigger vía ecs:RunTask (overrides).
CMD ["python", "processor.py"]
