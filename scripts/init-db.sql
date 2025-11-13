-- Создание схем для всех микросервисов
CREATE SCHEMA IF NOT EXISTS user_service;
CREATE SCHEMA IF NOT EXISTS catalog_service;
CREATE SCHEMA IF NOT EXISTS library_service;
CREATE SCHEMA IF NOT EXISTS reading_service;
CREATE SCHEMA IF NOT EXISTS rating_service;
CREATE SCHEMA IF NOT EXISTS review_service;
CREATE SCHEMA IF NOT EXISTS subscription_service;
CREATE SCHEMA IF NOT EXISTS recommendation_service;

-- User Service (Пользователи)
CREATE TABLE user_service.users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Catalog Service (Каталог книг - общий для всех)
CREATE TABLE catalog_service.books (
    book_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    genre VARCHAR(100),
    description TEXT,
    publication_year INTEGER,
    cover_image_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Library Service (Личная библиотека пользователя)
CREATE TABLE library_service.user_libraries (
    user_library_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    book_id UUID NOT NULL,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    shelf_type VARCHAR(50) DEFAULT 'want_to_read', -- 'want_to_read', 'reading', 'finished', 'favorites'
    UNIQUE(user_id, book_id)
);

-- Reading Service (Прогресс чтения)
CREATE TABLE reading_service.reading_progress (
    progress_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    book_id UUID NOT NULL,
    current_page INTEGER DEFAULT 0,
    total_pages INTEGER DEFAULT 0,
    reading_status VARCHAR(50) DEFAULT 'not_started', -- 'not_started', 'reading', 'finished', 'paused', 'abandoned'
    last_read_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    reading_time_minutes INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, book_id)
);

