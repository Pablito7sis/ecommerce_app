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
  (1, 'Camiseta de lino pastel', 'Camiseta ligera y fresca, ideal para usar todo el día con estilo suave.', 24.99, 'Ropa', 'https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg', 4.5),
  (2, 'Bolso mochila elegante', 'Bolso con múltiples compartimentos para trabajo y fin de semana.', 52.00, 'Accesorios', 'https://fakestoreapi.com/img/71li-ujtlUL._AC_UX679_.jpg', 4.3),
  (3, 'Zapatillas deportivas', 'Zapatillas cómodas para caminar y deportes ligeros.', 71.85, 'Calzado', 'https://fakestoreapi.com/img/61pHAEJ4NML._AC_UX679_.jpg', 4.2),
  (4, 'Auriculares inalámbricos', 'Sonido nítido con cancelación de ruido y gran autonomía.', 34.99, 'Electrónica', 'https://fakestoreapi.com/img/61U7T1koQqL._AC_SX679_.jpg', 4.1),
  (5, 'Reloj minimalista', 'Reloj con diseño minimalista y correa suave de cuero.', 87.99, 'Accesorios', 'https://fakestoreapi.com/img/71YAIFU48IL._AC_UX679_.jpg', 4.4),
  (6, 'Suéter suave', 'Suéter acogedor en tonos pastel, cómodo para cualquier ocasión.', 45.50, 'Ropa', 'https://fakestoreapi.com/img/71-3HjGNDUL._AC_UX679_.jpg', 4.6),
  (7, 'Bolso de mano', 'Bolso femenino elegante para el día a día y eventos especiales.', 33.99, 'Accesorios', 'https://fakestoreapi.com/img/71VZzC/upload.jpg', 4.0),
  (8, 'Chaqueta deportiva', 'Chaqueta ligera para entrenar o pasear con estilo deportivo.', 55.99, 'Ropa', 'https://fakestoreapi.com/img/71HblAHs5xL._AC_UY879_-2.jpg', 4.7);
