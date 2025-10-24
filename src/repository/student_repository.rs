use crate::error::AppError;
use crate::models::student::{CreateStudentRequest, Student, UpdateStudentRequest};
use sqlx::PgPool;

pub struct StudentRepository;

impl StudentRepository {
    pub async fn find_all(pool: &PgPool) -> Result<Vec<Student>, AppError> {
        let students = sqlx::query_as::<_, Student>(
            "SELECT * FROM students ORDER BY created_at DESC"
        )
            .fetch_all(pool)
            .await?;

        Ok(students)
    }

    pub async fn find_by_id(pool: &PgPool, id: i32) -> Result<Student, AppError> {
        let student = sqlx::query_as::<_, Student>(
            "SELECT * FROM students WHERE id = $1"
        )
            .bind(id)
            .fetch_one(pool)
            .await
            .map_err(|e| match e {
                sqlx::Error::RowNotFound => AppError::NotFound(format!("Student with id {} not found", id)),
                _ => AppError::Database(e),
            })?;

        Ok(student)
    }

    pub async fn find_by_student_id(pool: &PgPool, student_id: &str) -> Result<Student, AppError> {
        let student = sqlx::query_as::<_, Student>(
            "SELECT * FROM students WHERE student_id = $1"
        )
            .bind(student_id)
            .fetch_one(pool)
            .await
            .map_err(|e| match e {
                sqlx::Error::RowNotFound => AppError::NotFound(format!("Student with student_id {} not found", student_id)),
                _ => AppError::Database(e),
            })?;

        Ok(student)
    }

    pub async fn find_by_wallet(pool: &PgPool, wallet: &str) -> Result<Student, AppError> {
        let student = sqlx::query_as::<_, Student>(
            "SELECT * FROM students WHERE wallet_address = $1"
        )
            .bind(wallet)
            .fetch_one(pool)
            .await
            .map_err(|e| match e {
                sqlx::Error::RowNotFound => AppError::NotFound(format!("Student with wallet {} not found", wallet)),
                _ => AppError::Database(e),
            })?;

        Ok(student)
    }

    pub async fn create(pool: &PgPool, req: CreateStudentRequest) -> Result<Student, AppError> {
        let student = sqlx::query_as::<_, Student>(
            r#"
            INSERT INTO students (student_id, wallet_address, email, full_name, phone, faculty, career, semester)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING *
            "#
        )
            .bind(&req.student_id)
            .bind(&req.wallet_address)
            .bind(&req.email)
            .bind(&req.full_name)
            .bind(&req.phone)
            .bind(&req.faculty)
            .bind(&req.career)
            .bind(req.semester)
            .fetch_one(pool)
            .await
            .map_err(|e| match e {
                sqlx::Error::Database(db_err) if db_err.constraint() == Some("students_student_id_key") => {
                    AppError::Conflict("Student ID already exists".to_string())
                }
                sqlx::Error::Database(db_err) if db_err.constraint() == Some("students_wallet_address_key") => {
                    AppError::Conflict("Wallet address already exists".to_string())
                }
                _ => AppError::Database(e),
            })?;

        Ok(student)
    }

    pub async fn update(pool: &PgPool, id: i32, req: UpdateStudentRequest) -> Result<Student, AppError> {
        let student = sqlx::query_as::<_, Student>(
            r#"
            UPDATE students
            SET
                wallet_address = COALESCE($1, wallet_address),
                email = COALESCE($2, email),
                full_name = COALESCE($3, full_name),
                phone = COALESCE($4, phone),
                faculty = COALESCE($5, faculty),
                career = COALESCE($6, career),
                semester = COALESCE($7, semester),
                is_active = COALESCE($8, is_active),
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $9
            RETURNING *
            "#
        )
            .bind(&req.wallet_address)
            .bind(&req.email)
            .bind(&req.full_name)
            .bind(&req.phone)
            .bind(&req.faculty)
            .bind(&req.career)
            .bind(req.semester)
            .bind(req.is_active)
            .bind(id)
            .fetch_one(pool)
            .await
            .map_err(|e| match e {
                sqlx::Error::RowNotFound => AppError::NotFound(format!("Student with id {} not found", id)),
                _ => AppError::Database(e),
            })?;

        Ok(student)
    }

    pub async fn verify(pool: &PgPool, id: i32) -> Result<Student, AppError> {
        let student = sqlx::query_as::<_, Student>(
            "UPDATE students SET is_verified = true, updated_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING *"
        )
            .bind(id)
            .fetch_one(pool)
            .await
            .map_err(|e| match e {
                sqlx::Error::RowNotFound => AppError::NotFound(format!("Student with id {} not found", id)),
                _ => AppError::Database(e),
            })?;

        Ok(student)
    }

    pub async fn delete(pool: &PgPool, id: i32) -> Result<(), AppError> {
        let result = sqlx::query("DELETE FROM students WHERE id = $1")
            .bind(id)
            .execute(pool)
            .await?;

        if result.rows_affected() == 0 {
            return Err(AppError::NotFound(format!("Student with id {} not found", id)));
        }

        Ok(())
    }
}