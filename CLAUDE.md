# CLAUDE.md — Plataforma de Oficios y Servicios

## Qué es este proyecto

Marketplace móvil geolocalizado de oficios y servicios de cercanía. Conecta clientes que necesitan reparaciones/servicios del hogar con trabajadores independientes (plomeros, electricistas, fleteros, etc.) mediante geolocalización, perfiles validados y un sistema de reputación con reseñas mutuas.

Trabajo Final — Introducción al Desarrollo Móvil 2026.

Equipo: 2 personas.
- **Dev A (líder):** Backend completo (Django) + arquitectura Flutter + pantallas complejas
- **Dev B:** Pantallas de UI en Flutter siguiendo la arquitectura de Dev A

---

## Stack tecnológico definitivo

### Frontend Mobile
- **Framework:** Flutter (Dart)
- **Gestión de estado:** flutter_bloc (patrón BLoC)
- **HTTP Client:** dio
- **Mapas:** google_maps_flutter
- **Geolocalización:** geolocator
- **Fotos:** image_picker
- **Push notifications:** firebase_messaging
- **Storage local:** shared_preferences (para JWT)

### Backend API — Django
- **Framework:** Django 5.x
- **API REST:** Django REST Framework (DRF)
- **Auth:** djangorestframework-simplejwt (JWT)
- **Geoespacial:** GeoDjango (integrado en Django) + PostGIS
- **Upload imágenes:** Pillow + django default storage (o Cloudinary)
- **Panel admin:** django.contrib.admin (incluido, gratis)
- **CORS:** django-cors-headers
- **Variables de entorno:** django-environ
- **Push notifications:** firebase-admin
- **Filtros:** django-filter

### Base de datos
- **Motor:** PostgreSQL 15+ con PostGIS
- **SRID:** 4326 (WGS84, estándar GPS)
- **Django DB backend:** django.contrib.gis.db.backends.postgis

---

## Estructura de carpetas

### Backend (`/api`)
```
api/
├── manage.py
├── requirements.txt
├── .env
├── .env.example
├── config/                    ← proyecto Django (settings, urls, wsgi)
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── users/                     ← app de usuarios y auth
│   ├── __init__.py
│   ├── models.py              ← modelo Usuario custom (AbstractUser)
│   ├── serializers.py
│   ├── views.py
│   ├── urls.py
│   ├── admin.py
│   ├── permissions.py         ← IsCliente, IsTrabajador, IsAdmin
│   └── managers.py            ← UserManager custom
├── oficios/                   ← app de categorías de oficios
│   ├── models.py
│   ├── serializers.py
│   ├── views.py
│   ├── urls.py
│   └── admin.py
├── solicitudes/               ← app de solicitudes + propuestas
│   ├── models.py              ← Solicitud y Propuesta
│   ├── serializers.py
│   ├── views.py
│   ├── urls.py
│   ├── admin.py
│   └── filters.py             ← filtros por categoría, estado, geo
├── resenas/                   ← app de reseñas
│   ├── models.py
│   ├── serializers.py
│   ├── views.py
│   ├── urls.py
│   └── admin.py
└── media/                     ← fotos subidas (dev)
```

### Frontend (`/app`)
```
app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── config/
│   │   └── api_config.dart    ← BASE_URL del backend Django
│   ├── models/
│   │   ├── usuario.dart
│   │   ├── solicitud.dart
│   │   ├── propuesta.dart
│   │   ├── categoria.dart
│   │   └── resena.dart
│   ├── services/
│   │   ├── api_service.dart   ← Dio con interceptor JWT
│   │   ├── auth_service.dart
│   │   ├── solicitud_service.dart
│   │   └── propuesta_service.dart
│   ├── blocs/
│   │   ├── auth/
│   │   ├── solicitudes/
│   │   └── propuestas/
│   ├── screens/
│   │   ├── auth/
│   │   ├── cliente/
│   │   ├── trabajador/
│   │   └── shared/
│   └── widgets/
│       ├── solicitud_card.dart
│       ├── propuesta_card.dart
│       ├── star_rating.dart
│       └── loading_indicator.dart
├── pubspec.yaml
└── README.md
```

---

## Modelo de datos (Django models)

### Usuario (users/models.py) — Extiende AbstractUser
| Campo | Tipo Django | Notas |
|-------|-------------|-------|
| (hereda de AbstractUser) | | username, email, password, first_name, etc. |
| rol | CharField choices=('cliente','trabajador','admin') | NOT NULL |
| foto | ImageField | upload_to='perfiles/', blank=True, null=True |
| telefono | CharField(20) | blank=True, null=True |
| ubicacion | PointField(srid=4326) | GeoDjango, blank=True, null=True |
| verificado | BooleanField | default=False |
| activo | BooleanField | default=True |
| fcm_token | TextField | blank=True, null=True |

### OficioCategoria (oficios/models.py)
| Campo | Tipo Django | Notas |
|-------|-------------|-------|
| nombre | CharField(100) | unique=True |
| icono | CharField(50) | Nombre del ícono |
| descripcion | TextField | blank=True |
| activa | BooleanField | default=True |
| created_at | DateTimeField | auto_now_add=True |

