# Documento Tecnico - Mercado Movil

## 1. Resumen

Mercado Movil es una aplicacion movil de e-commerce desarrollada con Flutter y un backend REST propio en Node.js. La app permite registrar usuarios, iniciar sesion, consultar un catalogo de prendas de vestir, buscar y filtrar productos, ver detalle de producto, administrar carrito, realizar pedidos y consultar historial.

El backend usa Express como servidor HTTP, SQLite como base de datos local y JWT para autenticar rutas privadas. Los productos se sincronizan desde FakeStore API, filtrando solo prendas de vestir.

## 2. Alcance Funcional

- Registro e inicio de sesion de usuarios.
- Persistencia de sesion con `shared_preferences`.
- Perfil de usuario autenticado.
- Recuperacion y cambio de contrasena.
- Catalogo de productos consumido por API REST.
- Busqueda por titulo, descripcion y categoria.
- Filtros dinamicos por categorias reales recibidas desde la API.
- Detalle de producto.
- Carrito con cantidades.
- Creacion de pedidos.
- Historial de pedidos por usuario.
- Rutas de inspeccion para revisar datos guardados.

## 3. Tecnologias

### Frontend

- Flutter SDK con Dart.
- Provider para inyeccion de dependencias y estado.
- HTTP para consumo REST.
- Shared Preferences para guardar token y usuario.
- Material 3 para la interfaz.

### Backend

- Node.js.
- Express.
- SQLite.
- bcryptjs para hash de contraseñas.
- jsonwebtoken para tokens JWT.
- cors para permitir consumo desde la app.

### API externa

- FakeStore API: `https://fakestoreapi.com/products`.

## 4. Estructura del Proyecto

```text
ecommerce_app/
  lib/
    core/
      api_client.dart
    models/
      product.dart
      user.dart
      cart_item.dart
      order.dart
    screens/
      catalog_screen.dart
      product_detail_screen.dart
      cart_screen.dart
      checkout_screen.dart
      login_screen.dart
      register_screen.dart
      profile_screen.dart
      order_history_screen.dart
    services/
      auth_service.dart
      product_service.dart
    state/
      auth_controller.dart
      cart_controller.dart
    widgets/
      product_card.dart
    main.dart
  backend/
    index.js
    db_init.sql
    package.json
  test/
    widget_test.dart
```

## 5. Arquitectura General

La aplicacion esta separada en dos capas principales:

```text
Flutter App
  |
  | HTTP JSON
  v
Backend Express
  |
  | SQL
  v
SQLite database.db

Backend Express
  |
  | Sincronizacion al iniciar
  v
FakeStore API
```

### Frontend

`main.dart` inicializa:

- `ApiClient` con `API_BASE_URL`.
- `AuthService`.
- `AuthController`.
- `ProductService`.
- `CartController`.
- Providers globales.

El valor por defecto de la API es:

```text
http://localhost:8000
```

Puede cambiarse al compilar:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

### Backend

`backend/index.js` realiza:

- Inicializacion de SQLite desde `db_init.sql` cuando no existe `database.db`.
- Sincronizacion de productos desde FakeStore API al arrancar.
- Normalizacion de productos externos.
- Registro, login y gestion de perfil.

## 6. Modelo de Datos

### users

| Campo | Tipo | Descripcion |
| --- | --- | --- |
| id | INTEGER | Identificador autoincremental |
| first_name | TEXT | Nombre |
| last_name | TEXT | Apellido |
| username | TEXT | Usuario unico |
| email | TEXT | Correo unico |
| password_hash | TEXT | Hash de contrasena |
| avatar_url | TEXT | URL del avatar |

### password_resets

| Campo | Tipo | Descripcion |
| --- | --- | --- |
| id | INTEGER | Identificador autoincremental |
| email | TEXT | Correo asociado |
| token | TEXT | Token temporal |
| expires_at | TEXT | Fecha de expiracion |

### products

| Campo | Tipo | Descripcion |
| --- | --- | --- |
| id | INTEGER | ID del producto |
| title | TEXT | Nombre normalizado |
| description | TEXT | Descripcion normalizada |
| price | REAL | Precio |
| category | TEXT | Categoria interna |
| image_url | TEXT | Imagen del producto |
| rating | REAL | Calificacion |

### orders

