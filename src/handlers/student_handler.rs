use axum::{extract::State, Json};
use http::StatusCode;
use std::sync::Arc;
use sqlx::PgPool;
use super::super::models::student::Student;
use crate::dto::student::CreateStudent;

pub async fn list_students(State(pool): State<Arc<PgPool>>) -> Result<Json<Vec<Student>>, (StatusCode, String)> {
    let rows = sqlx::query_as::<_, Student>(
        "SELECT id, student_id, wallet_address, email, full_name, phone, faculty, career, semester, is_active, is_verified, created_at, updated_at FROM students ORDER BY id"
    )
        .fetch_all(&*pool)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    Ok(Json(rows))
}

pub async fn create_student(State(pool): State<Arc<PgPool>>, Json(payload): Json<CreateStudent>) -> Result<(StatusCode, Json<Student>), (StatusCode, String)> {
    let row = sqlx::query_as::<_, Student>(
        "INSERT INTO students (student_id, wallet_address, email, full_name, phone, faculty, career, semester, is_verified) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING id, student_id, wallet_address, email, full_name, phone, faculty, career, semester, is_active, is_verified, created_at, updated_at"
    )
        .bind(payload.student_id)
        .bind(payload.wallet_address)
        .bind(payload.email)
        .bind(payload.full_name)
        .bind(payload.phone)
        .bind(payload.faculty)
        .bind(payload.career)
        .bind(payload.semester)
        .bind(payload.is_verified)
        .fetch_one(&*pool)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok((StatusCode::CREATED, Json(row)))
}
