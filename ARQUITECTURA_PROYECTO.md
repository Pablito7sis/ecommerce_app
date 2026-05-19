# 🏗️ ARQUITECTURA DEL PROYECTO - Explicación Completa

---

## 1️⃣ ARQUITECTURA GENERAL

```
┌─────────────────────────────────────────────────────────────┐
│                      FLUTTER APP (Mobile)                   │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              AuthGate (Main.dart)                      │ │
│  │  ¿Está autenticado? → HomeShell / LoginScreen          │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              State Management (Provider)                │ │
│  │  • AuthController    (login/logout)                    │ │
│  │  • CartController    (carrito)                         │ │
│  │  • ProductService    (productos)                       │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │           Storage (SharedPreferences)                  │ │
│  │  Token JWT + User data (persiste entre reinicios)      │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                            ↑
                            │ HTTP JSON
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    NODE.JS EXPRESS API                      │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │        Authentication Middleware                        │ │
│  │  • Valida JWT en cada petición                         │ │
│  │  • Extrae user_id del token                            │ │
│  │  • Retorna 401 si no es válido                         │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Express Routes                            │ │
│  │  • POST /auth/login         → Validar credenciales     │ │
│  │  • POST /auth/register      → Crear usuario            │ │
│  │  • GET /users/me            → Perfil (protegido)       │ │
│  │  • POST /users/me           → Actualizar perfil        │ │
│  │  • GET /products            → Listar productos         │ │
│  │  • POST /orders             → Crear orden (protegido)  │ │
│  │  • GET /orders              → Mis órdenes (protegido)  │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
                          SQL
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    SQLITE DATABASE                          │
│                                                              │
│  Tablas:                                                     │
│  • users           (email, password_hash, etc)              │
│  • products        (title, price, category, etc)            │
│  • orders          (user_id, date, total, etc)              │
│  • order_items     (order_id, product_id, quantity)         │
│  • password_resets (email, token, expires_at)              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 2️⃣ FLUJO DE AUTENTICACIÓN

```
┌──────────────────────────────────────────────────────────────┐
│ 1️⃣ USUARIO ABRE APP                                          │
└──────────────────────────────────────────────────────────────┘
                            ↓
         main.dart ejecuta authController.restoreSession()
                            ↓
        ¿Hay token en SharedPreferences?
         /                                  \
       SÍ                                   NO
        ↓                                    ↓
  Restaura token                    AuthGate muestra
  y usuario                          LoginScreen
        ↓
  HomeShell


┌──────────────────────────────────────────────────────────────┐
│ 2️⃣ USUARIO HACE LOGIN                                        │
└──────────────────────────────────────────────────────────────┘
                            ↓
    Usuario ingresa email/password
                            ↓
    Formulario valida:
    • Email no vacío
    • Contraseña no vacía y >= 6 caracteres
                            ↓
    Click "Iniciar sesión"
                            ↓
    authController.login(email, password)
                            ↓
    AuthService llama: POST /auth/login
                            ↓
    Backend:
    • Busca usuario por email O username
    • Compara password con bcrypt.compareSync()
    • Si OK: genera JWT con jwt.sign()
    • Retorna: { token, user }
                            ↓
    _applyAuthPayload() guarda:
    • En memoria: _token, _user
    • En disco: SharedPreferences
    • En cliente HTTP: header Authorization: Bearer <token>
                            ↓
    notifyListeners() → AuthGate se actualiza → HomeShell


┌──────────────────────────────────────────────────────────────┐
│ 3️⃣ USUARIO NAVEGA POR LA APP                                 │
└──────────────────────────────────────────────────────────────┘
                            ↓
    Cada petición al backend incluye:
    Header: Authorization: Bearer eyJhbGciOiJIUzI1NiI...
                            ↓
    Backend recibe petición → authMiddleware:
    • Extrae token del header
    • Verifica firma con jwt.verify()
    • Si válido: agrega req.userId
    • Si no: retorna 401 Unauthorized
                            ↓
    Ruta protegida accede a req.userId


┌──────────────────────────────────────────────────────────────┐
│ 4️⃣ USUARIO HACE LOGOUT                                       │
└──────────────────────────────────────────────────────────────┘
                            ↓
    authController.logout()
                            ↓
    _token = null
    _user = null
    apiClient.setToken(null)
    SharedPreferences.remove('auth_token')
    notifyListeners()
                            ↓
    AuthGate → LoginScreen
```

---

## 3️⃣ FLUJO DE CARRITO DE COMPRAS

```
┌──────────────────────────────────────────────────────────────┐
│ USUARIO AGREGA PRODUCTOS                                     │
└──────────────────────────────────────────────────────────────┘

