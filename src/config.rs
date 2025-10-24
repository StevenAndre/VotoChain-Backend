use sqlx::{postgres::PgPoolOptions, PgPool};
use std::time::Duration;

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
}

impl AppState {
    pub async fn new() -> anyhow::Result<Self> {
        let database_url = std::env::var("DATABASE_URL")
            .unwrap_or_else(|_| "postgresql://user:secret@localhost/votochain_db".to_string());

        let pool = PgPoolOptions::new()
            .max_connections(20)
            .acquire_timeout(Duration::from_secs(3))
            .connect(&database_url)
            .await?;

        tracing::info!("✅ Connected to database");

        Ok(Self { db: pool })
    }
}