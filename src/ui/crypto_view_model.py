from PySide6.QtCore import QObject, Slot, Signal, Property, QThread
from database.repositories.crypto_repository import CryptoRepository
from workers.pipeline_worker import PipelineWorker

class CryptoViewModel(QObject):
    dataUpdated = Signal()
    statusChanged = Signal(str)
    ohlcDataReady = Signal(list)
    
    def __init__(self, repository: CryptoRepository):
        super().__init__()
        self._repo = repository
        self._status = "Ready"
        self._thread = None
        self._worker = None
    
    @Property(str, notify=statusChanged)
    def status(self):
        return self._status

    @Slot(result=list)
    def get_latest_prices(self):
        return self._repo.get_lastest_quotes()
    
    @Slot(str)
    def load_ohlc_async(self, symbol: str):
        if not symbol:
            return
        
        ohlc_data = self._repo.get_ohlc_data(symbol)
        self.ohlcDataReady.emit(ohlc_data)

    @Slot()
    def refresh_pipeline(self):
        if self._thread and self._thread.isRunning():
            return
        
        self._status = "Synchronizing..."
        self.statusChanged.emit(self._status)
        
        self._thread = QThread()
        self._worker = PipelineWorker()
        self._worker.moveToThread(self._thread)

        self._thread.started.connect(self._worker.run)

        self._worker.finished.connect(self._on_pipeline_success)
        self._worker.error.connect(self._on_pipeline_error)

        self._worker.finished.connect(self._thread.quit)
        self._worker.error.connect(self._thread.quit)
        self._thread.finished.connect(self._worker.deleteLater)
        self._thread.finished.connect(self._thread.deleteLater)

        self._thread.start()
    
    def _on_pipeline_success(self):
        self._status = "Synchronizing successful"
        self.statusChanged.emit(self._status)
        self.dataUpdated.emit()
    
    def _on_pipeline_error(self, error_msg: str):
        self._status = f"Error: {error_msg}"
        self.statusChanged.emit(self._status)