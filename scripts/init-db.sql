-- library-platform/scripts/init-db.sql
CREATE SCHEMA IF NOT EXISTS user_service;
CREATE SCHEMA IF NOT EXISTS library_service;

-- Таблица пользователей
CREATE TABLE user_service.users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Таблица книг (упрощенный каталог)
CREATE TABLE library_service.books (
    book_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    genre VARCHAR(100)
);

-- Таблица личной библиотеки
CREATE TABLE library_service.user_books (
    user_book_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    book_id UUID NOT NULL REFERENCES library_service.books(book_id) ON DELETE CASCADE,
    reading_status VARCHAR(50) DEFAULT 'want_to_read',
    progress_page INTEGER DEFAULT 0,
    UNIQUE(user_id, book_id)
);

-- Добавляем тестовые книги
INSERT INTO library_service.books (book_id, title, author, genre) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Преступление и наказание', 'Ф.М. Достоевский', 'Классика'),
    ('22222222-2222-2222-2222-222222222222', 'Мастер и Маргарита', 'М.А. Булгаков', 'Роман'),
    ('33333333-3333-3333-3333-333333333333', '1984', 'Джордж Оруэлл', 'Антиутопия')
ON CONFLICT DO NOTHING;