CREATE TABLE reading_service.bookmarks (
    bookmark_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    book_id UUID NOT NULL,
    page_number INTEGER NOT NULL,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Rating Service (Оценки)
CREATE TABLE rating_service.ratings (
    rating_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    book_id UUID NOT NULL,
    rating_value INTEGER NOT NULL CHECK (rating_value >= 1 AND rating_value <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, book_id)
);

-- Таблица для агрегированных рейтингов книг
CREATE TABLE rating_service.book_ratings_summary (
    book_id UUID PRIMARY KEY,
    total_ratings INTEGER DEFAULT 0,
    sum_ratings INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    rating_1_count INTEGER DEFAULT 0,
    rating_2_count INTEGER DEFAULT 0,
    rating_3_count INTEGER DEFAULT 0,
    rating_4_count INTEGER DEFAULT 0,
    rating_5_count INTEGER DEFAULT 0,
    last_calculated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Review Service (Отзывы) - могут быть с оценкой или без
CREATE TABLE review_service.reviews (
    review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    book_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    rating_value INTEGER CHECK (rating_value >= 1 AND rating_value <= 5), -- Может быть NULL
    is_edited BOOLEAN DEFAULT FALSE,
    is_public BOOLEAN DEFAULT TRUE,
    likes_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Subscription Service (Подписки) - ОБНОВЛЕННАЯ СТРУКТУРА
CREATE TABLE subscription_service.subscriptions (
    subscription_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscriber_id UUID NOT NULL,
    target_user_id UUID NOT NULL,
    subscription_type VARCHAR(50) DEFAULT 'regular', -- 'regular', 'close_friends'
    is_mutual BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(subscriber_id, target_user_id),
    CHECK (subscriber_id != target_user_id)
);

-- Лента активности пользователей - ОБНОВЛЕННАЯ СТРУКТУРА
CREATE TABLE subscription_service.activity_feed (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- Чья лента
    actor_id UUID NOT NULL, -- Кто совершил действие
    activity_type VARCHAR(100) NOT NULL, -- 'added_book', 'finished_reading', 'added_review', 'rated_book', 'started_following'
    target_type VARCHAR(50) NOT NULL, -- 'book', 'review', 'rating', 'user'
    target_id UUID NOT NULL, -- book_id, review_id, rating_id, или user_id
    activity_data JSONB, -- Дополнительные данные
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Уведомления для пользователей - НОВАЯ ТАБЛИЦА
CREATE TABLE subscription_service.notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- Кому уведомление
    notification_type VARCHAR(100) NOT NULL, -- 'new_follower', 'new_activity', 'system'
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_entity_type VARCHAR(50), -- 'user', 'book', 'review'
    related_entity_id UUID, -- ID связанной сущности
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Статистика подписчиков - НОВАЯ ТАБЛИЦА
CREATE TABLE subscription_service.user_stats (
    user_id UUID PRIMARY KEY,
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    mutual_followers_count INTEGER DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Recommendation Service (Рекомендации)
CREATE TABLE recommendation_service.user_preferences (
    preference_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    favorite_genres JSONB DEFAULT '[]',
    favorite_authors JSONB DEFAULT '[]',
    disliked_genres JSONB DEFAULT '[]',
    preferred_ratings JSONB DEFAULT '{}',
    reading_habits JSONB DEFAULT '{}',
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE recommendation_service.recommendations (
    recommendation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    book_id UUID NOT NULL,
    recommendation_score DECIMAL(5,4) NOT NULL,
    algorithm_type VARCHAR(50) NOT NULL, -- 'collaborative', 'content_based', 'hybrid'
    reason TEXT,
    is_viewed INTEGER DEFAULT 0,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- История рекомендаций - НОВАЯ ТАБЛИЦА
CREATE TABLE recommendation_service.recommendation_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    book_id UUID NOT NULL,
    action_type VARCHAR(50) NOT NULL, -- 'viewed', 'clicked', 'added_to_library', 'rated'
    action_score INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Индексы для производительности
CREATE INDEX idx_ratings_user_book ON rating_service.ratings(user_id, book_id);
CREATE INDEX idx_ratings_book ON rating_service.ratings(book_id);
CREATE INDEX idx_reviews_user_book ON review_service.reviews(user_id, book_id);
CREATE INDEX idx_reviews_book ON review_service.reviews(book_id);
CREATE INDEX idx_reviews_rating ON review_service.reviews(rating_value) WHERE rating_value IS NOT NULL;
CREATE INDEX idx_library_user_book ON library_service.user_libraries(user_id, book_id);
CREATE INDEX idx_reading_user_book ON reading_service.reading_progress(user_id, book_id);
CREATE INDEX idx_reading_status ON reading_service.reading_progress(reading_status);
CREATE INDEX idx_bookmarks_user_book ON reading_service.bookmarks(user_id, book_id);

-- Индексы для Subscription Service
CREATE INDEX idx_subscriptions_subscriber ON subscription_service.subscriptions(subscriber_id);
CREATE INDEX idx_subscriptions_target ON subscription_service.subscriptions(target_user_id);
CREATE INDEX idx_subscriptions_mutual ON subscription_service.subscriptions(is_mutual) WHERE is_mutual = TRUE;
CREATE INDEX idx_activity_feed_user ON subscription_service.activity_feed(user_id, created_at);
CREATE INDEX idx_activity_feed_actor ON subscription_service.activity_feed(actor_id);
CREATE INDEX idx_notifications_user ON subscription_service.notifications(user_id, created_at);
CREATE INDEX idx_notifications_unread ON subscription_service.notifications(user_id, is_read) WHERE is_read = FALSE;

-- Индексы для Recommendation Service
CREATE INDEX idx_recommendations_user ON recommendation_service.recommendations(user_id, recommendation_score);
CREATE INDEX idx_recommendations_algorithm ON recommendation_service.recommendations(algorithm_type);
CREATE INDEX idx_recommendation_history_user ON recommendation_service.recommendation_history(user_id, created_at);

-- Триггеры для автоматического обновления статистики подписок
CREATE OR REPLACE FUNCTION update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Обновляем статистику при добавлении подписки
    IF TG_OP = 'INSERT' THEN
        -- Обновляем статистику подписчика (following)
        INSERT INTO subscription_service.user_stats (user_id, following_count)
        VALUES (NEW.subscriber_id, 1)
        ON CONFLICT (user_id) DO UPDATE SET
            following_count = subscription_service.user_stats.following_count + 1,
            last_updated = CURRENT_TIMESTAMP;
        
        -- Обновляем статистику целевого пользователя (followers)
        INSERT INTO subscription_service.user_stats (user_id, followers_count)
        VALUES (NEW.target_user_id, 1)
        ON CONFLICT (user_id) DO UPDATE SET
            followers_count = subscription_service.user_stats.followers_count + 1,
            last_updated = CURRENT_TIMESTAMP;
        
        -- Проверяем взаимную подписку
        IF EXISTS (
            SELECT 1 FROM subscription_service.subscriptions 
            WHERE subscriber_id = NEW.target_user_id AND target_user_id = NEW.subscriber_id
        ) THEN
            -- Обновляем обе записи как взаимные
            UPDATE subscription_service.subscriptions 
            SET is_mutual = TRUE 
            WHERE (subscriber_id = NEW.subscriber_id AND target_user_id = NEW.target_user_id)
               OR (subscriber_id = NEW.target_user_id AND target_user_id = NEW.subscriber_id);
            
            -- Обновляем счетчики взаимных подписок
            UPDATE subscription_service.user_stats 
            SET mutual_followers_count = mutual_followers_count + 1 
            WHERE user_id IN (NEW.subscriber_id, NEW.target_user_id);
        END IF;
    
    -- Обновляем статистику при удалении подписки
    ELSIF TG_OP = 'DELETE' THEN
        -- Обновляем статистику подписчика
        UPDATE subscription_service.user_stats 
        SET following_count = GREATEST(0, following_count - 1)
        WHERE user_id = OLD.subscriber_id;
        
        -- Обновляем статистику целевого пользователя
        UPDATE subscription_service.user_stats 
        SET followers_count = GREATEST(0, followers_count - 1)
        WHERE user_id = OLD.target_user_id;
        
        -- Если была взаимная подписка, обновляем
        IF OLD.is_mutual THEN
            UPDATE subscription_service.user_stats 
            SET mutual_followers_count = GREATEST(0, mutual_followers_count - 1)
            WHERE user_id IN (OLD.subscriber_id, OLD.target_user_id);
            
            -- Снимаем флаг взаимности с обратной подписки
            UPDATE subscription_service.subscriptions 
            SET is_mutual = FALSE 
            WHERE subscriber_id = OLD.target_user_id AND target_user_id = OLD.subscriber_id;
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER subscription_stats_trigger
    AFTER INSERT OR DELETE ON subscription_service.subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_user_stats();

-- Функция для автоматического пересчета рейтингов книг
CREATE OR REPLACE FUNCTION update_book_ratings_summary()
RETURNS TRIGGER AS $$
BEGIN
    -- Пересчитываем статистику при изменении оценок
    WITH rating_stats AS (
        SELECT 
            book_id,
            COUNT(*) as total_ratings,
            SUM(rating_value) as sum_ratings,
            AVG(rating_value) as average_rating,
            COUNT(CASE WHEN rating_value = 1 THEN 1 END) as rating_1_count,
            COUNT(CASE WHEN rating_value = 2 THEN 1 END) as rating_2_count,
            COUNT(CASE WHEN rating_value = 3 THEN 1 END) as rating_3_count,
            COUNT(CASE WHEN rating_value = 4 THEN 1 END) as rating_4_count,
            COUNT(CASE WHEN rating_value = 5 THEN 1 END) as rating_5_count
        FROM rating_service.ratings
        WHERE book_id = COALESCE(NEW.book_id, OLD.book_id)
        GROUP BY book_id
    )
    INSERT INTO rating_service.book_ratings_summary (
        book_id, total_ratings, sum_ratings, average_rating,
        rating_1_count, rating_2_count, rating_3_count, rating_4_count, rating_5_count,
        last_calculated
    )
    SELECT 
        book_id, total_ratings, sum_ratings, average_rating,
        rating_1_count, rating_2_count, rating_3_count, rating_4_count, rating_5_count,
        CURRENT_TIMESTAMP
    FROM rating_stats
    ON CONFLICT (book_id) DO UPDATE SET
        total_ratings = EXCLUDED.total_ratings,
        sum_ratings = EXCLUDED.sum_ratings,
        average_rating = EXCLUDED.average_rating,
        rating_1_count = EXCLUDED.rating_1_count,
        rating_2_count = EXCLUDED.rating_2_count,
        rating_3_count = EXCLUDED.rating_3_count,
        rating_4_count = EXCLUDED.rating_4_count,
        rating_5_count = EXCLUDED.rating_5_count,
        last_calculated = EXCLUDED.last_calculated;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER rating_summary_trigger
    AFTER INSERT OR UPDATE OR DELETE ON rating_service.ratings
    FOR EACH ROW EXECUTE FUNCTION update_book_ratings_summary();

-- Добавляем тестовые книги в каталог
INSERT INTO catalog_service.books (book_id, title, author, genre, publication_year, description) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Преступление и наказание', 'Ф.М. Достоевский', 'Классика', 1866, 'Роман о моральных страданиях студента Раскольникова'),
    ('22222222-2222-2222-2222-222222222222', 'Мастер и Маргарита', 'М.А. Булгаков', 'Роман', 1967, 'Мистический роман о визите дьявола в Москву'),
    ('33333333-3333-3333-3333-333333333333', '1984', 'Джордж Оруэлл', 'Антиутопия', 1949, 'Роман-антиутопия о тоталитарном обществе'),
    ('44444444-4444-4444-4444-444444444444', 'Война и мир', 'Л.Н. Толстой', 'Классика', 1869, 'Эпопея о русском обществе во время войн с Наполеоном'),
    ('55555555-5555-5555-5555-555555555555', 'Гарри Поттер и философский камень', 'Дж.К. Роулинг', 'Фэнтези', 1997, 'Первая книга о юном волшебнике Гарри Поттере'),
    ('66666666-6666-6666-6666-666666666666', 'Маленький принц', 'Антуан де Сент-Экзюпери', 'Притча', 1943, 'Философская сказка о маленьком мальчике с астероида'),
    ('77777777-7777-7777-7777-777777777777', 'Три товарища', 'Эрих Мария Ремарк', 'Роман', 1936, 'Роман о дружбе и любви в послевоенной Германии'),
    ('88888888-8888-8888-8888-888888888888', 'Улисс', 'Джеймс Джойс', 'Модернизм', 1922, 'Сложный роман о одном дне в Дублине'),
    ('99999999-9999-9999-9999-999999999999', 'Анна Каренина', 'Л.Н. Толстой', 'Классика', 1877, 'Роман о трагической любви замужней женщины'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Сто лет одиночества', 'Габриэль Гарсия Маркес', 'Магический реализм', 1967, 'Семейная сага в вымышленном городе Макондо')
ON CONFLICT DO NOTHING;

-- Добавляем тестовых пользователей
INSERT INTO user_service.users (user_id, username, email, password_hash) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'ivan_ivanov', 'ivan@example.com', 'hash_ivan123'),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'maria_petrova', 'maria@example.com', 'hash_maria123'),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'alexey_sidorov', 'alexey@example.com', 'hash_alexey123'),
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'olga_kuznetsova', 'olga@example.com', 'hash_olga123'),
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'dmitry_popov', 'dmitry@example.com', 'hash_dmitry123')
ON CONFLICT DO NOTHING;

-- Добавляем тестовые подписки
INSERT INTO subscription_service.subscriptions (subscriber_id, target_user_id, subscription_type) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'regular'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'regular'),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'regular'), -- Взаимная подписка
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'regular'),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'regular')  -- Взаимная подписка
ON CONFLICT DO NOTHING;

