const mysql = require('mysql2/promise');
const config = require('./config/config');

async function initDatabase() {
    try {
        // Wait for config to be loaded (it's async via Secrets Manager)
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        const connection = await mysql.createConnection({
            host: config.APP_DB_HOST,
            user: config.APP_DB_USER,
            password: config.APP_DB_PASSWORD,
            database: config.APP_DB_NAME
        });

        console.log('✓ Connected to database');

        // Check if table exists
        const [tables] = await connection.query("SHOW TABLES LIKE 'students'");
        
        if (tables.length === 0) {
            console.log('📊 Creating students table...');
            
            await connection.query(`
                CREATE TABLE students (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(255),
                    address VARCHAR(255),
                    city VARCHAR(255),
                    state VARCHAR(255),
                    email VARCHAR(255),
                    phone VARCHAR(255)
                )
            `);

            console.log('📝 Inserting sample data...');
            await connection.query(`
                INSERT INTO students (name, address, city, state, email, phone) VALUES 
                    ('Alice Martin', '123 Rue de Paris', 'Paris', 'Ile-de-France', 'alice.martin@email.fr', '01 23 45 67 89'),
                    ('Bob Dupont', '456 Avenue de Lyon', 'Lyon', 'Auvergne-Rhone-Alpes', 'bob.dupont@email.fr', '04 56 78 90 12'),
                    ('Charlie Durand', '789 Boulevard de Marseille', 'Marseille', 'PACA', 'charlie.durand@email.fr', '04 91 23 45 67')
            `);

            console.log('✅ Database initialized successfully!');
        } else {
            console.log('✓ Students table already exists');
        }

        await connection.end();
    } catch (error) {
        console.error('❌ Database initialization error:', error.message);
        // Don't fail the app startup if DB init fails
    }
}

module.exports = { initDatabase };
