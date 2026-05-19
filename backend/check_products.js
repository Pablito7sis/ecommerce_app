const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const db = new sqlite3.Database(path.join(__dirname, 'database.db'));

db.all('SELECT id, title, category FROM products ORDER BY id', [], (err, rows) => {
  if (err) {
    console.error('Error:', err);
    process.exit(1);
  }
  
  console.log(`Total products: ${rows.length}\n`);
  rows.forEach((row, idx) => {
    console.log(`${idx + 1}. [${row.category}] ${row.title}`);
  });
  
  db.close();
  process.exit(0);
});
