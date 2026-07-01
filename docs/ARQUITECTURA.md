# Arquitectura de la infraestructura — CIPOLFLO (staging)

Este documento explica, en términos simples pero completos, cómo está armada la
infraestructura del proyecto **CIPOLFLO** en AWS. Está centrado en el ambiente
**staging** (producción es prácticamente igual). Cada componente incluye un
"¿qué es?" para entender los términos técnicos.

---

## La idea general

Tu app son dos programas separados: el **frontend** (lo que el usuario ve en el
navegador) y el **backend** (la lógica y los datos, que el frontend consulta).
Cada uno se "empaqueta" y corre en la nube de **AWS**. Toda la nube está
descrita en archivos de **Terraform**.

> **¿Qué es Terraform?** Es una herramienta de "infraestructura como código". En
> vez de crear los recursos a mano clickeando en la consola de AWS, los escribís
> en archivos de texto. Así podés crear, modificar o destruir toda la
> infraestructura con un comando, y queda versionado en git como cualquier
> código.

> **¿Qué es una imagen Docker / contenedor?** Una **imagen** es como una "caja
> sellada" que contiene tu programa más todo lo que necesita para correr
> (sistema, librerías, configuración). Un **contenedor** es esa caja ya en
> ejecución. La ventaja: corre igual en tu compu, en AWS o en cualquier lado,
> sin sorpresas de "en mi máquina andaba".

---

## 1. ¿Dónde viven las imágenes? → ECR

> **¿Qué es ECR (Elastic Container Registry)?** Es un "depósito de imágenes
> Docker" privado dentro de AWS. Pensalo como un Google Drive pero específico
> para guardar tus imágenes de contenedores. Solo tu cuenta puede subir y bajar
> de ahí.

Tenés dos repositorios:

- `cipolflo-backend` → la imagen de tu backend (Spring Boot / Java)
- `cipolflo-frontend` → la imagen de tu frontend

**El flujo:** construís la imagen en tu compu → la subís (`docker push`) a ECR →
AWS la baja desde ahí para ejecutarla. Siempre se usa el tag `:latest` (la
versión "más reciente").

📍 `terraform/modules/ecr/main.tf`

---

## 2. ¿Dónde se ejecutan? → ECS con Fargate

> **¿Qué es ECS (Elastic Container Service)?** Es el "director de orquesta" de
> AWS para contenedores. Vos le decís "quiero 1 contenedor del backend siempre
> corriendo" y ECS se encarga de levantarlo, vigilarlo y, si se cae, volver a
> levantarlo.

> **¿Qué es un cluster?** Es simplemente la **agrupación lógica** donde viven tus
> contenedores. Imaginalo como una "carpeta" o un "espacio de trabajo" que junta
> todos los servicios de tu proyecto bajo un mismo techo. El tuyo se llama
> `cipolflo-staging-cluster`.

> **¿Qué es Fargate?** Es el modo de ECS en el que **no manejás servidores**.
> Normalmente para correr un contenedor necesitarías una máquina virtual
> (encenderla, actualizarla, vigilar que no se llene). Con Fargate, AWS pone esa
> máquina por vos de forma invisible: vos solo te ocupás del contenedor. Más
> simple y sin mantenimiento.

> **¿Qué es una Task Definition?** Es la "receta" del contenedor: qué imagen
> usar, cuánta CPU y memoria, qué puerto abre y qué variables de entorno recibe.
> El **servicio** es lo que toma esa receta y mantiene corriendo la cantidad que
> pediste (en tu caso, 1 de cada uno).

| Servicio     | Imagen                     | Puerto | Dónde corre                          |
| ------------ | -------------------------- | ------ | ------------------------------------ |
| **backend**  | `cipolflo-backend:latest`  | 8080   | Subred **privada** (oculto a internet) |
| **frontend** | `cipolflo-frontend:latest` | 80     | Subred **pública**                   |

📍 `terraform/modules/ecs/main.tf`

---

## 3. La puerta de entrada → ALB y Route53

> **¿Qué es Route53?** Es el servicio de **DNS** de AWS. El DNS es la "agenda de
> contactos" de internet: traduce un nombre lindo
> (`staging.cipolflo.com.uy`) a la dirección técnica real del servidor. Cuando
> alguien escribe tu dominio en el navegador, Route53 lo manda al lugar correcto
> (tu Load Balancer).

> **¿Qué es el ALB (Application Load Balancer)?** Es el "recepcionista" de tu
> app: el único punto por donde entra todo el tráfico de internet. Hace dos
> trabajos clave:
>
> 1. **Maneja el HTTPS/seguridad**: tiene el certificado SSL (el candadito 🔒) y
>    si alguien entra por HTTP lo redirige a HTTPS automáticamente.
> 2. **Reparte el tráfico** según la dirección que pidieron (eso se llama
>    _routing_).

> **¿Qué es un certificado SSL / ACM?** El certificado es lo que habilita el
> `https://` y cifra la comunicación. **ACM (AWS Certificate Manager)** es donde
> AWS lo guarda y renueva gratis.

El camino completo de una petición:

