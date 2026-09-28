from PySide6.QtCore import QObject, Slot, Signal, Property, QThread
from database.repositories.crypto_repository import CryptoRepository
from workers.pipeline_worker import PipelineWorker
from workers.ohlc_worker import OhlcWorker
from workers.initial_quotes_worker import InitialQuotesWorker

class CryptoViewModel(QObject):
    dataUpdated = Signal()
    quotesReady = Signal(list)
    statusChanged = Signal(str)
    ohlcDataReady = Signal(list)
    errorMessage = Signal(str)
    successMessage = Signal(str)
    
    def __init__(self, repository: CryptoRepository):
        super().__init__()
        self._repo = repository
        self._status = "Ready"
        
        self._pipeline_thread = None
        self._pipeline_worker = None
        
        self._ohlc_thread = None
        self._ohlc_worker = None
        
        self._quotes_thread = None
        self._quotes_worker = None
        
    @Property(str, notify=statusChanged)
    def status(self):
        return self._status
    
    @Slot()
    def load_initial_quotes(self):
        if self._quotes_thread is not None:
            try:
                if self._quotes_thread.isRunning():
                    return
            
            except RuntimeError:
                self._quotes_thread = None
                self._quotes_worker = None
        
        self._quotes_thread = QThread()
        self._quotes_worker = InitialQuotesWorker(self._repo)
        self._quotes_worker.moveToThread(self._quotes_thread)

        self._quotes_thread.started.connect(self._quotes_worker.run)
        
        def on_data_fetched(data):
            self.quotesReady.emit(data)
        
        def cleanup():
            self._quotes_thread = None
            self._quotes_worker = None
        
        self._quotes_worker.finished.connect(on_data_fetched)
        self._quotes_worker.finished.connect(self._quotes_thread.quit)
        self._quotes_worker.finished.connect(self._quotes_worker.deleteLater)

        self._quotes_thread.finished.connect(self._quotes_thread.deleteLater)
        self._quotes_thread.finished.connect(cleanup)

        self._quotes_thread.start()

    @Slot(result=list)
    def get_latest_prices(self):
        return self._repo.get_lastest_quotes()
    
    @Slot(str, int)
    def load_ohlc_async(self, symbol: str, days: int = 365):
        if not symbol:
            return
        
        if self._ohlc_thread is not None and self._ohlc_thread.isRunning():
            return

        self._ohlc_thread = QThread()
        self._ohlc_worker = OhlcWorker(symbol, days)
        self._ohlc_worker.moveToThread(self._ohlc_thread)

        self._ohlc_thread.started.connect(self._ohlc_worker.run)

        def on_data_fetched(ohlc_data):
            self.ohlcDataReady.emit(ohlc_data)
        
        def cleanup_ohlc():
            self._ohlc_thread = None
            self._ohlc_worker = None

        self._ohlc_worker.finished.connect(on_data_fetched)
        self._ohlc_worker.finished.connect(self._ohlc_thread.quit)
        self._ohlc_worker.deleteLater()
        
        self._ohlc_thread.finished.connect(self._ohlc_thread.deleteLater)
        self._ohlc_thread.finished.connect(cleanup_ohlc)

        self._ohlc_thread.start()

    @Slot()
    def refresh_pipeline(self):
        if self._pipeline_thread is not None:
            try:
                if self._pipeline_thread.isRunning():
                    return

            except RuntimeError:
                self._pipeline_thread = None
                self._pipeline_worker = None
        
        self._status = "Synchronizing..."
        self.statusChanged.emit(self._status)
        
        self._pipeline_thread = QThread()
        self._pipeline_worker = PipelineWorker()
        self._pipeline_worker.moveToThread(self._pipeline_thread)

        self._pipeline_thread.started.connect(self._pipeline_worker.run)
        
        def cleanup_pipeline():
            self._pipeline_thread = None
            self._pipeline_worker = None

        self._pipeline_worker.finished.connect(self._on_pipeline_success)
        self._pipeline_worker.error.connect(self._on_pipeline_error)

        self._pipeline_worker.finished.connect(self._pipeline_thread.quit)
        self._pipeline_worker.error.connect(self._pipeline_thread.quit)
        
        self._pipeline_thread.finished.connect(self._pipeline_worker.deleteLater)
        self._pipeline_thread.finished.connect(self._pipeline_thread.deleteLater)
        self._pipeline_thread.finished.connect(cleanup_pipeline)

        self._pipeline_thread.start()
    
    def _on_pipeline_success(self):
        self._status = "Ready"
        self.statusChanged.emit(self._status)
        self.dataUpdated.emit()
        self.successMessage.emit("Data successfully updated")
    
    def _on_pipeline_error(self, error_msg: str):
        self._status = f"Error: {error_msg}"
        self.statusChanged.emit(self._status)
        self.errorMessage.emit(f"Error synchronizing data: {error_msg}")