| Campo | Tipo | Descripcion |
| --- | --- | --- |
| id | INTEGER | Identificador autoincremental |
| user_id | INTEGER | Usuario dueno del pedido |
| date | TEXT | Fecha del pedido |
| status | TEXT | Estado |
| subtotal | REAL | Subtotal |
| tax | REAL | Impuesto |
| shipping | REAL | Envio |
| total | REAL | Total |

### order_items

| Campo | Tipo | Descripcion |
| --- | --- | --- |
| id | INTEGER | Identificador autoincremental |
| order_id | INTEGER | Pedido relacionado |
| product_id | INTEGER | Producto relacionado |
| quantity | INTEGER | Cantidad |
| price | REAL | Precio unitario |

## 8. Endpoints REST

### Estado del servidor

```http
GET /
```

Devuelve un resumen de endpoints disponibles.

### Autenticacion

```http
POST /auth/register
```

Body:

```json
{
  "first_name": "Ana",
  "last_name": "Lopez",
  "username": "ana",
  "email": "ana@example.com",
  "password": "123456"
}
```

```http
POST /auth/login
```

Body:

```json
{
  "email": "ana@example.com",
  "password": "123456"
}
```

Respuesta:

```json
{
  "token": "jwt",
  "user": {
    "id": 1,
    "first_name": "Ana",
    "last_name": "Lopez",
    "username": "ana",
    "email": "ana@example.com",
    "avatar_url": "https://..."
  }
}
```

Tambien existen rutas GET para pruebas:

```http
GET /auth/register?first_name=...&last_name=...&username=...&email=...&password=...
GET /auth/login?email=...&password=...
```

### Usuarios

```http
GET /users/me
```

Requiere header:

```http
Authorization: Bearer <token>
```

```http
POST /users/me
POST /users/me/password
```

Rutas de inspeccion:

```http
GET /users
GET /get/users
```

Estas rutas listan usuarios sin devolver `password_hash`.

### Productos

```http
GET /products
GET /get/products
```

Devuelven productos guardados en SQLite, filtrados a categorias de prendas.

### Pedidos

```http
POST /orders
GET /orders
```

Ambas rutas requieren token. `GET /orders` devuelve solo pedidos del usuario autenticado.

Ruta de inspeccion:

```http
GET /get/orders
```

Devuelve todos los pedidos guardados con sus items.

## 9. Flujo de Autenticacion

1. El usuario se registra o inicia sesion.
2. El backend valida credenciales.
3. El backend devuelve `token` JWT y datos publicos del usuario.
4. `AuthController` guarda token y usuario en `shared_preferences`.
5. `ApiClient` agrega el header `Authorization`.
6. Al abrir la app nuevamente, `restoreSession` restaura la sesion local.

## 10. Flujo de Compra

1. `CatalogScreen` consulta `ProductService.fetchProducts`.
2. `ProductService` llama `GET /products`.
3. El usuario filtra, busca y abre productos.
4. `CartController` administra cantidades en memoria.
5. En checkout se llama `ProductService.createOrder`.
6. El backend guarda un registro en `orders` y registros relacionados en `order_items`.
7. El historial consulta `GET /orders`.

## 11. Instalacion y Ejecucion

### Backend

```powershell
cd backend
npm install
npm start
```

Servidor:

```text
http://localhost:8000
```

Si el puerto esta ocupado:

```powershell
Get-NetTCPConnection -LocalPort 8000 | Select-Object OwningProcess
Stop-Process -Id <PID>
npm start
```

O ejecutar en otro puerto:

```powershell
$env:PORT=8001
npm start
```

### Flutter

```powershell
flutter pub get
flutter run
```

Con URL de API explicita:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

## 12. Validacion

Comandos recomendados:

```powershell
node --check backend\index.js
flutter test
flutter analyze
```

Estado conocido:

- `node --check backend\index.js` valida sintaxis del backend.
- `flutter test` valida el catalogo y filtros principales.
- `flutter analyze` puede mostrar avisos informativos existentes de Flutter, como usos de APIs deprecadas o contexto despues de operaciones asincronas.

## 13. Seguridad y Consideraciones

- Las contrasenas se guardan como hash con bcrypt.
- Las rutas privadas usan JWT.
- Las rutas `/get/users`, `/users`, `/get/products` y `/get/orders` son utiles para depuracion local, pero no deberian quedar publicas en produccion sin autenticacion administrativa.
- El valor `JWT_SECRET` deberia configurarse por variable de entorno en produccion.
- La base de datos `database.db` es local y no debe versionarse si contiene datos reales.