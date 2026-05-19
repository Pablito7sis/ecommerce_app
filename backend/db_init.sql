PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  username TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  avatar_url TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS password_resets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL,
  token TEXT NOT NULL UNIQUE,
  expires_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS products (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  price REAL NOT NULL,
  category TEXT NOT NULL,
  image_url TEXT NOT NULL,
  rating REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  date TEXT NOT NULL,
  status TEXT NOT NULL,
  subtotal REAL NOT NULL,
  tax REAL NOT NULL,
  shipping REAL NOT NULL,
  total REAL NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS order_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  price REAL NOT NULL,
  FOREIGN KEY(order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
);

INSERT OR IGNORE INTO products (id, title, description, price, category, image_url, rating) VALUES
  (1, 'Camiseta de manga corta para hombre', 'Camiseta cómoda de algodón con corte entallado, ideal para el día a día.', 24.99, 'Camisas', 'https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg', 4.5),
  (2, 'Pantalón jeans para mujer', 'Jeans ajustados con acabado clásico y tejido resistente.', 39.99, 'Pantalones', 'https://fakestoreapi.com/img/71li-ujtlUL._AC_UX679_.jpg', 4.3),
  (3, 'Chaqueta ligera de hombre', 'Chaqueta deportiva con capucha, perfecta para clima fresco.', 55.99, 'Abrigos', 'https://fakestoreapi.com/img/71HblAHs5xL._AC_UY879_-2.jpg', 4.7),
  (4, 'Suéter de mujer', 'Suéter suave de punto con un estilo cómodo y elegante.', 45.50, 'Abrigos', 'https://fakestoreapi.com/img/71-3HjGNDUL._AC_UX679_.jpg', 4.6),
  (5, 'Camisa formal para hombre', 'Camisa de manga larga para ocasiones especiales y oficina.', 32.99, 'Camisas', 'https://fakestoreapi.com/img/71YAIFU48IL._AC_UX679_.jpg', 4.4),
  (6, 'Pantalones cortos casual para mujer', 'Shorts ligeros y cómodos para uso diario en verano.', 29.99, 'Pantalones', 'https://fakestoreapi.com/img/61pHAEJ4NML._AC_UX679_.jpg', 4.2),
  (7, 'Abrigo de invierno para mujer', 'Abrigo cálido con forro suave para los días fríos.', 69.99, 'Abrigos', 'https://fakestoreapi.com/img/71VZzC/upload.jpg', 4.9),
  (8, 'Pantalón deportivo para hombre', 'Pantalón ligero con elasticidad para entrenamientos y descanso.', 34.99, 'Pantalones', 'https://fakestoreapi.com/img/61U7T1koQqL._AC_SX679_.jpg', 4.1);
