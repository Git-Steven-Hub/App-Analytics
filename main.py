import sys
import qasync
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

def main():
    DatabaseManager()
    
    app = QGuiApplication(sys.argv)
    loop = qasync.QEventLoop(app)
    qasync.asyncio.set_event_loop(loop)

    engine = QQmlApplicationEngine()
    
    backend = StudentBackend()
    engine.rootContext().setContextProperty("backend", backend)
    
    base_dir = Path(__file__).resolve().parent
    qml_file = base_dir / "qml" / "main.qml"
    
    if not qml_file.exists():
        print(f"Error: No se encontró el archivo QML en {qml_file}")
        sys.exit(-1)
        
    engine.load(str(qml_file))
    
    if not engine.rootObjects():
        sys.exit(-1)
    
    with loop:
        loop.run_forever()

if __name__ == "__main__":
    main()