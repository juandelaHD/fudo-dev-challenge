# Backend Developer Jr. - Technical Challenge - FUDO

## Autor

**Juan Martín de la Cruz**

- GitHub: [@juandelaHD](https://github.com/juandelaHD)
- Email: juanmartindelacruz03@gmail.com

## Requisitos

- **Docker**: versión 20.10 o superior
- **Docker Compose**: versión 2.0 o superior
- **Git**: para clonar el repositorio

## Instalación

```bash
# 1. Clonar el repositorio
git clone https://github.com/juandelaHD/fudo-dev-challenge.git
cd fudo-dev-challenge

# 2. Configurar variables de entorno
# Copiar el archivo de ejemplo y configurarlo según tus necesidades
cp .env.example .env

# Edita el archivo .env con tus configuraciones
# Ver sección "Configuración de Base de Datos" más abajo
```

## Configuración de Base de Datos

Este proyecto soporta dos modos de ejecución según la variable `RACK_ENV`:

### Modo Development

El entorno `development` levanta una copia local de PostgreSQL dentro de Docker para facilitar desarrollo rápido y pruebas locales.

```bash
# En tu archivo .env
RACK_ENV=development
```

### Modo Production

El entorno `production` conecta la aplicación a una base de datos gestionada (por ejemplo, Supabase) para simular en un entorno en la nube.

```bash
# En tu archivo .env
RACK_ENV=production
DATABASE_URL="postgresql://usuario:password@host:5432/nombre_bd"
```

**NOTA:** Para usar la base de datos hosteada en Supabase del proyecto original, solicita el archivo `.env` o revisa si tienes un correo con el asunto:
_"Variables de entorno - FUDO Challenge - Juan Martín de la Cruz"_

## Usos

### Ejecutar el backend

```bash
# Levantar el servidor API en modo development (con BD local PostgreSQL)
# Asegúrate de tener en tu .env: RACK_ENV=development
docker-compose --profile development up --build

# Levantar el servidor API en modo production (con BD remota)
# Asegúrate de tener en tu .env: RACK_ENV=production y DATABASE_URL configurada
docker-compose --profile production up --build

# El servidor estará disponible en: http://localhost:9292
```

### Gestión de servicios

```bash
# Development (local postgres + app)
# Detener y eliminar containers (la BD local persiste)
docker-compose --profile development down

# Detener y eliminar containers Y la base de datos local (borra volumen)
docker-compose --profile development down -v

# Production (solo app, BD remota)
docker-compose --profile production down
```

### Ejecutar Tests

```bash
# Correr la suite completa de tests
docker-compose -f docker-compose.test.yml up --build
```

Para limpiar la base de datos de tests y empezar desde cero:

```bash
docker-compose -f docker-compose.test.yml down
```

**Nota:** Los tests utilizan una base de datos PostgreSQL local e independiente.
