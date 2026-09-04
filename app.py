import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent / "src"))

from PySide6.QtWidgets import QApplication
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtQml import QQmlApplicationEngine
from src.ui_bridge import CryptoBridge

def main():
    QQuickStyle.setStyle("Basic")
    
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()
    
    bridge = CryptoBridge()
    
    engine.rootContext().setContextProperty("cryptoBridge", bridge)
    
    qml_file = Path(__file__).resolve().parent / "qml" / "main.qml"
    engine.load(str(qml_file))
    
    if not engine.rootObjects():
        sys.exit(-1)
    
    sys.exit(app.exec())
    
if __name__ == "__main__":
    main()