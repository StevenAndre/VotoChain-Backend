use axum::{
    routing::{get, post, put, delete},
    Router,
};
use tower_http::cors::{Any, CorsLayer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use std::net::SocketAddr;

mod config;
mod error;
mod models;
mod handlers;
mod repository;

use config::AppState;

#[tokio::main]
async fn main() -> anyhow::Result<()> {

    dotenv::dotenv().ok();


    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info,sqlx=warn".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();


    let state = AppState::new().await?;


    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);


    let app = Router::new()
        .route("/health", get(health_check))
        .nest("/api/v1/students", students_routes())
        .layer(cors)
        .with_state(state);


    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    tracing::info!("🚀 Server running on http://{}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn health_check() -> &'static str {
    "OK"
}

fn students_routes() -> Router<AppState> {
    Router::new()
        .route("/", get(handlers::student_handler::list_students))
        .route("/", post(handlers::student_handler::create_student))
        .route("/:id", get(handlers::student_handler::get_student))
        .route("/:id", put(handlers::student_handler::update_student))
        .route("/:id", delete(handlers::student_handler::delete_student))
        .route("/student-id/:student_id", get(handlers::student_handler::get_by_student_id))
        .route("/wallet/:wallet", get(handlers::student_handler::get_by_wallet))
        .route("/:id/verify", post(handlers::student_handler::verify_student))
}