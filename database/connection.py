import sqlite3
import threading
import logging
from pathlib import Path

class DatabaseManager:
    
    _instance = None
    _lock = threading.Lock()
    _local = threading.local()
    _initialized = False
    
    def __new__(cls):
        """
        Crea una instancia singleton de DatabaseManager.
        """
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
            
        return cls._instance
    
    def __init__(self):
        """
        Inicializa la base de datos y crea las tablas si no existen.
        """
        if DatabaseManager._initialized:
            return
        
        with DatabaseManager._lock:
            if DatabaseManager._initialized:
                return
        
            base_dir = Path(__file__).resolve().parent
            self.db_path = base_dir / "students.db"
            self.logger = logging.getLogger("DatabaseManager")
            
            temp_connection = sqlite3.connect(str(self.db_path))
            temp_connection.execute("PRAGMA journal_mode=WAL")
            temp_connection.close()

            self.tables_db()
            DatabaseManager._initialized = True

    def get_connection(self):
        """
        Retorna la conexión a la base de datos.
        """
        if not hasattr(DatabaseManager._local, "connection") or DatabaseManager._local.connection is None:
            connection = sqlite3.connect(str(self.db_path))
            
            connection.row_factory = sqlite3.Row
            connection.execute("PRAGMA foreign_keys=ON")
            connection.execute("PRAGMA busy_timeout=5000")
            
            DatabaseManager._local.connection = connection
        
        return DatabaseManager._local.connection

    @property
    def connection(self):
        return self.get_connection()

    def tables_db(self):
        with self.get_connection() as conn:
            try:
                cursor = conn.cursor()

                cursor.execute("""
                CREATE TABLE IF NOT EXISTS admin (
                    id TEXT PRIMARY KEY,
                    usuario TEXT NOT NULL,
                    contraseña TEXT NOT NULL
                    )
                """)

                cursor.execute("""
                CREATE TABLE IF NOT EXISTS alumnos (
                    id TEXT PRIMARY KEY,
                    dni TEXT UNIQUE NOT NULL,
                    nombre TEXT NOT NULL,
                    apellido TEXT NOT NULL,
                    telefono TEXT,
                    colegio TEXT,
                    año TEXT,
                    telefono_madre TEXT,
                    telefono_padre TEXT,
                    localidad TEXT,
                    calle TEXT,
                    numero TEXT,
                    manzana TEXT,
                    barrio TEXT,
                    piso TEXT,
                    departamento TEXT,
                    email TEXT,
                    ingresante TEXT NOT NULL,
                    recursante TEXT NOT NULL,
                    estado TEXT CHECK(estado IN ('ACTIVO', 'INACTIVO')) DEFAULT 'ACTIVO',
                    sincronizado INTEGER DEFAULT 0, --0: Pendiente, 1: Sincronizado con Supabase,
                    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)

                cursor.execute("""
                CREATE TABLE IF NOT EXISTS contratos (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    alumno_id TEXT NOT NULL,
                    universidad TEXT NOT NULL,
                    carrera TEXT NOT NULL,
                    total REAL NOT NULL,
                    cantidad_cuotas INTEGER NOT NULL,
                    fecha_inicio DATE NOT NULL,
                    estado TEXT CHECK(estado IN ('ACTIVO', 'CANCELADO', 'FINALIZADO')) DEFAULT 'ACTIVO',
                    sincronizado INTEGER DEFAULT 0,
                    FOREIGN KEY (alumno_id) REFERENCES alumnos (id) ON DELETE CASCADE
                    )
                """)

                cursor.execute("""
                CREATE TABLE IF NOT EXISTS cuotas (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    contrato_id INTEGER NOT NULL,
                    numero_cuota INTEGER NOT NULL,
                    monto REAL NOT NULL,
                    fecha_vencimiento DATE NOT NULL,
                    estado TEXT CHECK(estado IN ('PENDIENTE', 'PAGADO', 'VENCIDO')) DEFAULT 'PENDIENTE',
                    sincronizado INTEGER DEFAULT 0,
                    FOREIGN KEY (contrato_id) REFERENCES contratos (id) ON DELETE CASCADE
                    )
                """)
                
                cursor.execute("""
                CREATE TABLE IF NOT EXISTS pagos (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    cuota_id INTEGER NOT NULL,
                    fecha_pago TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    monto_pagado REAL NOT NULL,
                    medio_pago TEXT CHECK(medio_pago IN ('EFECTIVO', 'TRANSFERENCIA')) NOT NULL,
                    numero_boleta TEXT NOT NULL,
                    sincronizado INTEGER DEFAULT 0,
                    FOREIGN KEY (cuota_id) REFERENCES cuotas (id) ON DELETE CASCADE
                    )
                """)
                
                conn.commit()
                
            except Exception as e:
                conn.rollback()
                self.logger.error(f"Error al crear las tablas: {e}")