CatalogScreen / ProductDetailScreen
                ↓
        usuario clickea "Agregar al carrito"
                ↓
    cartController.add(product, quantity=1)
                ↓
    CartController:
    • Busca product.id en Map _items
    • Si no existe: crea CartItem nuevo
    • Si existe: suma cantidad
    • notifyListeners()
                ↓
    HomeShell escucha cambios
                ↓
    BottomNavigationBar muestra badge:
    Badge.count(count: cartController.totalItems)


┌──────────────────────────────────────────────────────────────┐
│ USUARIO VE CARRITO                                           │
└──────────────────────────────────────────────────────────────┘

CartScreen:
                ↓
    consumer<CartController>(
        cartController.items.map(...) → Lista visual
    )
                ↓
    Muestra:
    • Imagen del producto
    • Nombre + precio unitario
    • Controles +/- para cantidad
    • Botón eliminar
                ↓
    Cálculos automáticos:
    subtotal = suma de (precio × cantidad) de cada item
    tax = subtotal × 0.16 (IVA 16%)
    shipping = subtotal > 120 ? 0 : 8.99
    total = subtotal + tax + shipping


┌──────────────────────────────────────────────────────────────┐
│ USUARIO HACE CHECKOUT                                        │
└──────────────────────────────────────────────────────────────┘

CartScreen → Click "Proceder al pago"
                ↓
    cartController.checkout()
                ↓
    Validaciones:
    • ¿Carrito no vacío?
    • ¿No está procesando ya?
                ↓
    _isCheckingOut = true
    notifyListeners() → Muestra spinner
                ↓
    ProductService.createOrder(items)
                ↓
    Arma payload:
    {
      date: "2026-05-19T14:30:00Z",
      subtotal: 180,
      tax: 28.8,
      shipping: 0,
      total: 208.8,
      products: [
        { product_id: 1, quantity: 2, price: 50 },
        { product_id: 2, quantity: 1, price: 80 }
      ]
    }
                ↓
    POST /orders (con JWT en header)
                ↓
    Backend (authMiddleware valida JWT):
    • req.userId = 5 (del token)
    • INSERT INTO orders (...) VALUES (5, "2026-05-19...", ...)
    • lastID = 42
    • FOR EACH item:
        INSERT INTO order_items (42, product_id, quantity, price)
                ↓
    Si respuesta OK:
    • _items.clear() → Carrito vacío
    • Muestra snackbar "Compra realizada"
    • Navega a OrderHistoryScreen
                ↓
    Si falla:
    • _isCheckingOut = false
    • Muestra error
    • Permite reintentar
```

---

## 4️⃣ ESTRUCTURA DE DATOS - BASE DE DATOS

### Tabla: users

| Campo | Tipo | Constraints | Descripción |
|-------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY | Auto-incrementa |
| first_name | TEXT | NOT NULL | Nombre |
| last_name | TEXT | NOT NULL | Apellido |
| username | TEXT | UNIQUE | Usuario único para login |
| email | TEXT | UNIQUE | Correo único |
| password_hash | TEXT | NOT NULL | Hash bcrypt de contraseña |
| avatar_url | TEXT | | URL del avatar generado |

**Ejemplo:**
```
id | first_name | last_name | username | email | password_hash | avatar_url
---|------------|-----------|----------|-------|---|---
1 | Juan | Pérez | juanperez | juan@gmail.com | $2b$10$N9qo... | https://ui-avatars.com/api/?name=Juan%20Pérez
```

### Tabla: products

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | INTEGER PRIMARY KEY | Del API FakeStore |
| title | TEXT | Nombre del producto (traducido) |
| description | TEXT | Descripción (traducida) |
| price | REAL | Precio en $ |
| category | TEXT | Categoría: Hombre, Mujer, Camisas, etc |
| image_url | TEXT | URL de imagen |
| rating | REAL | Calificación 0-5 |

**Ejemplo:**
```
id | title | price | category | rating
---|-------|-------|----------|-------
1 | Chaqueta de hombre | 50.00 | Hombre | 4.5
2 | Pantalón de mujer | 80.00 | Mujer | 4.2
```

### Tabla: orders

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | INTEGER PRIMARY KEY | Auto-incrementa |
| user_id | INTEGER | FK → users.id |
| date | TEXT | ISO 8601 timestamp |
| status | TEXT | "Recibido", "En proceso", etc |
| subtotal | REAL | Sin impuestos |
| tax | REAL | IVA (16% en Colombia) |
| shipping | REAL | Costo de envío (0 si > 120) |
| total | REAL | subtotal + tax + shipping |

**Ejemplo:**
```
id | user_id | date | status | subtotal | tax | shipping | total
---|---------|------|--------|----------|-----|----------|-------
1 | 5 | 2026-05-19T14:30:00Z | Recibido | 180.00 | 28.80 | 0.00 | 208.80
```

### Tabla: order_items

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | INTEGER PRIMARY KEY | Auto-incrementa |
| order_id | INTEGER | FK → orders.id |
| product_id | INTEGER | ID del producto |
| quantity | INTEGER | Cantidad comprada |
| price | REAL | Precio al momento de compra |

**Ejemplo:**
```
id | order_id | product_id | quantity | price
---|----------|-----------|----------|-------
1 | 1 | 10 | 2 | 50.00
2 | 1 | 15 | 1 | 80.00
```

### Tabla: password_resets

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | INTEGER PRIMARY KEY | Auto-incrementa |
| email | TEXT | Email para reset |
| token | TEXT | Token temporal (10 chars) |
| expires_at | TEXT | ISO 8601 timestamp |

---

## 5️⃣ FLUJO DE PRODUCTOS

```
┌──────────────────────────────────────────────────────────────┐
│ SINCRONIZACIÓN INICIAL (al iniciar backend)                  │
└──────────────────────────────────────────────────────────────┘

