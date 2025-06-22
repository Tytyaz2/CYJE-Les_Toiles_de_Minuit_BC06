-- TABLE users
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(180) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    roles JSON NOT NULL DEFAULT '[]',
    name VARCHAR(255) DEFAULT NULL
    );

-- TABLE events
CREATE TABLE IF NOT EXISTS events (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT DEFAULT NULL,
    city VARCHAR(255) DEFAULT NULL,
    address VARCHAR(255) DEFAULT NULL,
    date TIMESTAMP NOT NULL,
    price FLOAT NOT NULL DEFAULT 0.0,
    state VARCHAR(50) NOT NULL DEFAULT 'Draft',
    max_capacity INTEGER NOT NULL DEFAULT 0,
    image VARCHAR(255) DEFAULT NULL,
    organizer_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE
    );

-- TABLE inscriptions (ou participations)
CREATE TABLE IF NOT EXISTS event_registrations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, event_id) -- empêche un même utilisateur de s'inscrire plusieurs fois au même événement
    );
