import sys
from pathlib import Path
from PySide6.QtWidgets import QApplication
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtQml import QQmlApplicationEngine

sys.path.append(str(Path(__file__).resolve().parent / "src"))

from ui.crypto_view_model import CryptoViewModel
from database.readers.supabase_reader import SupabaseReader
from database.repositories.crypto_repository import CryptoRepository

def main():
    QQuickStyle.setStyle("Basic")
    
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()
    
    reader = SupabaseReader()
    repo = CryptoRepository(reader)
    
    view_model = CryptoViewModel(repo)
    
    engine.rootContext().setContextProperty("cryptoBridge", view_model)
    
    qml_file = Path(__file__).resolve().parent / "qml" / "main.qml"
    engine.load(str(qml_file))
    
    if not engine.rootObjects():
        sys.exit(-1)
    
    sys.exit(app.exec())
    
if __name__ == "__main__":
    main()