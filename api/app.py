import os
import pickle
import pandas as pd
import numpy as np
from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
import logging
from datetime import datetime
import traceback

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Crear aplicación Flask
app = Flask(__name__)
CORS(app)  # Permitir CORS para desarrollo

# Configuración de base de datos
DB_CONFIG = {
    'host': os.getenv('POSTGRES_HOST', 'localhost'),
    'port': os.getenv('POSTGRES_PORT', '5432'),
    'database': os.getenv('POSTGRES_DB', 'datascience'),
    'user': os.getenv('POSTGRES_USER', 'postgres'),
    'password': os.getenv('POSTGRES_PASSWORD', 'postgres')
}

# ============================================================================
# UTILIDADES DE BASE DE DATOS
# ============================================================================

def get_db_connection():
    """Obtener conexión a PostgreSQL"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        logger.error(f"Error conectando a BD: {e}")
        return None

def execute_query(query, params=None, fetch=True):
    """Ejecutar query en PostgreSQL"""
    try:
        conn = get_db_connection()
        if not conn:
            return None
        
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute(query, params)
        
        if fetch:
            result = cursor.fetchall()
            conn.close()
            return [dict(row) for row in result]
        else:
            conn.commit()
            conn.close()
            return True
            
    except Exception as e:
        logger.error(f"Error ejecutando query: {e}")
        if conn:
            conn.close()
        return None

# ============================================================================
# MODELO DE ML (SIMULADO - AQUÍ IRÍA SU MODELO REAL)
# ============================================================================

class ModeloPrecios:
    """Modelo simulado para predecir precios"""
    
    def __init__(self):
        self.is_trained = False
        self.features = ['categoria_encoded', 'stock', 'temporada']
        
    def predict(self, data):
        """Predicción simulada"""
        # En producción, aquí cargarían su modelo real
        # model = pickle.load(open('modelo.pkl', 'rb'))
        
        categoria = data.get('categoria', 'Electrónicos')
        stock = data.get('stock', 10)
        
        # Simulación simple
        base_price = 100
        if categoria == 'Electrónicos':
            base_price = 200
        elif categoria == 'Gaming':
            base_price = 150
        elif categoria == 'Accesorios':
            base_price = 50
            
        # Factor de stock (menos stock = más caro)
        stock_factor = max(0.5, 1 - (stock / 100))
        
        predicted_price = base_price * (1 + stock_factor)
        confidence = 0.85  # Simulado
        
        return {
            'precio_predicho': round(predicted_price, 2),
            'confianza': confidence,
            'factores': {
                'categoria_base': base_price,
                'factor_stock': stock_factor
            }
        }

# Instanciar modelo
modelo = ModeloPrecios()

# ============================================================================
# RUTAS DE LA API
# ============================================================================

@app.route('/')
def home():
    """Página principal con documentación"""
    html = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Data Science API</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .endpoint { background: #f5f5f5; padding: 15px; margin: 10px 0; border-radius: 5px; }
            .method { color: #28a745; font-weight: bold; }
            code { background: #e9ecef; padding: 2px 5px; border-radius: 3px; }
        </style>
    </head>
    <body>
        <h1>🔬 Data Science API</h1>
        <p>API para análisis de datos y predicciones con ML</p>
        
        <h2>Endpoints Disponibles:</h2>
        
        <div class="endpoint">
            <h3><span class="method">GET</span> /health</h3>
            <p>Verificar estado de la API</p>
        </div>
        
        <div class="endpoint">
            <h3><span class="method">GET</span> /productos</h3>
            <p>Obtener lista de productos</p>
        </div>
        
        <div class="endpoint">
            <h3><span class="method">GET</span> /productos/stats</h3>
            <p>Estadísticas de productos</p>
        </div>
        
        <div class="endpoint">
            <h3><span class="method">POST</span> /predict/precio</h3>
            <p>Predecir precio de producto</p>
            <p><strong>Body:</strong> <code>{"categoria": "Electrónicos", "stock": 15}</code></p>
        </div>
        
        <div class="endpoint">
            <h3><span class="method">GET</span> /ventas/resumen</h3>
            <p>Resumen de ventas por categoría</p>
        </div>
        
        <h2>Ejemplos de uso:</h2>
        <pre>
# Verificar salud
curl http://localhost:8080/health

# Obtener productos
curl http://localhost:8080/productos

# Predecir precio
curl -X POST http://localhost:8080/predict/precio \\
  -H "Content-Type: application/json" \\
  -d '{"categoria": "Gaming", "stock": 5}'
        </pre>
        
        <p><em>Desarrollado para el curso de Data Science</em></p>
    </body>
    </html>
    """
    return html

@app.route('/health')
def health():
    """Endpoint de salud"""
    try:
        # Probar conexión a BD
        conn = get_db_connection()
        if conn:
            conn.close()
            db_status = "ok"
        else:
            db_status = "error"
            
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'database': db_status,
            'modelo': 'activo',
            'version': '1.0.0'
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'error': str(e)
        }), 500

