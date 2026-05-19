const fs = require('fs');
const path = require('path');
const express = require('express');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const DATABASE_PATH = path.join(__dirname, 'database.db');
const SCHEMA_PATH = path.join(__dirname, 'db_init.sql');
const SECRET_KEY = process.env.JWT_SECRET || 'change-me-for-production';
const PORT = Number(process.env.PORT || 8000);

function openDb() {
  const db = new sqlite3.Database(DATABASE_PATH);
  db.configure('busyTimeout', 5000);
  return db;
}

async function initDb() {
  const dbExists = fs.existsSync(DATABASE_PATH);
  if (!dbExists) {
    const script = fs.readFileSync(SCHEMA_PATH, 'utf8');
    const db = openDb();
    await new Promise((resolve, reject) => {
      db.exec(script, (err) => {
        if (err) {
          reject(err);
          return;
        }
        resolve();
      });
    });
    db.close();
    console.log('Base de datos inicializada con db_init.sql');
  }

  const db = openDb();
  try {
    await syncProductsFromFakeStore(db);
  } catch (error) {
    console.error('Error al inicializar productos:', error);
  } finally {
    db.close();
  }
}

function run(db, sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) return reject(err);
      resolve(this);
    });
  });
}

function get(db, sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) return reject(err);
      resolve(row);
    });
  });
}

function all(db, sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) return reject(err);
      resolve(rows);
    });
  });
}

async function syncProductsFromFakeStore(db) {
  try {
    const response = await fetch('https://fakestoreapi.com/products');
    if (!response.ok) {
      throw new Error(`Fakestore API responded with ${response.status}`);
    }

    const products = await response.json();
    if (!Array.isArray(products)) {
      throw new Error('Fakestore API returned invalid product list.');
    }

    await run(db, 'DELETE FROM products');

    const insert = db.prepare(
      'INSERT OR REPLACE INTO products (id, title, description, price, category, image_url, rating) VALUES (?, ?, ?, ?, ?, ?, ?)',
    );

    for (const product of products) {
      const normalized = normalizeFakeStoreProduct(product);
      if (!normalized) continue;

      await new Promise((resolve, reject) => {
        insert.run(
          normalized.id,
          normalized.title,
          normalized.description,
          normalized.price,
          normalized.category,
          normalized.image_url,
          normalized.rating,
          (err) => {
            if (err) return reject(err);
            resolve();
          },
        );
      });
    }

    insert.finalize();
    console.log('Productos sincronizados desde FakeStore API.');
  } catch (error) {
    console.error('No se pudieron sincronizar productos desde FakeStore:', error);
  }
}

function isClothingCategory(category) {
  const normalized = String(category).toLowerCase();
  return normalized.includes("men's") || normalized.includes("women's");
}

function isActualClothing(title, description) {
  const combined = (String(title || '') + ' ' + String(description || '')).toLowerCase();
  
  // Clothing items we want
  const clothingKeywords = /(shirt|t-shirt|tee|polo|blouse|top|sweater|sweatshirt|hoodie|jacket|coat|cardigan|vest|dress|skirt|pants|jeans|trouser|short|bermuda|pant|tank|camiseta|camisa|pantalón|sudadera|chaqueta|abrigo|vestido|falda)/;
  
  // Exclude accessories and non-clothing
  const excludedKeywords = /(bag|backpack|purse|wallet|belt|hat|cap|shoe|boot|sneaker|sock|jewelry|watch|ring|necklace|bracelet|earring|glove|scarf|tie|handkerchief|luggage|tote|satchel|clutch|briefcase|carrier|case)/;
  
  return clothingKeywords.test(combined) && !excludedKeywords.test(combined);
}

