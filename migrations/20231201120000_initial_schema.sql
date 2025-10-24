-- ============================================
-- VOTO-CHAIN - SCRIPT COMPLETO DE BASE DE DATOS
-- Sistema de Votación Descentralizada
-- ============================================

-- Conectar a la base de datos
-- psql -U votochain_user -d votochain_db -h localhost

BEGIN;

-- ============================================
-- 1. ELIMINAR TABLAS EXISTENTES (si existen)
-- ============================================

DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS user_sessions CASCADE;
DROP TABLE IF EXISTS student_verifications CASCADE;
DROP TABLE IF EXISTS election_results CASCADE;
DROP TABLE IF EXISTS vote_logs CASCADE;
DROP TABLE IF EXISTS candidates CASCADE;
DROP TABLE IF EXISTS elections CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS system_config CASCADE;

-- Eliminar vistas
DROP VIEW IF EXISTS active_elections_stats CASCADE;
DROP VIEW IF EXISTS students_vote_status CASCADE;

-- Eliminar funciones
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS log_audit() CASCADE;
DROP FUNCTION IF EXISTS get_election_winner(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS has_student_voted(VARCHAR, INTEGER) CASCADE;

-- ============================================
-- 2. CREAR TABLAS PRINCIPALES
-- ============================================

-- Tabla de Estudiantes
CREATE TABLE students (
                          id SERIAL PRIMARY KEY,
                          student_id VARCHAR(50) UNIQUE NOT NULL,
                          wallet_address VARCHAR(100) UNIQUE,
                          email VARCHAR(100),
                          full_name VARCHAR(200) NOT NULL,
                          phone VARCHAR(20),
                          faculty VARCHAR(100),
                          career VARCHAR(100),
                          semester INTEGER,
                          is_active BOOLEAN DEFAULT true,
                          is_verified BOOLEAN DEFAULT false,
                          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Elecciones
CREATE TABLE elections (
                           id SERIAL PRIMARY KEY,
                           program_id VARCHAR(100) NOT NULL,
                           title VARCHAR(200) NOT NULL,
                           description TEXT,
                           start_time TIMESTAMP NOT NULL,
                           end_time TIMESTAMP NOT NULL,
                           is_active BOOLEAN DEFAULT true,
                           created_by VARCHAR(100),
                           total_voters INTEGER DEFAULT 0,
                           total_votes_cast INTEGER DEFAULT 0,
                           voter_turnout_percentage DECIMAL(5,2) DEFAULT 0.00,
                           blockchain_transaction_signature VARCHAR(200),
                           status VARCHAR(20) DEFAULT 'DRAFT',
                           created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                           updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                           CONSTRAINT check_dates CHECK (end_time > start_time),
                           CONSTRAINT check_status CHECK (status IN ('DRAFT', 'ACTIVE', 'COMPLETED', 'CANCELLED'))
);

-- Tabla de Candidatos
CREATE TABLE candidates (
                            id SERIAL PRIMARY KEY,
                            election_id INTEGER NOT NULL REFERENCES elections(id) ON DELETE CASCADE,
                            name VARCHAR(200) NOT NULL,
                            photo_url TEXT,
                            proposal TEXT,
                            biography TEXT,
                            candidate_index INTEGER NOT NULL,
                            party_name VARCHAR(100),
                            contact_info JSONB,
                            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                            UNIQUE(election_id, candidate_index)
);

-- Tabla de Registro de Votos (metadata)
CREATE TABLE vote_logs (
                           id SERIAL PRIMARY KEY,
                           election_id INTEGER NOT NULL REFERENCES elections(id) ON DELETE CASCADE,
                           wallet_address VARCHAR(100) NOT NULL,
                           transaction_signature VARCHAR(200) UNIQUE NOT NULL,
                           block_time TIMESTAMP,
                           voted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                           UNIQUE(election_id, wallet_address)
);

-- ============================================
-- 3. TABLAS AUXILIARES
-- ============================================

-- Tabla de Auditoría
CREATE TABLE audit_log (
                           id SERIAL PRIMARY KEY,
                           table_name VARCHAR(50) NOT NULL,
                           action VARCHAR(20) NOT NULL,
                           record_id INTEGER,
                           old_data JSONB,
                           new_data JSONB,
                           user_wallet VARCHAR(100),
                           ip_address INET,
                           user_agent TEXT,
                           created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Sesiones
CREATE TABLE user_sessions (
                               id SERIAL PRIMARY KEY,
                               student_id VARCHAR(50) REFERENCES students(student_id) ON DELETE CASCADE,
                               wallet_address VARCHAR(100) NOT NULL,
                               session_token VARCHAR(255) UNIQUE NOT NULL,
                               refresh_token VARCHAR(255) UNIQUE,
                               ip_address INET,
                               user_agent TEXT,
                               expires_at TIMESTAMP NOT NULL,
                               is_active BOOLEAN DEFAULT true,
                               created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                               last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Verificaciones
CREATE TABLE student_verifications (
                                       id SERIAL PRIMARY KEY,
                                       student_id VARCHAR(50) NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
                                       verification_type VARCHAR(50) NOT NULL,
                                       verification_code VARCHAR(100),
                                       verification_data JSONB,
                                       status VARCHAR(20) DEFAULT 'PENDING',
                                       verified_by VARCHAR(100),
                                       verified_at TIMESTAMP,
                                       expires_at TIMESTAMP,
                                       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                       CONSTRAINT check_verification_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'EXPIRED'))
);

-- Tabla de Notificaciones
CREATE TABLE notifications (
                               id SERIAL PRIMARY KEY,
                               student_id VARCHAR(50) REFERENCES students(student_id) ON DELETE CASCADE,
                               title VARCHAR(200) NOT NULL,
                               message TEXT NOT NULL,
                               notification_type VARCHAR(50) NOT NULL,
                               is_read BOOLEAN DEFAULT false,
                               metadata JSONB,
                               created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                               read_at TIMESTAMP,
                               CONSTRAINT check_notification_type CHECK (notification_type IN ('ELECTION_START', 'ELECTION_END', 'VOTE_CONFIRMED', 'SYSTEM', 'WARNING', 'INFO'))
);

-- Tabla de Configuración
CREATE TABLE system_config (
                               id SERIAL PRIMARY KEY,
                               config_key VARCHAR(100) UNIQUE NOT NULL,
                               config_value TEXT NOT NULL,
                               config_type VARCHAR(20) DEFAULT 'STRING',
                               description TEXT,
                               is_public BOOLEAN DEFAULT false,
                               updated_by VARCHAR(100),
                               updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                               CONSTRAINT check_config_type CHECK (config_type IN ('STRING', 'NUMBER', 'BOOLEAN', 'JSON'))
);

-- Tabla de Resultados (cache)
CREATE TABLE election_results (
                                  id SERIAL PRIMARY KEY,
                                  election_id INTEGER UNIQUE NOT NULL REFERENCES elections(id) ON DELETE CASCADE,
                                  results_data JSONB NOT NULL,
                                  total_votes INTEGER DEFAULT 0,
                                  winner_candidate_id INTEGER REFERENCES candidates(id),
                                  is_final BOOLEAN DEFAULT false,
                                  calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 4. ÍNDICES PARA PERFORMANCE
-- ============================================

-- Índices en students
CREATE INDEX idx_students_wallet ON students(wallet_address);
CREATE INDEX idx_students_student_id ON students(student_id);
CREATE INDEX idx_students_email ON students(email);
CREATE INDEX idx_students_active ON students(is_active);

-- Índices en elections
CREATE INDEX idx_elections_active ON elections(is_active);
CREATE INDEX idx_elections_status ON elections(status);
CREATE INDEX idx_elections_dates ON elections(start_time, end_time);
CREATE INDEX idx_elections_program_id ON elections(program_id);

-- Índices en candidates
CREATE INDEX idx_candidates_election ON candidates(election_id);

-- Índices en vote_logs
CREATE INDEX idx_vote_logs_election ON vote_logs(election_id);
CREATE INDEX idx_vote_logs_wallet ON vote_logs(wallet_address);
CREATE INDEX idx_vote_logs_transaction ON vote_logs(transaction_signature);
CREATE INDEX idx_vote_logs_date ON vote_logs(voted_at);

-- Índices en audit_log
CREATE INDEX idx_audit_table ON audit_log(table_name);
CREATE INDEX idx_audit_wallet ON audit_log(user_wallet);
CREATE INDEX idx_audit_created ON audit_log(created_at);

-- Índices en sessions
CREATE INDEX idx_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_sessions_wallet ON user_sessions(wallet_address);
CREATE INDEX idx_sessions_active ON user_sessions(is_active, expires_at);

-- Índices en verifications
CREATE INDEX idx_verifications_student ON student_verifications(student_id);
CREATE INDEX idx_verifications_status ON student_verifications(status);

-- Índices en notifications
CREATE INDEX idx_notifications_student ON notifications(student_id);
CREATE INDEX idx_notifications_unread ON notifications(student_id, is_read);
CREATE INDEX idx_notifications_type ON notifications(notification_type);

-- Índices en results
CREATE INDEX idx_results_election ON election_results(election_id);

-- ============================================
-- 5. TRIGGERS Y FUNCIONES
-- ============================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger a tablas con updated_at
CREATE TRIGGER update_students_updated_at
    BEFORE UPDATE ON students
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_elections_updated_at
    BEFORE UPDATE ON elections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_system_config_updated_at
    BEFORE UPDATE ON system_config
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Función para audit log automático
CREATE OR REPLACE FUNCTION log_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log(table_name, action, record_id, old_data)
        VALUES (TG_TABLE_NAME, TG_OP, OLD.id, row_to_json(OLD));
RETURN OLD;
ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log(table_name, action, record_id, old_data, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.id, row_to_json(OLD), row_to_json(NEW));
RETURN NEW;
ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log(table_name, action, record_id, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.id, row_to_json(NEW));
RETURN NEW;
END IF;
END;
$$ LANGUAGE plpgsql;

-- Aplicar audit triggers
CREATE TRIGGER audit_students
    AFTER INSERT OR UPDATE OR DELETE ON students
    FOR EACH ROW EXECUTE FUNCTION log_audit();

CREATE TRIGGER audit_elections
    AFTER INSERT OR UPDATE OR DELETE ON elections
    FOR EACH ROW EXECUTE FUNCTION log_audit();

CREATE TRIGGER audit_candidates
    AFTER INSERT OR UPDATE OR DELETE ON candidates
    FOR EACH ROW EXECUTE FUNCTION log_audit();

CREATE TRIGGER audit_vote_logs
    AFTER INSERT OR DELETE ON vote_logs
    FOR EACH ROW EXECUTE FUNCTION log_audit();

-- ============================================
-- 6. VISTAS ÚTILES
-- ============================================

-- Vista de elecciones activas con estadísticas
CREATE VIEW active_elections_stats AS
SELECT
    e.id,
    e.title,
    e.description,
    e.start_time,
    e.end_time,
    e.total_votes_cast,
    e.total_voters,
    e.voter_turnout_percentage,
    e.status,
    COUNT(DISTINCT c.id) as total_candidates,
    CASE
        WHEN CURRENT_TIMESTAMP < e.start_time THEN 'UPCOMING'
        WHEN CURRENT_TIMESTAMP BETWEEN e.start_time AND e.end_time THEN 'ACTIVE'
        WHEN CURRENT_TIMESTAMP > e.end_time THEN 'ENDED'
        END as current_status
FROM elections e
         LEFT JOIN candidates c ON c.election_id = e.id
WHERE e.is_active = true
GROUP BY e.id;

-- Vista de estudiantes con estado de voto
CREATE VIEW students_vote_status AS
SELECT
    s.id,
    s.student_id,
    s.full_name,
    s.email,
    s.wallet_address,
    s.is_verified,
    COUNT(vl.id) as total_votes_cast,
    MAX(vl.voted_at) as last_vote_time
FROM students s
         LEFT JOIN vote_logs vl ON vl.wallet_address = s.wallet_address
GROUP BY s.id;

-- ============================================
-- 7. FUNCIONES ÚTILES
-- ============================================

-- Función para obtener ganador de elección
CREATE OR REPLACE FUNCTION get_election_winner(election_id_param INTEGER)
RETURNS TABLE(
    candidate_id INTEGER,
    candidate_name VARCHAR,
    total_votes BIGINT
) AS $$
BEGIN
RETURN QUERY
SELECT
    c.id,
    c.name,
    COUNT(vl.id) as votes
FROM candidates c
         LEFT JOIN vote_logs vl ON vl.election_id = c.election_id
WHERE c.election_id = election_id_param
GROUP BY c.id, c.name
ORDER BY votes DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Función para verificar si estudiante ya votó
CREATE OR REPLACE FUNCTION has_student_voted(
    wallet_param VARCHAR,
    election_id_param INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
RETURN EXISTS (
    SELECT 1 FROM vote_logs
    WHERE wallet_address = wallet_param
      AND election_id = election_id_param
);
END;
$$ LANGUAGE plpgsql;

-- Función para calcular porcentaje de participación
CREATE OR REPLACE FUNCTION calculate_voter_turnout(election_id_param INTEGER)
RETURNS DECIMAL AS $$
DECLARE
votes_cast INTEGER;
    total_eligible INTEGER;
    turnout DECIMAL;
BEGIN
SELECT total_votes_cast, total_voters
INTO votes_cast, total_eligible
FROM elections
WHERE id = election_id_param;

IF total_eligible > 0 THEN
        turnout := (votes_cast::DECIMAL / total_eligible::DECIMAL) * 100;
ELSE
        turnout := 0;
END IF;

RETURN ROUND(turnout, 2);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. DATOS DE CONFIGURACIÓN
-- ============================================

INSERT INTO system_config (config_key, config_value, config_type, description, is_public) VALUES
                                                                                              ('APP_NAME', 'VOTO-CHAIN', 'STRING', 'Nombre de la aplicación', true),
                                                                                              ('APP_VERSION', '1.0.0', 'STRING', 'Versión de la aplicación', true),
                                                                                              ('MAINTENANCE_MODE', 'false', 'BOOLEAN', 'Modo de mantenimiento', true),
                                                                                              ('MIN_VOTE_INTERVAL_SECONDS', '5', 'NUMBER', 'Tiempo mínimo entre votos', false),
                                                                                              ('MAX_ELECTIONS_SIMULTANEOUS', '3', 'NUMBER', 'Elecciones simultáneas máximas', false),
                                                                                              ('SUPPORT_EMAIL', 'soporte@votochain.edu.pe', 'STRING', 'Email de soporte', true),
                                                                                              ('BLOCKCHAIN_NETWORK', 'devnet', 'STRING', 'Red de Solana', false),
                                                                                              ('VOTE_CONFIRMATION_REQUIRED', 'true', 'BOOLEAN', 'Requiere confirmación de voto', true),
                                                                                              ('ALLOW_VOTE_CHANGE', 'false', 'BOOLEAN', 'Permitir cambiar voto', true),
                                                                                              ('SESSION_EXPIRY_HOURS', '24', 'NUMBER', 'Horas de expiración de sesión', false),
                                                                                              ('MAX_LOGIN_ATTEMPTS', '5', 'NUMBER', 'Intentos máximos de login', false),
                                                                                              ('REQUIRE_EMAIL_VERIFICATION', 'true', 'BOOLEAN', 'Requiere verificación de email', false);

-- ============================================
-- 9. DATOS DE PRUEBA
-- ============================================

-- Estudiantes de prueba
INSERT INTO students (student_id, wallet_address, email, full_name, faculty, career, semester, is_verified) VALUES
                                                                                                                ('20220001', '6Wh6Qrm15kD4UXZxc7HGyqCivRfDwTgMtUrqkAWHivZC', 'estudiante1@unsm.edu.pe', 'Juan Pérez García', 'Ingeniería de Sistemas', 'Ingeniería de Software', 6, true),
                                                                                                                ('20220002', '7Xh7Rrn26lE5VYAyd8IHzrDjwSgEeTuNuVsXrjBmJwlD', 'estudiante2@unsm.edu.pe', 'María López Silva', 'Ingeniería de Sistemas', 'Ciencia de Datos', 5, true),
                                                                                                                ('20220003', '8Yh8Ssn37mF6WZBze9JIAsEkxThFfUvOvWtYskCnKxmE', 'estudiante3@unsm.edu.pe', 'Carlos Gómez Díaz', 'Ingeniería de Sistemas', 'Ciberseguridad', 7, true),
                                                                                                                ('20220004', '9Zh9Tto48nG7XaCaf0KJBtFlzUigGfWPwXuZtkDoLynF', 'estudiante4@unsm.edu.pe', 'Ana Torres Mendoza', 'Ingeniería de Sistemas', 'Inteligencia Artificial', 4, true),
                                                                                                                ('20220005', 'AZhATup59oH8YbDbg1LKCuGm0VjhHgXQxYvAulEpMzoG', 'estudiante5@unsm.edu.pe', 'Luis Ramírez Castro', 'Ingeniería de Sistemas', 'Desarrollo Web', 6, true),
                                                                                                                ('20220006', 'BZhBUvq60pH9ZcEch2MLDvHn1WkiIhYRyZwBvmFqNApH', 'estudiante6@unsm.edu.pe', 'Sofia Vargas Luna', 'Ingeniería de Sistemas', 'Blockchain', 8, true);

-- Elección de prueba
INSERT INTO elections (program_id, title, description, start_time, end_time, total_voters, status) VALUES
    ('9QfqUUxFJY6WNoaMydeyo12FHTWfHDxuuYwX21m6Fkgd',
     'Elección Presidente Estudiantil 2025',
     'Elección para el cargo de Presidente del Centro Federado de Estudiantes de la Facultad de Ingeniería de Sistemas e Informática',
     '2025-10-25 08:00:00',
     '2025-10-27 18:00:00',
     6,
     'ACTIVE');

-- Candidatos
INSERT INTO candidates (election_id, name, photo_url, proposal, biography, candidate_index, party_name) VALUES
                                                                                                            (1, 'Juan Pérez García', 'https://via.placeholder.com/300',
                                                                                                             'Mejorar la infraestructura tecnológica de la facultad, ampliar la conectividad WiFi en todos los ambientes y crear un laboratorio de innovación tecnológica.',
                                                                                                             'Estudiante de 8vo ciclo, con experiencia en gestión estudiantil. Ha participado en múltiples proyectos de desarrollo tecnológico.',
                                                                                                             0, 'Movimiento Innovación Tech'),

                                                                                                            (1, 'María López Silva', 'https://via.placeholder.com/300',
                                                                                                             'Ampliar el programa de becas estudiantiles, crear tutorías académicas gratuitas y mejorar el sistema de biblioteca digital.',
                                                                                                             'Estudiante destacada con promedio de 18. Coordinadora del programa de ayuda académica entre estudiantes.',
                                                                                                             1, 'Lista Progreso Estudiantil'),

                                                                                                            (1, 'Carlos Gómez Díaz', 'https://via.placeholder.com/300',
                                                                                                             'Fomentar actividades culturales y deportivas, crear más espacios recreativos y organizar eventos de integración interdisciplinaria.',
                                                                                                             'Capitán del equipo de fútbol de la facultad. Ha organizado múltiples eventos deportivos y culturales exitosos.',
                                                                                                             2, 'Movimiento Deportivo Cultural');

-- Notificaciones de prueba
INSERT INTO notifications (student_id, title, message, notification_type) VALUES
                                                                              ('20220001', '¡Bienvenido a VOTO-CHAIN!', 'Tu cuenta ha sido verificada exitosamente. Ya puedes participar en las elecciones estudiantiles.', 'SYSTEM'),
                                                                              ('20220001', 'Nueva elección disponible', 'Ya puedes emitir tu voto en: Elección Presidente Estudiantil 2025', 'ELECTION_START'),
                                                                              ('20220002', '¡Bienvenido a VOTO-CHAIN!', 'Tu cuenta ha sido verificada exitosamente. Ya puedes participar en las elecciones estudiantiles.', 'SYSTEM'),
                                                                              ('20220002', 'Nueva elección disponible', 'Ya puedes emitir tu voto en: Elección Presidente Estudiantil 2025', 'ELECTION_START'),
                                                                              ('20220003', 'Elección próxima a finalizar', 'Recuerda que la elección termina el 27 de octubre a las 18:00', 'WARNING');

COMMIT;