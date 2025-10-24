use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use crate::{
    config::AppState,
    error::AppError,
    models::student::{CreateStudentRequest, StudentResponse, UpdateStudentRequest},
    repository::student_repository::StudentRepository,
};

pub async fn list_students(
    State(state): State<AppState>,
) -> Result<Json<Vec<StudentResponse>>, AppError> {
    let students = StudentRepository::find_all(&state.db).await?;
    let response: Vec<StudentResponse> = students.into_iter().map(Into::into).collect();
    Ok(Json(response))
}

pub async fn get_student(
    State(state): State<AppState>,
    Path(id): Path<i32>,
) -> Result<Json<StudentResponse>, AppError> {
    let student = StudentRepository::find_by_id(&state.db, id).await?;
    Ok(Json(student.into()))
}

pub async fn get_by_student_id(
    State(state): State<AppState>,
    Path(student_id): Path<String>,
) -> Result<Json<StudentResponse>, AppError> {
    let student = StudentRepository::find_by_student_id(&state.db, &student_id).await?;
    Ok(Json(student.into()))
}

pub async fn get_by_wallet(
    State(state): State<AppState>,
    Path(wallet): Path<String>,
) -> Result<Json<StudentResponse>, AppError> {
    let student = StudentRepository::find_by_wallet(&state.db, &wallet).await?;
    Ok(Json(student.into()))
}

pub async fn create_student(
    State(state): State<AppState>,
    Json(req): Json<CreateStudentRequest>,
) -> Result<(StatusCode, Json<StudentResponse>), AppError> {
    let student = StudentRepository::create(&state.db, req).await?;
    Ok((StatusCode::CREATED, Json(student.into())))
}

pub async fn update_student(
    State(state): State<AppState>,
    Path(id): Path<i32>,
    Json(req): Json<UpdateStudentRequest>,
) -> Result<Json<StudentResponse>, AppError> {
    let student = StudentRepository::update(&state.db, id, req).await?;
    Ok(Json(student.into()))
}

pub async fn verify_student(
    State(state): State<AppState>,
    Path(id): Path<i32>,
) -> Result<Json<StudentResponse>, AppError> {
    let student = StudentRepository::verify(&state.db, id).await?;
    Ok(Json(student.into()))
}

pub async fn delete_student(
    State(state): State<AppState>,
    Path(id): Path<i32>,
) -> Result<StatusCode, AppError> {
    StudentRepository::delete(&state.db, id).await?;
    Ok(StatusCode::NO_CONTENT)
}