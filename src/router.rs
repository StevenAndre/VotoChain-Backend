use axum::{routing::{get, post}, Router};
use std::sync::Arc;
use sqlx::PgPool;
mod handlers;

pub fn router(pool: Arc<PgPool>) -> Router {
    Router::new()
        .route("/", get(|| async { "VOTOCOIN OK" }))
        .route("/students", get(handlers::students::list_students).post(handlers::students::create_student))
        .with_state(pool)
}