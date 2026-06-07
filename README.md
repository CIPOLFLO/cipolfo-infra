# cipolfo-infra
Infraestructura de despliegue de los repositorios de back y front

# CIPOLFLO — Infraestructura

Este repositorio contiene la infraestructura del proyecto CIPOLFLO, incluyendo el `docker-compose.yml` para desarrollo local y los archivos de Terraform para el despliegue en AWS.

---

## Requisitos previos

### 1. Docker Desktop
Instalalo desde https://www.docker.com/products/docker-desktop

### 2. WSL (Windows Subsystem for Linux) con Ubuntu
Abrí PowerShell como administrador y corré:
```bash
wsl --install
```
Reiniciá la PC. Al abrir Ubuntu por primera vez te va a pedir crear un usuario y contraseña, recordalos.

Una vez instalado, habilitá la integración de Docker con WSL:
- Abrí Docker Desktop → Settings → Resources → WSL Integration
- Habilitá el toggle de **Ubuntu**
- Hacé click en **Apply & Restart**

### 3. AWS CLI (en WSL Ubuntu)
Abrí una terminal de Ubuntu y corré:
```bash
sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg < <(wget -qO- https://apt.releases.hashicorp.com/gpg)

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install terraform -y
```

Verificá que instaló correctamente:
```bash
terraform --version
```

### 4. Terraform (en WSL Ubuntu)
```bash
sudo apt update && sudo apt install terraform -y
```

Verificá:
```bash
terraform --version
```

---

## Configurar credenciales de AWS

### Obtener las credenciales
1. Entrá a tu cuenta de AWS Educate/Academy
2. Hacé click en **AWS Details** o **AWS CLI Access**
3. Copiá los tres valores: `AWS Access Key ID`, `AWS Secret Access Key` y `AWS Session Token`

### Configurar el CLI
Desde **WSL Ubuntu**:
```bash
aws configure
```
Completá los campos:
```
AWS Access Key ID: <tu valor>
AWS Secret Access Key: <tu valor>
Default region name: us-east-1
Default output format: json
```

Luego agregá el Session Token:
```bash
aws configure set aws_session_token <tu session token>
```

Verificá que funciona:
```bash
aws sts get-caller-identity
```
Debería mostrarte tu Account ID y nombre de usuario.

> **Importante:** Las credenciales de AWS Educate vencen cada cierto tiempo. Cuando veas errores de autenticación, repetí este paso con las nuevas credenciales.

---

## Crear el bucket de Terraform (solo la primera vez)

Cada integrante crea su propio bucket S3 para guardar el estado de Terraform. Reemplazá `tu-nombre` con tu nombre o alias.

Desde **WSL Ubuntu**:
```bash
aws s3api create-bucket \
  --bucket cipolflo-terraform-state-tu-nombre \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket cipolflo-terraform-state-tu-nombre \
  --versioning-configuration Status=Enabled
```

---

## Desplegar la infraestructura

### Inicializar Terraform (solo la primera vez o al cambiar el backend)

Desde **WSL Ubuntu**, navegá al ambiente que querés desplegar:

**Staging:**
```bash
cd /ruta/al/repo/cipolfo-infra/terraform/environments/staging
terraform init -backend-config="bucket=cipolflo-terraform-state-tu-nombre"
```

**Producción:**
```bash
cd /ruta/al/repo/cipolfo-infra/terraform/environments/production
terraform init -backend-config="bucket=cipolflo-terraform-state-tu-nombre"
```

### Ver qué va a crear
```bash
terraform plan
```

### Aplicar la infraestructura
```bash
terraform apply
```
Escribí `yes` cuando te pida confirmación.

---

## Subir imágenes a ECR

Antes de subir imágenes necesitás autenticarte con ECR. Reemplazá `TU_ACCOUNT_ID` con tu Account ID de AWS.

Desde **WSL Ubuntu**:
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

Luego taguear y subir el backend:
```bash
docker tag cipolflo-server-backend:latest TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cipolflo-backend:latest
docker push TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cipolflo-backend:latest
```

Y el frontend:
```bash
docker tag cipolflo-frontend:latest TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cipolflo-frontend:latest
docker push TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cipolflo-frontend:latest
```

---

## Levantar el ambiente local

Asegurate de tener un archivo `.env` en la raíz del repo con los valores correspondientes (copiá `.env.example` y completá los valores).

Desde **PowerShell en Windows** o **WSL Ubuntu**, navegá a la raíz del repo y corré:
```bash
docker compose up
```

Para bajar los contenedores:
```bash
docker compose down
```

Para bajar y eliminar los volúmenes (base de datos incluida):
```bash
docker compose down -v
```

---

## Destruir la infraestructura

Cuando no vayas a usar el ambiente, destruí todo para no consumir créditos.

Desde **WSL Ubuntu**, navegá al ambiente correspondiente y corré:
```bash
terraform destroy
```
Escribí `yes` cuando te pida confirmación.

Esto elimina todos los recursos de AWS incluyendo los repositorios ECR y las imágenes. La próxima vez que quieras levantar todo, repetí los pasos de **Desplegar la infraestructura** y **Subir imágenes a ECR**.

---

## Variables de entorno

Copiá el archivo `.env.example` en la raíz del repo y creá tu propio `.env` con los valores reales:

| Variable | Descripción |
|---|---|
| `POSTGRES_USER` | Usuario de PostgreSQL |
| `POSTGRES_PASSWORD` | Contraseña de PostgreSQL |
| `POSTGRES_DB` | Nombre de la base de datos |
| `DB_USERNAME` | Usuario para Spring Boot (igual a POSTGRES_USER) |
| `DB_PASSWORD` | Contraseña para Spring Boot (igual a POSTGRES_PASSWORD) |
| `AUTH0_ISSUER_URI` | URI del issuer de Auth0 (con https:// y / al final) |
| `AUTH0_AUDIENCE` | Audience de Auth0 |
| `AUTH0_DOMAIN` | Dominio de Auth0 (sin https://) |
| `AUTH0_CLIENT_ID` | Client ID de Auth0 |

> El archivo `.env` está en `.gitignore` y nunca debe commitearse al repositorio.