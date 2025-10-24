use serde::Deserialize;

#[derive(Deserialize)]
pub struct CreateStudent {
    pub student_id: String,
    pub wallet_address: Option<String>,
    pub email: Option<String>,
    pub full_name: String,
    pub phone: Option<String>,
    pub faculty: Option<String>,
    pub career: Option<String>,
    pub semester: Option<i32>,
    pub is_verified: bool,
}
