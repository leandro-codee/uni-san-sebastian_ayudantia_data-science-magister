-- init_db/01-init.sql
-- Script de inicialización para PostgreSQL

-- Crear base de datos para n8n (si no existe)
CREATE DATABASE n8n;

-- Usar la base de datos principal
\c datascience;

-- Crear extensiones útiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================================
-- TABLAS DE EJEMPLO PARA PRÁCTICA
-- ============================================================================

-- Tabla de productos
CREATE TABLE IF NOT EXISTS productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    categoria VARCHAR(50),
    precio DECIMAL(10,2),
    stock INTEGER,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de ventas
CREATE TABLE IF NOT EXISTS ventas (
    id SERIAL PRIMARY KEY,
    producto_id INTEGER REFERENCES productos(id),
    cantidad INTEGER NOT NULL,
    precio_unitario DECIMAL(10,2),
    total DECIMAL(10,2),
    fecha_venta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cliente_nombre VARCHAR(100),
    cliente_email VARCHAR(100)
);

-- Tabla de clientes
CREATE TABLE IF NOT EXISTS clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    telefono VARCHAR(20),
    direccion TEXT,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
);

-- Tabla de categorías
CREATE TABLE IF NOT EXISTS categorias (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    activa BOOLEAN DEFAULT TRUE
);

-- ============================================================================
-- DATOS DE EJEMPLO
-- ============================================================================

-- Insertar categorías
INSERT INTO categorias (nombre, descripcion) VALUES
('Electrónicos', 'Dispositivos electrónicos y gadgets'),
('Accesorios', 'Accesorios para computadoras y móviles'),
('Software', 'Licencias y software'),
('Gaming', 'Productos para gaming'),
('Hogar', 'Productos para el hogar inteligente')
ON CONFLICT (nombre) DO NOTHING;

-- Insertar productos de ejemplo
INSERT INTO productos (nombre, categoria, precio, stock, descripcion) VALUES
('Laptop Gaming RGB', 'Electrónicos', 1299.99, 15, 'Laptop gaming con RGB y alta performance'),
('Mouse Inalámbrico Pro', 'Accesorios', 29.99, 50, 'Mouse ergonómico inalámbrico con sensor óptico'),
('Teclado Mecánico RGB', 'Accesorios', 89.99, 30, 'Teclado mecánico con switches azules y RGB'),
('Monitor 4K Ultra', 'Electrónicos', 399.99, 12, 'Monitor 4K de 27 pulgadas con HDR'),
('Webcam HD 1080p', 'Accesorios', 59.99, 25, 'Webcam Full HD con micrófono integrado'),
('Auriculares Gaming', 'Gaming', 149.99, 20, 'Auriculares gaming con sonido envolvente 7.1'),
('SSD 1TB NVMe', 'Electrónicos', 129.99, 35, 'SSD NVMe de alta velocidad 1TB'),
('Hub USB-C', 'Accesorios', 39.99, 40, 'Hub USB-C con múltiples puertos'),
('Cámara Web 4K', 'Electrónicos', 199.99, 8, 'Cámara web 4K para streaming profesional'),
('Mousepad Gaming XL', 'Gaming', 24.99, 60, 'Mousepad gaming extra grande con base antideslizante')
ON CONFLICT DO NOTHING;

-- Insertar clientes de ejemplo
INSERT INTO clientes (nombre, email, telefono, direccion) VALUES
('Ana García', 'ana.garcia@email.com', '+56912345678', 'Las Condes, Santiago'),
('Carlos Rodríguez', 'carlos.r@email.com', '+56987654321', 'Providencia, Santiago'),
('María López', 'maria.lopez@email.com', '+56911111111', 'Ñuñoa, Santiago'),
('Pedro Martínez', 'pedro.m@email.com', '+56922222222', 'La Reina, Santiago'),
('Sofia Chen', 'sofia.chen@email.com', '+56933333333', 'Las Condes, Santiago')
ON CONFLICT (email) DO NOTHING;

-- Insertar ventas de ejemplo
INSERT INTO ventas (producto_id, cantidad, precio_unitario, total, cliente_nombre, cliente_email) VALUES
(1, 1, 1299.99, 1299.99, 'Ana García', 'ana.garcia@email.com'),
(2, 2, 29.99, 59.98, 'Carlos Rodríguez', 'carlos.r@email.com'),
(3, 1, 89.99, 89.99, 'María López', 'maria.lopez@email.com'),
(4, 1, 399.99, 399.99, 'Pedro Martínez', 'pedro.m@email.com'),
(5, 3, 59.99, 179.97, 'Sofia Chen', 'sofia.chen@email.com'),
(6, 1, 149.99, 149.99, 'Ana García', 'ana.garcia@email.com'),
(7, 2, 129.99, 259.98, 'Carlos Rodríguez', 'carlos.r@email.com'),
(8, 1, 39.99, 39.99, 'María López', 'maria.lopez@email.com'),
(2, 5, 29.99, 149.95, 'Pedro Martínez', 'pedro.m@email.com'),
(10, 2, 24.99, 49.98, 'Sofia Chen', 'sofia.chen@email.com')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- VISTAS ÚTILES PARA ANÁLISIS
-- ============================================================================