backend/index.js → startServer()
                ↓
    await initDb()
                ↓
    ¿Existe database.db?
    └─→ NO: 
        • Crea database.db
        • Lee db_init.sql
        • Ejecuta todas las sentencias
        • Crea tablas vacías
                ↓
    syncProductsFromFakeStore(db)
                ↓
    fetch('https://fakestoreapi.com/products')
                ↓
    Recibe 20 productos de FakeStore
                ↓
    Filtra:
    • Solo ropa (clothing)
    • Rechaza accesorios (bags, shoes, etc)
                ↓
    Normaliza cada producto:
    • Traduce título al español
    • Traduce descripción al español
    • Cambia "men's clothing" → "Hombre"
    • Cambia "women's clothing" → "Mujer"
                ↓
    INSERT INTO products (...) VALUES (...)
    para cada producto normalizado
                ↓
    "Productos sincronizados desde FakeStore API"


┌──────────────────────────────────────────────────────────────┐
│ CARGAR PRODUCTOS EN FLUTTER                                  │
└──────────────────────────────────────────────────────────────┘

CatalogScreen._productsFuture
                ↓
    ProductService.fetchProducts()
                ↓
    GET /products
                ↓
    Backend:
    SELECT * FROM products WHERE category IN ('Hombre','Mujer',...)
                ↓
    Retorna JSON array
                ↓
    Flutter convierte cada JSON → Product.fromJson()
                ↓
    FutureBuilder<List<Product>>
    │
    ├─ connectionState.waiting → CircularProgressIndicator
    ├─ hasError → ErrorWidget
    └─ connectionState.done → GridView con productos


┌──────────────────────────────────────────────────────────────┐
│ FILTRAR PRODUCTOS (tiempo real)                              │
└──────────────────────────────────────────────────────────────┘

Usuario en CatalogScreen:

1. BUSCA POR TEXTO:
   _searchController.addListener(() {
     _query = value;
     setState(() { ... })  // Recalcula filtro
   })
                ↓
   filteredProducts = products.where((product) {
     searchText = '${title} ${description} ${category}'.toLowerCase();
     return searchText.contains(_query.toLowerCase());
   }).toList();

2. FILTRA POR CATEGORÍA:
   usuarioClickea categoria ("Hombre", "Camisas", etc)
                ↓
   _selectedCategory = "Hombre"
   setState(() { ... })
                ↓
   filteredProducts = products.where((product) {
     return product.category == "Hombre";
   }).toList();

3. COMBINA AMBOS FILTROS:
   filteredProducts = products.where((product) {
     final categoryMatch = _selectedCategory == 'Todos' 
       || product.category == _selectedCategory;
     
     final searchText = '${title} ${description} ${category}'.toLowerCase();
     final searchMatch = searchText.contains(_query.toLowerCase());
     
     return categoryMatch && searchMatch;
   }).toList();
                ↓
   GridView se actualiza automáticamente
