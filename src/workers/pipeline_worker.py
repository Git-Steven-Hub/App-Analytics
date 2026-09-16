from PySide6.QtCore import QObject, Signal
import main as pipeline

class PipelineWorker(QObject):
    finished = Signal()
    error = Signal(str)
    
    def run(self):
        
        try:
            print("\n [WORKER THREAD] Iniciando pipeline asíncrono...")
            pipeline.run_pipeline()
            self.finished.emit()
        
        except Exception as e:
            print(f"[WORKER THREAD ERROR] {e}")
            self.error.emit(str(e))