# parcial_ajlg — Miniaturas de imagen (S3 → Lambda → Fargate → S3)

Parcial 1 · Andres Lopez · Computación en la Nube · `us-east-1`

Generador de miniaturas sobre AWS, desplegado con **Terraform**. Sin ALB, sin API
Gateway, sin Cognito.

## Arquitectura

```
Usuario
  │ 1. abre el sitio estático (bucket público)
  ▼
S3 frontend (sitio web estático)
  │ 2. PUT anónimo de la imagen
  ▼
S3 originales/uploads/*  ──(3. evento s3:ObjectCreated:*)──▶  Lambda parcial_ajlg_trigger
                                                                   │ 4. ecs:RunTask
                                                                   │    (pasa SOURCE_KEY / IMAGE_URI por variable de entorno)
                                                                   ▼
                                                        ECS Fargate (on-demand, SIN service)
                                                         contenedor parcial_ajlg_processor
                                                                   │ 5. GetObject original
                                                                   │    Pillow → miniatura 200 px
                                                                   ▼
                                                        S3 miniaturas/thumbs/*
                                                                   │ 6. galería pública
                                                                   ▼
                                                               Usuario
```

**Puntos clave**

- El contenedor **no corre el 100 % del tiempo**: no hay ECS Service. Solo existe
  durante el `RunTask` que dispara la Lambda y se detiene al terminar.
- La ruta de la imagen llega al contenedor **por variable de entorno**
  (`SOURCE_BUCKET`, `SOURCE_KEY`, `IMAGE_URI`, `DEST_BUCKET`), como pide el enunciado.
- Los buckets son públicos **solo porque es un parcial**: la web estática sube y
  lista sin backend ni credenciales. En producción serían privados + URLs firmadas.

## Estructura

```
.
├── terraform/          infraestructura completa
├── container/          Dockerfile + processor.py (Pillow)
├── lambda/trigger/     handler.py (evento S3 → RunTask)
├── frontend/           index.html, app.js, styles.css (vanilla, sin SDK)
├── scripts/            build_push.sh (docker build + push a ECR)
└── diagrama/           arquitectura .drawio (iconos AWS, VPC/AZ/subnet)
```

## Despliegue

Requisitos: AWS CLI configurado, Terraform ≥ 1.5, Docker.

```bash
terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve
bash scripts/build_push.sh
```

La primera vez, el `apply` crea la task definition apuntando a `:latest` aunque la
imagen todavía no exista. Se sube en el segundo comando.

Abrir el sitio:

```bash
terraform -chdir=terraform output -raw frontend_url
```

## Probar

1. Abrir la URL, subir un `.jpg`.
2. En ~30-90 s aparece en “Miniaturas”.

```bash
# confirmar que el contenedor no está corriendo
aws ecs list-tasks --cluster parcial_ajlg_cluster --desired-status RUNNING

# ver el disparo de la Lambda
aws logs tail /aws/lambda/parcial_ajlg_trigger --follow

# ver el contenedor trabajando
aws logs tail /ecs/parcial_ajlg_thumb_task --follow
```

## Recursos

| Recurso | Nombre |
|---|---|
| Buckets | `parcial-ajlg-originales-<cuenta>`, `parcial-ajlg-miniaturas-<cuenta>`, `parcial-ajlg-frontend-<cuenta>` |
| Lambda | `parcial_ajlg_trigger` |
| ECS | cluster `parcial_ajlg_cluster`, task `parcial_ajlg_thumb_task` (sin service) |
| ECR | `parcial-ajlg-thumb` |
| Roles | `parcial_ajlg_ecs_exec_role`, `parcial_ajlg_ecs_task_role`, `parcial_ajlg_lambda_trigger_role` |
| SG | `parcial_ajlg_fargate_sg` |

## Destruir

```bash
terraform -chdir=terraform destroy -auto-approve
```

Funciona sin pasos manuales: `force_destroy` en buckets y `force_delete` en ECR.

## Si los `.tf` no están junto a `frontend/`

Terraform autodetecta la raíz del proyecto. Si tu layout es distinto:

```bash
terraform -chdir=terraform plan -var="project_root=../ruta/del/proyecto"
```