### TrabajadorOficio (users/models.py o oficios/models.py)
- ManyToManyField en Usuario: `oficios = models.ManyToManyField(OficioCategoria, blank=True)`
- Django crea la tabla intermedia automáticamente

### Solicitud (solicitudes/models.py)
| Campo | Tipo Django | Notas |
|-------|-------------|-------|
| titulo | CharField(200) | |
| descripcion | TextField | blank=True |
| foto | ImageField | upload_to='solicitudes/', blank=True, null=True |
| ubicacion | PointField(srid=4326) | GeoDjango |
| estado | CharField choices | default='abierta' |
| cliente | ForeignKey(Usuario) | related_name='solicitudes' |
| trabajador_aceptado | ForeignKey(Usuario) | null=True, blank=True, related_name='trabajos' |
| categoria | ForeignKey(OficioCategoria) | |
| created_at | DateTimeField | auto_now_add=True |
| closed_at | DateTimeField | null=True, blank=True |

### Propuesta (solicitudes/models.py)
| Campo | Tipo Django | Notas |
|-------|-------------|-------|
| solicitud | ForeignKey(Solicitud) | related_name='propuestas' |
| trabajador | ForeignKey(Usuario) | related_name='propuestas_enviadas' |
| precio_estimado | DecimalField(10,2) | |
| mensaje | TextField | blank=True |
| estado | CharField choices | default='pendiente' |
| created_at | DateTimeField | auto_now_add=True |
| Meta: unique_together | (solicitud, trabajador) | |

### Resena (resenas/models.py)
| Campo | Tipo Django | Notas |
|-------|-------------|-------|
| solicitud | ForeignKey(Solicitud) | related_name='resenas' |
| autor | ForeignKey(Usuario) | related_name='resenas_escritas' |
| destinatario | ForeignKey(Usuario) | related_name='resenas_recibidas' |
| puntaje | IntegerField | validators=[1-5] |
| comentario | TextField | blank=True |
| created_at | DateTimeField | auto_now_add=True |
| Meta: unique_together | (solicitud, autor) | |

---

## Máquina de estados

```
ABIERTA → EN_PROGRESO → CERRADA
   ↓            ↓
CANCELADA    CANCELADA
```

Reglas:
- Propuestas solo a solicitudes ABIERTA
- Solo el cliente dueño acepta propuestas
- Al aceptar: solicitud → en_progreso, propuesta → aceptada, demás → rechazada
- Reseñas solo cuando CERRADA
- CERRADA y CANCELADA son finales

---

## API REST — Endpoints

Base: `/api/v1/`
Admin panel: `/admin/` (gratis con Django)
API browsable: DRF genera interfaz web navegable automáticamente

### Auth
- POST /api/v1/auth/register/ → { username, email, password, rol, nombre }
- POST /api/v1/auth/token/ → { email, password } → { access, refresh }
- POST /api/v1/auth/token/refresh/ → { refresh } → { access }
- GET /api/v1/auth/me/ → perfil (Auth)

### Categorías
- GET /api/v1/categorias/ (Auth)
- POST /api/v1/categorias/ (Admin)
- PUT /api/v1/categorias/{id}/ (Admin)
- DELETE /api/v1/categorias/{id}/ (Admin)

### Solicitudes
- GET /api/v1/solicitudes/?lat=&lon=&radio=&categoria= (Auth, filtro geo)
- POST /api/v1/solicitudes/ — multipart (Auth, cliente)
- GET /api/v1/solicitudes/{id}/ (Auth)
- GET /api/v1/solicitudes/mis/ (Auth)
- DELETE /api/v1/solicitudes/{id}/ (Auth, owner/admin)
- POST /api/v1/solicitudes/{id}/cerrar/ (Auth, participante)

### Propuestas
- POST /api/v1/solicitudes/{id}/propuestas/ (Auth, trabajador)
- GET /api/v1/solicitudes/{id}/propuestas/ (Auth, cliente dueño)
- POST /api/v1/propuestas/{id}/aceptar/ (Auth, cliente dueño)
- GET /api/v1/propuestas/mis/ (Auth, trabajador)

### Reseñas
- POST /api/v1/solicitudes/{id}/resenas/ (Auth, participante)
- GET /api/v1/usuarios/{id}/resenas/ (Auth)

### Trabajadores
- GET /api/v1/trabajadores/?lat=&lon=&radio=&oficio= (Auth)
- GET /api/v1/trabajadores/{id}/ (Auth)

---

## Consultas geoespaciales (GeoDjango)

```python
from django.contrib.gis.geos import Point
from django.contrib.gis.measure import D

# Buscar solicitudes dentro de N km
punto = Point(lon, lat, srid=4326)
Solicitud.objects.filter(
    estado='abierta',
    ubicacion__distance_lte=(punto, D(km=radio_km))
).order_by('ubicacion')

# Crear solicitud con ubicación
solicitud = Solicitud.objects.create(
    titulo="Instalar split",
    ubicacion=Point(-65.4120, -24.7821, srid=4326),
    cliente=request.user,
    categoria=categoria,
)
```

