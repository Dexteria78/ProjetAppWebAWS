const mysql = require('mysql2/promise');
const AWS = require('aws-sdk');

const client = new AWS.SecretsManager({
    region: process.env.AWS_REGION || "us-east-1"
});

const secretName = process.env.SECRET_NAME || "student-records-ecs-db-credentials-phase6";

async function initDatabase() {
    try {
        console.log(`📝 Fetching secret: ${secretName}`);
        const data = await client.getSecretValue({SecretId: secretName}).promise();
        const secret = JSON.parse(data.SecretString);

        console.log(`🔌 Connecting to database: ${secret.host}`);
        const connection = await mysql.createConnection({
            host: secret.host,
            user: secret.username,
            password: secret.password,
            database: secret.database,
            multipleStatements: true
        });

        console.log('✓ Connected to database');

        const sql = `
            CREATE TABLE IF NOT EXISTS students (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255),
                address VARCHAR(255),
                city VARCHAR(255),
                state VARCHAR(255),
                email VARCHAR(255),
                phone VARCHAR(255)
            );

            DELETE FROM students;

            INSERT INTO students (name, address, city, state, email, phone) VALUES 
                ('Alice Martin', '123 Rue de Paris', 'Paris', 'Ile-de-France', 'alice.martin@email.fr', '01 23 45 67 89'),
                ('Bob Dupont', '456 Avenue de Lyon', 'Lyon', 'Auvergne-Rhone-Alpes', 'bob.dupont@email.fr', '04 56 78 90 12'),
                ('Charlie Durand', '789 Boulevard de Marseille', 'Marseille', 'PACA', 'charlie.durand@email.fr', '04 91 23 45 67');
        `;

        console.log('📊 Creating table and inserting data...');
        await connection.query(sql);
        await connection.end();

        console.log('✅ Database initialized successfully!');
        console.log('   - Table "students" created');
        console.log('   - 3 sample records inserted');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
    }
}

initDatabase();
