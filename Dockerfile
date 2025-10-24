# Etapa de construcción
FROM rust:1.85.0 AS builder

# Instalar dependencias necesarias
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de trabajo
WORKDIR /app

# Copiar manifiestos
COPY Cargo.toml Cargo.lock ./

# Crear un proyecto dummy para cachear dependencias
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release && \
    rm -rf src

# Copiar el código fuente real
COPY . .

# Forzar reconstrucción del binario
RUN touch src/main.rs

# Compilar la aplicación en modo release
RUN cargo build --release

# Etapa final - imagen ligera
FROM debian:bookworm-slim

# Instalar dependencias de runtime
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Crear usuario no-root
RUN useradd -m -u 1001 appuser

WORKDIR /app

# Copiar el binario compilado desde la etapa de construcción
COPY --from=builder /app/target/release/votochain-api /app/app

# Cambiar permisos y usuario
RUN chown -R appuser:appuser /app

USER appuser

# Exponer el puerto
EXPOSE 3000

# Variables de entorno por defecto
ENV RUST_LOG=info

# Comando para ejecutar la aplicación
CMD ["./app"]