function translateText(text) {
  if (!text) return '';
  
  let translated = String(text)
    .replace(/Men's Clothing/gi, 'Ropa para hombre')
    .replace(/Women's Clothing/gi, 'Ropa para mujer')
    .replace(/jacket/gi, 'chaqueta')
    .replace(/coat/gi, 'abrigo')
    .replace(/hoodie/gi, 'sudadera')
    .replace(/sweatshirt/gi, 'sudadera')
    .replace(/cardigan/gi, 'cardigan')
    .replace(/sweater/gi, 'suéter')
    .replace(/polo/gi, 'polo')
    .replace(/shirt/gi, 'camisa')
    .replace(/blouse/gi, 'blusa')
    .replace(/t-shirt/gi, 'camiseta')
    .replace(/tee/gi, 'camiseta')
    .replace(/top/gi, 'top')
    .replace(/tank/gi, 'camiseta')
    .replace(/pants/gi, 'pantalón')
    .replace(/jeans/gi, 'pantalón')
    .replace(/trouser/gi, 'pantalón')
    .replace(/shorts/gi, 'short')
    .replace(/short/gi, 'short')
    .replace(/bermuda/gi, 'bermuda')
    .replace(/dress/gi, 'vestido')
    .replace(/skirt/gi, 'falda')
    .replace(/vest/gi, 'chaleco')
    .replace(/cotton/gi, 'algodón')
    .replace(/polyester/gi, 'poliéster')
    .replace(/slim/gi, 'entallado')
    .replace(/classic/gi, 'clásico')
    .replace(/regular/gi, 'regular')
    .replace(/fit/gi, 'ajuste')
    .replace(/100%/gi, '100%')
    .replace(/soft/gi, 'suave')
    .replace(/lightweight/gi, 'ligero')
    .replace(/breathable/gi, 'transpirable')
    .replace(/comfortable/gi, 'cómodo')
    .replace(/perfect/gi, 'perfecto')
    .replace(/ideal/gi, 'ideal')
    .replace(/stylish/gi, 'elegante')
    .replace(/casual/gi, 'casual')
    .replace(/formal/gi, 'formal')
    .replace(/everyday/gi, 'diario')
    .replace(/women's/gi, 'de mujer')
    .replace(/men's/gi, 'de hombre')
    .replace(/summer/gi, 'de verano')
    .replace(/winter/gi, 'de invierno')
    .replace(/spring/gi, 'de primavera');
  
  translated = translated.replace(/\s+/g, ' ').trim();
  
  if (translated.length === 0) {
    return 'Descripción de prenda.';
  }
  
  if (!translated.endsWith('.')) {
    translated += '.';
  }
  
  return translated
    .split('. ')
    .map((part) => part.trim())
    .filter((part) => part.length > 0)
    .map((part) => part[0].toUpperCase() + part.slice(1))
    .join('. ');
}

function getCategoryFromTitle(title, category) {
  const titleLower = String(title || '').toLowerCase();
  const categoryLower = String(category || '').toLowerCase();
  
  // Jackets and outerwear
  if (/(jacket|coat|hoodie|cardigan|vest|sweater|sweatshirt)/.test(titleLower)) {
    return 'Abrigos';
  }
  
  // Shirts and tops
  if (/(shirt|blouse|polo|tee|t-shirt|top|tank|camiseta|camisa|blusa)/.test(titleLower)) {
    return 'Camisas';
  }
  
  // Pants and bottoms
  if (/(pants|jeans|trouser|shorts|short|bermuda|pant|pantalón)/.test(titleLower)) {
    return 'Pantalones';
  }
  
  // Dresses and skirts for women
  if (/(dress|skirt|vestido|falda)/.test(titleLower)) {
    return categoryLower.includes('women') ? 'Mujer' : 'Mujer';
  }
  
  // By gender
  if (categoryLower.includes('men')) {
    return 'Hombre';
  }
  
  if (categoryLower.includes('women')) {
    return 'Mujer';
  }
  
  return null;
}

function normalizeFakeStoreProduct(product) {
  if (!isClothingCategory(product.category)) {
    return null;
  }
  
  if (!isActualClothing(product.title, product.description)) {
    return null;
  }
  
  const categoryLabel = getCategoryFromTitle(product.title, product.category);
  if (!categoryLabel) {
    return null;
  }

  const ratingData = product.rating;
  return {
    id: Number(product.id) || 0,
    title: translateText(product.title || 'Prenda'),
    description: translateText(product.description || ''),
    price: Number(product.price) || 0,
    category: categoryLabel,
    image_url: product.image || product.image_url || '',
    rating: typeof ratingData === 'object' ? Number(ratingData.rate) || 0 : Number(ratingData) || 0,
  };
}

function createToken(userId) {
  return jwt.sign({ sub: userId }, SECRET_KEY, { expiresIn: '1h' });
}

function getUserRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    first_name: row.first_name,
    last_name: row.last_name,
    username: row.username,
    email: row.email,
    avatar_url: row.avatar_url,
  };
}

function authMiddleware(req, res, next) {
  const authHeader = req.header('authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'No autorizado' });
  }

  const token = authHeader.slice(7);
  try {
    const payload = jwt.verify(token, SECRET_KEY);
    req.userId = payload.sub;
    next();
  } catch (error) {
    return res.status(401).json({ message: 'No autorizado' });
  }
}

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    message: 'Ecommerce backend API está activo. Usa los endpoints /products, /auth/login, /orders, etc.',
  });
});

