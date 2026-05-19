# Mercado Movil

App movil e-commerce hecha con Flutter. Incluye catalogo de productos, busqueda,
detalle, carrito, checkout y una capa de API REST separada para conectar un
backend propio.

## Ejecutar

```bash
flutter pub get
flutter run
```

Por defecto consume datos de prueba desde `https://fakestoreapi.com`.


La app espera estos endpoints:

- `GET /products`: lista de productos.
- `POST /carts`: crea un pedido con productos y cantidades.

## Estructura principal

- `lib/core/api_client.dart`: cliente HTTP REST.
- `lib/models/`: modelos de producto y carrito.
- `lib/services/product_service.dart`: repositorio REST.
- `lib/state/cart_controller.dart`: estado del carrito.
- `lib/screens/`: pantallas de catalogo, detalle, carrito y perfil.
- `lib/widgets/`: componentes reutilizables.

## Documentacion

- `DOCUMENTO_TECNICO.md`: arquitectura, endpoints, modelo de datos, flujos y ejecucion del proyecto.

## Validacion

```bash
flutter analyze
flutter test
```
"# ecommerce_app" 
