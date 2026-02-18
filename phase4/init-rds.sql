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
