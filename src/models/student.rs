use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Student {
    pub id: i32,
    pub student_id: String,
    pub wallet_address: Option<String>,
    pub email: Option<String>,
    pub full_name: String,
    pub phone: Option<String>,
    pub faculty: Option<String>,
    pub career: Option<String>,
    pub semester: Option<i32>,
    pub is_active: Option<bool>,
    pub is_verified: Option<bool>,
    pub created_at: Option<NaiveDateTime>,
    pub updated_at: Option<NaiveDateTime>,
}

#[derive(Debug, Deserialize)]
pub struct CreateStudentRequest {
    pub student_id: String,
    pub wallet_address: Option<String>,
    pub email: Option<String>,
    pub full_name: String,
    pub phone: Option<String>,
    pub faculty: Option<String>,
    pub career: Option<String>,
    pub semester: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateStudentRequest {
    pub wallet_address: Option<String>,
    pub email: Option<String>,
    pub full_name: Option<String>,
    pub phone: Option<String>,
    pub faculty: Option<String>,
    pub career: Option<String>,
    pub semester: Option<i32>,
    pub is_active: Option<bool>,
}

#[derive(Debug, Serialize)]
pub struct StudentResponse {
    pub id: i32,
    pub student_id: String,
    pub wallet_address: Option<String>,
    pub email: Option<String>,
    pub full_name: String,
    pub phone: Option<String>,
    pub faculty: Option<String>,
    pub career: Option<String>,
    pub semester: Option<i32>,
    pub is_active: bool,
    pub is_verified: bool,
    pub created_at: NaiveDateTime,
}

impl From<Student> for StudentResponse {
    fn from(student: Student) -> Self {
        Self {
            id: student.id,
            student_id: student.student_id,
            wallet_address: student.wallet_address,
            email: student.email,
            full_name: student.full_name,
            phone: student.phone,
            faculty: student.faculty,
            career: student.career,
            semester: student.semester,
            is_active: student.is_active.unwrap_or(true),
            is_verified: student.is_verified.unwrap_or(false),
            created_at: student.created_at.unwrap_or_else(|| chrono::Local::now().naive_local()),
        }
    }
}