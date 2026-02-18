-- Script d'initialisation de la base de données pour test local
-- Création de la table students

CREATE TABLE IF NOT EXISTS students (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  address VARCHAR(255),
  city VARCHAR(255),
  state VARCHAR(255),
  email VARCHAR(255),
  phone VARCHAR(255)
);

-- Insertion de données de test
INSERT INTO students (name, address, city, state, email, phone) VALUES
('Alice Martin', '123 Rue de la Paix', 'Paris', 'Île-de-France', 'alice.martin@example.com', '+33 1 23 45 67 89'),
('Bob Dupont', '456 Avenue des Champs', 'Lyon', 'Auvergne-Rhône-Alpes', 'bob.dupont@example.com', '+33 4 12 34 56 78'),
('Charlie Durand', '789 Boulevard Saint-Michel', 'Marseille', 'Provence-Alpes-Côte d''Azur', 'charlie.durand@example.com', '+33 4 91 23 45 67');
