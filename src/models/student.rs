use serde::Serialize;
use sqlx::FromRow;
use chrono::NaiveDateTime;

#[derive(Serialize, FromRow)]
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
    pub is_active: bool,
    pub is_verified: bool,
    pub created_at: Option<NaiveDateTime>,
    pub updated_at: Option<NaiveDateTime>,
}