```
Usuario (navegador)
      │  escribe https://staging.cipolflo.com.uy
      ▼
  Route53 (DNS)  →  "ese nombre vive en el Load Balancer"
      ▼
  ALB  [HTTPS 443, con certificado SSL]
      │   ¿qué URL pidió?
      ├── empieza con /api/*  ─────►  Contenedor BACKEND  (puerto 8080)
      │                                    │  consulta/guarda datos
      │                                    ▼
      │                               RDS PostgreSQL (puerto 5432)
      │
      └── cualquier otra cosa  ────►  Contenedor FRONTEND (puerto 80)
```

📍 ALB en `terraform/modules/alb/main.tf`; el ruteo `/api/*` está en la línea 84.
El registro de Route53 está en `terraform/environments/staging/main.tf:76`.

---

## 4. La base de datos → RDS

> **¿Qué es RDS (Relational Database Service)?** Es PostgreSQL pero
> **administrado por AWS**. En vez de instalar y mantener vos la base de datos
> (backups, actualizaciones, etc.), AWS lo hace. Vos solo la usás.

- Motor: **PostgreSQL 15** | Instancia: `cipolflo-staging-db`
- Base: `CIPOLFLO_BD` | Usuario: `admin_staging`
- Vive en las **subredes privadas**: **no es accesible desde internet**, solo el
  backend puede hablarle.

📍 `terraform/modules/rds/main.tf`

---

## 5. La red → VPC, subredes, NAT, Security Groups

> **¿Qué es una VPC (Virtual Private Cloud)?** Es **tu red privada propia**
> dentro de AWS, aislada de las redes de los demás. Como tener tu propio
> "edificio" donde ubicás todas tus piezas y controlás quién entra y sale.

> **¿Qué son las subredes (subnets)?** Son "divisiones" dentro de tu red. Tenés
> dos tipos:
>
> - **Públicas**: tienen contacto directo con internet. Acá va el Load Balancer
>   y el frontend.
> - **Privadas**: no son alcanzables desde internet. Acá van el backend y la base
>   de datos (lo más sensible).
>
> Hay 2 de cada tipo, repartidas en dos **zonas de disponibilidad** (dos centros
> de datos físicos distintos), para que si una falla, la otra siga funcionando.

> **¿Qué es un Internet Gateway?** La "puerta principal" que conecta tus
> subredes **públicas** con internet (entrada y salida).

> **¿Qué es un NAT Gateway?** Una "puerta de salida de un solo sentido" para las
> subredes **privadas**. Permite que el backend salga a internet (por ejemplo, a
> bajar su imagen de ECR), pero **nadie de afuera puede entrar** por ahí.
> Seguridad sin aislamiento total.

> **¿Qué es un Security Group?** Es un **firewall** (cortafuegos) por cada pieza:
> define qué tráfico se permite. Tus reglas forman capas de seguridad:
>
> - Internet → **ALB**: solo puertos 80 y 443.
> - **ALB → contenedores**: solo el ALB puede entrarles, nadie más.
> - **contenedores → RDS**: solo los contenedores pueden hablarle a la base
>   (puerto 5432).

📍 `terraform/modules/networking/main.tf`

---

## 6. Qué consume cada parte (variables y servicios externos)

**Backend** recibe: la conexión a la base (URL, usuario, contraseña), el perfil
de Spring (`docker`), credenciales de **Auth0** y la config de **CORS**.

**Frontend** recibe: datos de **Auth0** (domain, client_id, audience) y la
`BACKEND_URL`.

> **¿Qué es Auth0?** Un servicio **externo** (no es de AWS) que maneja el
> **login y la identidad** de los usuarios por vos: registro, contraseñas,
> tokens. Tu front y tu back se apoyan en él para saber "quién es este usuario y
> puede hacer esto".

> **¿Qué es CORS?** Una regla de seguridad de los navegadores. Le dice al backend
> "solo aceptá pedidos que vengan desde tu propio dominio"
> (`staging.cipolflo.com.uy`), para que sitios ajenos no usen tu API.

> **¿Qué es CloudWatch?** El servicio de **logs y monitoreo** de AWS. Todo lo que
> imprimen tus contenedores queda guardado ahí (en tu caso, 7 días) para que
> puedas revisar errores. Grupos: `/ecs/cipolflo-staging-backend` y `-frontend`.

---

## 7. Desarrollo local → docker-compose

> **¿Qué es docker-compose?** Una forma de levantar **varios contenedores juntos
> en tu propia compu** con un solo comando (`docker compose up`). Sirve para
> desarrollar sin gastar ni depender de AWS.

Levanta lo mismo localmente: Postgres + backend + frontend, leyendo las
variables de un archivo `.env`. La única diferencia importante: la base de datos
es un contenedor local, no RDS.

---

## En una frase

> Empaquetás front y back como imágenes Docker → las guardás en **ECR** → corren
> como contenedores sin servidor en un **cluster de ECS/Fargate** → **Route53**
> dirige tu dominio al **ALB**, que los expone con HTTPS y manda `/api/*` al
> backend y el resto al frontend → el backend guarda datos en **RDS
> PostgreSQL** → todo encerrado en una **VPC** con subredes públicas/privadas,
> firewalls (**security groups**) y **Auth0** para el login.
