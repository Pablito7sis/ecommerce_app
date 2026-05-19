const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('backend/database.db');

db.all('SELECT id, title, category FROM products ORDER BY id', [], (err, rows) => {
  if (err) {
    console.error('Error:', err);
    process.exit(1);
  }
  
  console.log(`Total products: ${rows.length}\n`);
  console.log(JSON.stringify(rows, null, 2));
  
  db.close();
  process.exit(0);
});