-- Добавляем тестовые оценки
INSERT INTO rating_service.ratings (user_id, book_id, rating_value) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 5),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 4),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 4),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333', 5),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', '44444444-4444-4444-4444-444444444444', 3),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', '55555555-5555-5555-5555-555555555555', 5)
ON CONFLICT DO NOTHING;

-- Добавляем тестовые отзывы
INSERT INTO review_service.reviews (user_id, book_id, title, content, rating_value) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Великолепно!', 'Один из лучших романов, которые я читал. Глубокий психологический анализ.', 5),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'Интересно, но сложно', 'Много аллегорий, нужно перечитывать чтобы понять все слои.', 4),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', '55555555-5555-5555-5555-555555555555', 'Отлично для детей и взрослых', 'Волшебный мир, который захватывает с первых страниц.', 5)
ON CONFLICT DO NOTHING;

-- Добавляем тестовые книги в библиотеки пользователей
INSERT INTO library_service.user_libraries (user_id, book_id, shelf_type) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'finished'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 'reading'),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333', 'want_to_read'),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', '44444444-4444-4444-4444-444444444444', 'finished')
ON CONFLICT DO NOTHING;

-- Добавляем тестовый прогресс чтения
INSERT INTO reading_service.reading_progress (user_id, book_id, current_page, total_pages, reading_status) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 150, 480, 'reading'),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333', 0, 328, 'not_started'),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', '44444444-4444-4444-4444-444444444444', 1224, 1224, 'finished')
ON CONFLICT DO NOTHING;

-- Добавляем тестовые закладки
INSERT INTO reading_service.bookmarks (user_id, book_id, page_number, note) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 45, 'Интересный момент с котом'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 120, 'Начало балла у Сатаны')
ON CONFLICT DO NOTHING;