```

---

## 6️⃣ COMPONENTES PRINCIPALES

### Frontend

```
main.dart
└─ AuthGate
   ├─ LoginScreen
   │  └─ LoginForm
   │     ├─ EmailField + validator
   │     └─ PasswordField + toggle
   │
   └─ HomeShell
      ├─ CatalogScreen
      │  ├─ BannerCarousel (PageView)
      │  ├─ SearchBar
      │  ├─ CategoryFilter (Chips)
      │  └─ ProductGrid (GridView)
      │
      ├─ CartScreen
      │  ├─ CartItemsList
      │  │  └─ CartItemCard (cantidad +/-)
      │  └─ OrderSummary
      │     ├─ Subtotal
      │     ├─ Impuestos
      │     ├─ Envío
      │     └─ Total + CheckoutButton
      │
      ├─ ProfileScreen
      │  ├─ UserInfo (Avatar + nombre)
      │  ├─ EditForm
      │  └─ ChangePasswordButton
      │
      └─ Drawer
         ├─ UserHeader
         ├─ Navigation Items
         └─ LogoutButton

ProductDetailScreen
└─ ProductImage
   ├─ ProductInfo (nombre, precio)
   ├─ Description (con bullets)
   ├─ QuantitySelector (+/-)
   └─ AddToCartButton
```

### Backend

```
index.js
├─ Database Setup
│  ├─ openDb()
│  ├─ initDb() + syncFromFakeStore()
│  └─ Helper functions (get, all, run)
│
├─ Authentication Routes
│  ├─ POST /auth/register
│  ├─ POST /auth/login
│  ├─ POST /auth/forgot-password
│  └─ POST /auth/reset-password
│
├─ User Routes (require authMiddleware)
│  ├─ GET /users/me
│  ├─ POST /users/me
│  └─ POST /users/me/password
│
├─ Product Routes
│  └─ GET /products
│
└─ Order Routes (require authMiddleware)
   ├─ POST /orders
   └─ GET /orders
```

---

## 7️⃣ PUNTO DE ENTRADA: main.dart

```dart
main()
├─ WidgetsFlutterBinding.ensureInitialized()
│  └─ Asegura que plugins de Flutter estén listos
│
├─ Leer API_BASE_URL del entorno
│
├─ SharedPreferences.getInstance()
│  └─ Acceso al almacenamiento local
│
├─ Crear ApiClient con URL base
│
├─ Crear AuthService
│
├─ Crear AuthController
│  └─ authController.restoreSession()
│     └─ Restaura token + usuario si existen
│
├─ Crear ProductService
│
├─ Crear CartController
│
├─ runApp(MultiProvider(...))
│  └─ Registra providers globales
│     ├─ authController
│     ├─ cartController
│     └─ productService
│
└─ ShopApp
   ├─ MaterialApp(home: AuthGate)
   │  └─ if (auth.isAuthenticated)
   │     ├─ HomeShell
   │     └─ LoginScreen
   │
   └─ Tema Material3 personalizado
```

---

## 8️⃣ FLUJO DE API REQUESTS

```
┌────────────────────────────┐
│   Flutter Widget           │
│   (context.read/watch)     │
└──────────────┬─────────────┘
               │
               ↓
┌────────────────────────────┐
│   Controller/Service       │
│   (AuthController, etc)    │
└──────────────┬─────────────┘
               │
               ↓
┌────────────────────────────┐
│   ApiClient.post/get()     │
│   • Agrega token al header │
│   • Serializa JSON         │
└──────────────┬─────────────┘
               │
      HTTP (JSON) Request
               │
               ↓
┌────────────────────────────┐
│   Express Server           │
│   • Routing                │
│   • Middleware             │
│   • Validaciones           │
└──────────────┬─────────────┘
               │
               ↓
┌────────────────────────────┐
│   SQLite Database          │
│   • Queries                │
│   • Inserts                │
└──────────────┬─────────────┘
               │
      HTTP Response (JSON)
               │
               ↓
┌────────────────────────────┐
│   Flutter: Future/async    │
│   • Deserializa JSON       │
│   • Crea modelos (fromJson)│
└──────────────┬─────────────┘
               │
               ↓
┌────────────────────────────┐
│   Controller               │
│   • notifyListeners()      │
│   • UI se actualiza        │
└────────────────────────────┘
```

---

## 🎯 RESUMEN ARQUITECTURA

**Patrón:** Clean Architecture + Provider Pattern

**Capas:**
1. **Presentation** (Widgets) - UI
2. **State Management** (Controllers) - Lógica
3. **Services** (Auth, Product) - Orquestación
4. **Data** (ApiClient, SharedPreferences) - Acceso a datos
5. **Models** (User, Product, etc) - Objetos

**Backend:**
1. **Routes** (Express) - Endpoints
2. **Middleware** (Auth) - Seguridad
3. **Business Logic** - Validaciones
4. **Database** (SQLite) - Persistencia

**Seguridad:**
- JWT con expiración
- bcrypt para contraseñas
- Middleware de autenticación
- SQL placeholders (previene injection)

---

**Esta es la arquitectura completa del proyecto.** 🏗️
