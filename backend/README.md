# Backend REST para Ecommerce App

Este backend está implementado en Node.js con Express, SQLite y JWT. Provee autenticación, productos, pedidos y perfil para la aplicación móvil.

## Requisitos

- Node.js 18+ (ya probada con Node 24)
- npm

## Instalación

1. Abre una terminal en `backend`.
2. Instala dependencias:
   ```powershell
   npm install
   ```

## Ejecutar

```powershell
npm start
```

El servidor quedará escuchando en `http://localhost:8000`.

## Uso

- `POST /auth/register` – registro de usuario
- `POST /auth/login` – inicio de sesión
- `POST /auth/forgot-password` – token de recuperación (simulado)
- `POST /auth/reset-password` – restablecer contraseña
- `GET /users/me` – perfil del usuario autenticado
- `POST /users/me` – actualizar perfil
- `POST /users/me/password` – cambiar contraseña
- `GET /products` – lista de productos
- `POST /orders` – crear pedido
- `GET /orders` – historial de pedidos

## Notas

- `db_init.sql` define las tablas y carga productos de ejemplo.
- Si no existe `database.db`, se crea automáticamente al iniciar el servidor.
- El token JWT se envía en el header `Authorization: Bearer <token>`.