-- Vista de ventas con detalles de productos
CREATE OR REPLACE VIEW vista_ventas_detalle AS
SELECT 
    v.id as venta_id,
    v.fecha_venta,
    v.cliente_nombre,
    v.cliente_email,
    p.nombre as producto_nombre,
    p.categoria,
    v.cantidad,
    v.precio_unitario,
    v.total,
    (v.precio_unitario * v.cantidad) as subtotal_calculado
FROM ventas v
JOIN productos p ON v.producto_id = p.id;

-- Vista de resumen por categoría
CREATE OR REPLACE VIEW resumen_por_categoria AS
SELECT 
    p.categoria,
    COUNT(v.id) as total_ventas,
    SUM(v.cantidad) as unidades_vendidas,
    SUM(v.total) as ingresos_totales,
    AVG(v.total) as ticket_promedio,
    COUNT(DISTINCT v.cliente_email) as clientes_unicos
FROM ventas v
JOIN productos p ON v.producto_id = p.id
GROUP BY p.categoria
ORDER BY ingresos_totales DESC;

-- Vista de productos más vendidos
CREATE OR REPLACE VIEW productos_top_ventas AS
SELECT 
    p.id,
    p.nombre,
    p.categoria,
    p.precio,
    p.stock,
    COALESCE(SUM(v.cantidad), 0) as total_vendido,
    COALESCE(SUM(v.total), 0) as ingresos_generados,
    COUNT(v.id) as numero_transacciones
FROM productos p
LEFT JOIN ventas v ON p.id = v.producto_id
GROUP BY p.id, p.nombre, p.categoria, p.precio, p.stock
ORDER BY total_vendido DESC;

-- ============================================================================
-- FUNCIONES ÚTILES
-- ============================================================================

-- Función para actualizar timestamp de productos
CREATE OR REPLACE FUNCTION actualizar_fecha_modificacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar automáticamente fecha_actualizacion
DROP TRIGGER IF EXISTS trigger_actualizar_productos ON productos;
CREATE TRIGGER trigger_actualizar_productos
    BEFORE UPDATE ON productos
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_fecha_modificacion();

-- ============================================================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_productos_categoria ON productos(categoria);
CREATE INDEX IF NOT EXISTS idx_ventas_fecha ON ventas(fecha_venta);
CREATE INDEX IF NOT EXISTS idx_ventas_cliente_email ON ventas(cliente_email);
CREATE INDEX IF NOT EXISTS idx_ventas_producto_id ON ventas(producto_id);

-- ============================================================================
-- COMENTARIOS EN TABLAS
-- ============================================================================

COMMENT ON TABLE productos IS 'Catálogo de productos disponibles';
COMMENT ON TABLE ventas IS 'Registro de todas las ventas realizadas';
COMMENT ON TABLE clientes IS 'Información de clientes registrados';
COMMENT ON TABLE categorias IS 'Categorías de productos';

COMMENT ON COLUMN productos.precio IS 'Precio en pesos chilenos (CLP)';
COMMENT ON COLUMN ventas.total IS 'Total de la venta en pesos chilenos (CLP)';

-- ============================================================================
-- DATOS PARA PRÁCTICA DE PATHFINDING (basado en el proyecto Santiago)
-- ============================================================================

-- Tabla para almacenar nodos del grafo de Santiago
CREATE TABLE IF NOT EXISTS nodos_santiago (
    id BIGINT PRIMARY KEY,
    latitud DOUBLE PRECISION NOT NULL,
    longitud DOUBLE PRECISION NOT NULL,
    tipo VARCHAR(50) DEFAULT 'intersection',
    nombre VARCHAR(200),
    comuna VARCHAR(100)
);

-- Tabla para almacenar aristas (calles) del grafo
CREATE TABLE IF NOT EXISTS aristas_santiago (
    id SERIAL PRIMARY KEY,
    nodo_origen BIGINT REFERENCES nodos_santiago(id),
    nodo_destino BIGINT REFERENCES nodos_santiago(id),
    distancia_metros DOUBLE PRECISION,
    velocidad_maxima INTEGER DEFAULT 50,
    nombre_calle VARCHAR(200),
    tipo_via VARCHAR(50) DEFAULT 'street',
    tiempo_estimado DOUBLE PRECISION -- en minutos
);

-- Insertar algunos nodos de ejemplo (coordenadas reales de Santiago)
INSERT INTO nodos_santiago (id, latitud, longitud, nombre, comuna) VALUES
(1930783039, -33.42033, -70.60308, 'Campus San Joaquín UC', 'Macul'),
(253299978, -33.4569, -70.6483, 'Plaza de Armas', 'Santiago Centro'),
(500000001, -33.4372, -70.6506, 'Plaza Baquedano', 'Providencia'),
(500000002, -33.4203, -70.5403, 'Plaza Los Leones', 'Providencia'),
(500000003, -33.3750, -70.5689, 'Las Condes', 'Las Condes')
ON CONFLICT (id) DO NOTHING;

-- Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE '✅ Base de datos inicializada correctamente';
    RAISE NOTICE '📊 Tablas creadas: productos, ventas, clientes, categorias';
    RAISE NOTICE '🗺️  Tablas de pathfinding: nodos_santiago, aristas_santiago';
    RAISE NOTICE '👀 Vistas disponibles: vista_ventas_detalle, resumen_por_categoria, productos_top_ventas';
    RAISE NOTICE '🚀 ¡Listo para empezar a trabajar!';
END $$;