@app.route('/productos')
def get_productos():
    """Obtener lista de productos"""
    try:
        query = """
        SELECT id, nombre, categoria, precio, stock, fecha_creacion
        FROM productos 
        ORDER BY fecha_creacion DESC
        """
        productos = execute_query(query)
        
        if productos is None:
            return jsonify({'error': 'Error conectando a base de datos'}), 500
            
        return jsonify({
            'productos': productos,
            'total': len(productos),
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error en /productos: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/productos/stats')
def get_productos_stats():
    """Estadísticas de productos"""
    try:
        query = """
        SELECT 
            categoria,
            COUNT(*) as total_productos,
            AVG(precio) as precio_promedio,
            MIN(precio) as precio_minimo,
            MAX(precio) as precio_maximo,
            SUM(stock) as stock_total
        FROM productos 
        GROUP BY categoria
        ORDER BY total_productos DESC
        """
        stats = execute_query(query)
        
        if stats is None:
            return jsonify({'error': 'Error conectando a base de datos'}), 500
            
        return jsonify({
            'estadisticas': stats,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error en /productos/stats: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/predict/precio', methods=['POST'])
def predict_precio():
    """Predecir precio usando modelo de ML"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No se enviaron datos'}), 400
            
        # Validar datos requeridos
        if 'categoria' not in data:
            return jsonify({'error': 'Categoría es requerida'}), 400
            
        # Hacer predicción
        prediction = modelo.predict(data)
        
        return jsonify({
            'prediccion': prediction,
            'input_data': data,
            'timestamp': datetime.now().isoformat(),
            'modelo_version': '1.0.0'
        })
        
    except Exception as e:
        logger.error(f"Error en predicción: {e}")
        return jsonify({
            'error': str(e),
            'traceback': traceback.format_exc()
        }), 500

@app.route('/ventas/resumen')
def get_ventas_resumen():
    """Resumen de ventas por categoría"""
    try:
        query = """
        SELECT * FROM resumen_por_categoria
        """
        resumen = execute_query(query)
        
        if resumen is None:
            return jsonify({'error': 'Error conectando a base de datos'}), 500
            
        return jsonify({
            'resumen_ventas': resumen,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error en /ventas/resumen: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/productos/top')
def get_productos_top():
    """Productos más vendidos"""
    try:
        query = """
        SELECT * FROM productos_top_ventas
        LIMIT 10
        """
        top_productos = execute_query(query)
        
        if top_productos is None:
            return jsonify({'error': 'Error conectando a base de datos'}), 500
            
        return jsonify({
            'top_productos': top_productos,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error en /productos/top: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/analytics/dashboard')
def analytics_dashboard():
    """Datos para dashboard de analytics"""
    try:
        # Ventas por mes
        query_ventas_mes = """
        SELECT 
            DATE_TRUNC('month', fecha_venta) as mes,
            COUNT(*) as total_ventas,
            SUM(total) as ingresos
        FROM ventas 
        WHERE fecha_venta >= CURRENT_DATE - INTERVAL '12 months'
        GROUP BY DATE_TRUNC('month', fecha_venta)
        ORDER BY mes
        """
        
        # Top productos
        query_top_productos = """
        SELECT nombre, total_vendido, ingresos_generados
        FROM productos_top_ventas
        LIMIT 5
        """
        
        ventas_mes = execute_query(query_ventas_mes)
        top_productos = execute_query(query_top_productos)
        
        return jsonify({
            'ventas_por_mes': ventas_mes,
            'top_productos': top_productos,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error en dashboard: {e}")
        return jsonify({'error': str(e)}), 500

# ============================================================================
# MANEJO DE ERRORES
# ============================================================================

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'error': 'Endpoint no encontrado',
        'available_endpoints': [
            '/health',
            '/productos',
            '/productos/stats',
            '/predict/precio',
            '/ventas/resumen'
        ]
    }), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        'error': 'Error interno del servidor',
        'timestamp': datetime.now().isoformat()
    }), 500

# ============================================================================
# CONFIGURACIÓN Y STARTUP
# ============================================================================

if __name__ == '__main__':
    # Configuración
    port = int(os.getenv('PORT', 8080))
    host = os.getenv('HOST', '0.0.0.0')
    debug = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    
    logger.info(f"🚀 Iniciando API en {host}:{port}")
    logger.info(f"🐘 PostgreSQL: {DB_CONFIG['host']}:{DB_CONFIG['port']}")
    
    # Verificar conexión inicial
    conn = get_db_connection()
    if conn:
        logger.info("✅ Conexión a PostgreSQL exitosa")
        conn.close()
    else:
        logger.warning("⚠️  No se pudo conectar a PostgreSQL")
    
    # Iniciar servidor
    app.run(
        host=host,
        port=port,
        debug=debug
    )