---

## Settings de Django relevantes (config/settings.py)

```python
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.gis',          # GeoDjango
    'rest_framework',              # DRF
    'rest_framework_simplejwt',    # JWT
    'corsheaders',                 # CORS para Flutter
    'django_filters',              # Filtros
    # Apps del proyecto
    'users',
    'oficios',
    'solicitudes',
    'resenas',
]

DATABASES = {
    'default': {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'NAME': env('DB_NAME'),
        'USER': env('DB_USER'),
        'PASSWORD': env('DB_PASSWORD'),
        'HOST': env('DB_HOST', default='localhost'),
        'PORT': env('DB_PORT', default='5432'),
    }
}

AUTH_USER_MODEL = 'users.Usuario'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
    ],
}
```

---

## Variables de entorno (.env)

```
SECRET_KEY=django-secret-key-largo-y-random
DEBUG=True
DB_NAME=oficios_db
DB_USER=postgres
DB_PASSWORD=tu_password
DB_HOST=localhost
DB_PORT=5432
ALLOWED_HOSTS=localhost,127.0.0.1
CORS_ALLOWED_ORIGINS=http://localhost:3000
```

---

## requirements.txt

```
Django==5.1.*
djangorestframework==3.15.*
djangorestframework-simplejwt==5.4.*
django-cors-headers==4.6.*
django-environ==0.11.*
django-filter==24.*
Pillow==11.*
psycopg2-binary==2.9.*
firebase-admin==6.6.*
cloudinary==1.41.*
django-cloudinary-storage==0.3.*
```

---

## Datos seed

```python
# Correr con: python manage.py shell < seed.py
# O crear un management command: python manage.py seed_categorias

categorias = [
    ("Plomería", "plumbing", "Caños, grifos, pérdidas, termotanques"),
    ("Electricidad", "electric_bolt", "Instalaciones, cortocircuitos, tableros"),
    ("Gasista", "local_fire_department", "Gas, calefones, estufas"),
    ("Pintura", "format_paint", "Interior, exterior, impermeabilización"),
    ("Albañilería", "construction", "Mampostería, revoques, pisos"),
    ("Fletes", "local_shipping", "Mudanzas, transporte de muebles"),
    ("Limpieza", "cleaning_services", "Hogar, oficinas, vidrios"),
    ("Cerrajería", "lock", "Puertas, cerraduras, copias de llaves"),
    ("Aire acondicionado", "ac_unit", "Instalación, carga de gas, splits"),
    ("Carpintería", "carpenter", "Muebles a medida, puertas, ventanas"),
]
```

---

## Comandos útiles

```bash
# Backend
cd api
pip install -r requirements.txt
python manage.py makemigrations         # Generar migración
python manage.py migrate                # Aplicar a la BD
python manage.py createsuperuser        # Crear admin
python manage.py runserver              # Servidor dev en localhost:8000
# Admin panel en http://localhost:8000/admin/
# API browsable en http://localhost:8000/api/v1/

# Frontend
cd app
flutter pub get
flutter run
flutter build apk
```

---

## Panel admin (GRATIS con Django)

Registrando los modelos en admin.py de cada app, Django genera automáticamente:
- CRUD completo de Categorías de oficios
- Listado y gestión de Usuarios (filtrar por rol, suspender)
- Listado de Solicitudes (filtrar por estado, categoría, fecha)
- Listado de Propuestas
- Listado de Reseñas
- Búsqueda, filtros, paginación, todo incluido

Esto reemplaza TODO el "panel admin web" que teníamos planificado.

---

## Convenciones de código

### Python/Django
- snake_case para variables, funciones, archivos
- PascalCase para clases (modelos, serializers, views)
- Un modelo por app cuando tiene sentido, o agrupar relacionados
- Serializers siempre con campos explícitos (nunca fields = '__all__' en producción)
- Permisos custom en permissions.py de cada app
- Lógica de negocio en el serializer o en el model, no en la view

### Flutter
- snake_case archivos, PascalCase clases
- BLoC por feature
- Widgets reutilizables en /widgets

---

## Notas para Claude Code

- Backend en /api (Django), Frontend en /app (Flutter).
- Stack definitivo: Django 5 + DRF + GeoDjango + SimpleJWT. NO FastAPI, NO SQLAlchemy.
- Migraciones con makemigrations + migrate, como siempre en Django.
- BD engine es django.contrib.gis.db.backends.postgis (NO el default de PostgreSQL).
- AUTH_USER_MODEL = 'users.Usuario' (modelo custom, extiende AbstractUser).
- Fotos como multipart/form-data con ImageField + Pillow.
- Consultas geo con GeoDjango: ubicacion__distance_lte=(punto, D(km=radio)).
- El panel admin ya existe en /admin/, no hay que construirlo.
- DRF genera API browsable automática en el navegador.
- Usar SimpleJWT para auth: /api/v1/auth/token/ devuelve access + refresh.
