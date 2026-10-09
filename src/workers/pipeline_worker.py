from PySide6.QtCore import QObject, Signal
import main as pipeline

class PipelineWorker(QObject):
    finished = Signal()
    error = Signal(str)
    warning = Signal(str)
    
    def run(self):
        
        try:
            pipeline.run_pipeline(progress_callback=self.warning.emit)
            self.finished.emit()
        
        except Exception as e:
            print(f"{e}")
            self.error.emit("Error al guardar datos en el servidor.")