app.post('/auth/register', async (req, res) => {
  const { first_name, last_name, username, email, password } = req.body;
  if (!first_name || !last_name || !username || !email || !password) {
    return res.status(400).json({ message: 'Faltan datos de registro' });
  }

  const db = openDb();
  try {
    const existingEmail = await get(db, 'SELECT id FROM users WHERE email = ?', [email]);
    if (existingEmail) {
      return res.status(400).json({ message: 'El correo electrónico ya está registrado.' });
    }

    const existingUsername = await get(db, 'SELECT id FROM users WHERE username = ?', [username]);
    if (existingUsername) {
      return res.status(400).json({ message: 'El nombre de usuario ya está en uso.' });
    }

    const password_hash = bcrypt.hashSync(password, 10);
    const avatar_url = `https://ui-avatars.com/api/?name=${encodeURIComponent(first_name + ' ' + last_name)}&background=7EC8C9&color=ffffff`;
    const result = await run(db,
      'INSERT INTO users (first_name, last_name, username, email, password_hash, avatar_url) VALUES (?, ?, ?, ?, ?, ?)',
      [first_name, last_name, username, email, password_hash, avatar_url],
    );
    const user = getUserRow(await get(db, 'SELECT * FROM users WHERE id = ?', [result.lastID]));
    const token = createToken(user.id);
    res.json({ token, user });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error en el servidor' });
  } finally {
    db.close();
  }
});

app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ message: 'Faltan credenciales' });
  }

  const db = openDb();
  try {
    const row = await get(db, 'SELECT * FROM users WHERE email = ? OR username = ?', [email, email]);
    if (!row || !bcrypt.compareSync(password, row.password_hash)) {
      return res.status(401).json({ message: 'Credenciales incorrectas' });
    }
    const user = getUserRow(row);
    const token = createToken(user.id);
    res.json({ token, user });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error en el servidor' });
  } finally {
    db.close();
  }
});

app.post('/auth/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({ message: 'El correo es requerido' });
  }

  const db = openDb();
  try {
    const user = await get(db, 'SELECT id FROM users WHERE email = ?', [email]);
    if (!user) {
      return res.status(200).json({ message: 'Si existe el correo, se envió el token' });
    }
    const token = Math.random().toString(36).slice(2, 12);
    const expires_at = new Date(Date.now() + 3600 * 1000).toISOString();
    await run(db, 'INSERT OR REPLACE INTO password_resets (email, token, expires_at) VALUES (?, ?, ?)', [email, token, expires_at]);
    res.json({ token, expires_at });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error en el servidor' });
  } finally {
    db.close();
  }
});

