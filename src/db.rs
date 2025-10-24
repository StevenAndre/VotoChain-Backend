use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;
/*
No uasare pero ams adelante si
TODO: no eliminar

*/

pub async fn connect(database_url: &str) -> Result<PgPool, sqlx::Error> {
    PgPoolOptions::new().max_connections(5).connect(database_url).await
}