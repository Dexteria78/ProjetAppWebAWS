const mysql = require('mysql2/promise');
const AWS = require('aws-sdk');

async function getDbConfig() {
    try {
        const client = new AWS.SecretsManager({
            region: process.env.AWS_REGION || "us-east-1"
        });
        
        const secretName = process.env.SECRET_NAME || "student-records-ecs-db-credentials-phase6";
        const data = await client.getSecretValue({SecretId: secretName}).promise();
        const secret = JSON.parse(data.SecretString);
        
        return {
            host: secret.host,
            user: secret.username,
            password: secret.password,
            database: secret.database
        };
    } catch (error) {
        return {
            host: process.env.APP_DB_HOST || 'localhost',
            user: process.env.APP_DB_USER || 'admin',
            password: process.env.APP_DB_PASSWORD || 'adminpassword',
            database: process.env.APP_DB_NAME || 'studentrecordsdb'
        };
    }
}

async function initDatabase() {
    try {
        await new Promise(resolve => setTimeout(resolve, 3000));
        
        const dbConfig = await getDbConfig();
        console.log(`🔌 Connecting to database: ${dbConfig.host}/${dbConfig.database}`);
        
        const connection = await mysql.createConnection(dbConfig);
        console.log('✓ Connected to database');

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
    }
}

module.exports = { initDatabase };