app.post('/auth/reset-password', async (req, res) => {
  const { email, token, new_password } = req.body;
  if (!email || !token || !new_password) {
    return res.status(400).json({ message: 'Faltan datos' });
  }

  const db = openDb();
  try {
    const row = await get(db, 'SELECT * FROM password_resets WHERE email = ? AND token = ?', [email, token]);
    if (!row || new Date(row.expires_at) < new Date()) {
      return res.status(400).json({ message: 'Token inválido o expirado' });
    }
    const password_hash = bcrypt.hashSync(new_password, 10);
    await run(db, 'UPDATE users SET password_hash = ? WHERE email = ?', [password_hash, email]);
    await run(db, 'DELETE FROM password_resets WHERE email = ?', [email]);
    res.json({ message: 'Contraseña actualizada' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error en el servidor' });
  } finally {
    db.close();
  }
});

app.get('/users/me', authMiddleware, async (req, res) => {
  const db = openDb();
  try {
    const row = await get(db, 'SELECT * FROM users WHERE id = ?', [req.userId]);
    if (!row) return res.status(401).json({ message: 'No autorizado' });
    res.json(getUserRow(row));
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error en el servidor' });
  } finally {
    db.close();
  }
});

app.post('/users/me', authMiddleware, async (req, res) => {
  const { first_name, last_name, username } = req.body;
  if (!first_name || !last_name || !username) {
    return res.status(400).json({ message: 'Faltan datos de perfil' });
  }

  const db = openDb();
  try {
    const existing = await get(db, 'SELECT id FROM users WHERE username = ? AND id != ?', [username, req.userId]);
    if (existing) {
      return res.status(400).json({ message: 'El nombre de usuario ya está en uso.' });
    }
    await run(db, 'UPDATE users SET first_name = ?, last_name = ?, username = ? WHERE id = ?', [first_name, last_name, username, req.userId]);
    const row = await get(db, 'SELECT * FROM users WHERE id = ?', [req.userId]);
    res.json(getUserRow(row));
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error en el servidor' });
  } finally {
    db.close();
  }
});

app.post('/users/me/password', authMiddleware, async (req, res) => {
  const { current_password, new_password } = req.body;
  if (!current_password || !new_password) {
    return res.status(400).json({ message: 'Faltan datos de contraseña' });
  }

  const db = openDb();
  try {
    const row = await get(db, 'SELECT password_hash FROM users WHERE id = ?', [req.userId]);
    if (!row || !bcrypt.compareSync(current_password, row.password_hash)) {
      return res.status(401).json({ message: 'Contraseña actual incorrecta.' });
    }
    const password_hash = bcrypt.hashSync(new_password, 10);
    await run(db, 'UPDATE users SET password_hash = ? WHERE id = ?', [password_hash, req.userId]);
    res.json({ message: 'Contraseña actualizada.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error en el servidor' });
  } finally {
    db.close();
  }
});

app.get('/products', async (req, res) => {
  const db = openDb();
  try {
    const rows = await all(
      db,
      "SELECT * FROM products WHERE category IN ('Hombre','Mujer','Camisas','Pantalones','Abrigos') ORDER BY id",
    );
    res.json(rows.map((row) => ({
      id: row.id,
      title: row.title,
      description: row.description,
      price: row.price,
      category: row.category,
      image_url: row.image_url,
      rating: row.rating,
    })));
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error en el servidor' });
  } finally {
    db.close();
  }
});

app.post('/orders', authMiddleware, async (req, res) => {
  const { date, subtotal, tax, shipping, total, products } = req.body;
  if (!date || subtotal == null || tax == null || shipping == null || total == null || !Array.isArray(products)) {
    return res.status(400).json({ message: 'Faltan datos del pedido' });
  }

  const db = openDb();
  try {
    const result = await run(db,
      'INSERT INTO orders (user_id, date, status, subtotal, tax, shipping, total) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [req.userId, date, 'Recibido', subtotal, tax, shipping, total],
    );
    const orderId = result.lastID;
    for (const item of products) {
      await run(db, 'INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)', [orderId, item.product_id, item.quantity, item.price]);
    }
    res.json({ id: orderId });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error en el servidor' });
  } finally {
    db.close();
  }
});

app.get('/orders', authMiddleware, async (req, res) => {
  const db = openDb();
  try {
    const orders = await all(db, 'SELECT * FROM orders WHERE user_id = ? ORDER BY date DESC', [req.userId]);
    const result = [];
    for (const order of orders) {
      const items = await all(db, 'SELECT product_id, quantity, price FROM order_items WHERE order_id = ?', [order.id]);
      result.push({
        id: order.id,
        date: order.date,
        status: order.status,
        subtotal: order.subtotal,
        tax: order.tax,
        shipping: order.shipping,
        total: order.total,
        items,
      });
    }
    res.json(result);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error en el servidor' });
  } finally {
    db.close();
  }
});

async function startServer() {
  await initDb();
  app.listen(PORT, () => {
    console.log(`Backend Node.js escuchando en http://localhost:${PORT}`);
  });
}

startServer().catch((error) => {
  console.error('Error al iniciar el servidor:', error);
  process.exit(1);
});
