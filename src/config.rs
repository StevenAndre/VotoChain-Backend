use std::env;


pub struct Config {
    pub database_url: String,
    pub host: String,
    pub port: u16,
}


impl Config {
    pub fn from_env() -> Self {
        dotenvy::dotenv().ok();
        let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
        let host = env::var("HOST").unwrap_or_else(|_| "127.0.0.1".into());
        let port = env::var("PORT").ok().and_then(|p| p.parse().ok()).unwrap_or(5432);
        Self { database_url, host, port }
    }
}