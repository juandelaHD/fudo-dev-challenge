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
# Colocar el archivo .env dentro de la carpeta del proyecto (dentro de `fudo-dev-challenge`).

# NOTA: Dado que la base de datos está hosteada en Supabase, el archivo .env será enviado por correo a quien corresponda con el asunto: 
# "Variables de entorno - FUDO Challenge - Juan Martín de la Cruz" 
```

## Usos

### Ejecutar el backend

```bash
# Levantar el servidor API
docker-compose up --build

# El servidor estará disponible en: http://localhost:9292
# Health check: http://localhost:9292/v1/health
```

Para detener los servicios:

```bash
docker-compose down
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
