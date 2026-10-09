import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
if str(ROOT_DIR) not in sys.path:
    sys.path.append(str(ROOT_DIR))

from PySide6.QtCore import QObject, Slot, Signal, Property, QThread
from database.readers.supabase_reader import SupabaseReader
from database.repositories.crypto_repository import CryptoRepository
from workers.ohlc_worker import OhlcWorker
from workers.pipeline_worker import PipelineWorker

class CryptoBridge(QObject):
    
    dataUpdated = Signal()
    statusChanged = Signal(str)
    ohlcDataReady = Signal(list)
    ohlcError = Signal(str)
    
    def __init__(self):
        super().__init__()
        self.reader = SupabaseReader()
        self.repo = CryptoRepository(self.reader)
        self._status = "Listo"
        
        self._ohlc_thread = None
        self._ohlc_worker = None
    
        self._pipeline_thread = None
        self._pipeline_worker = None   
    
    @Property(str, notify=statusChanged)
    def status(self):
        return self._status
    
    @Slot(result=list)
    def get_latest_prices(self):
        return self.repo.get_lastest_quotes()
    
    @Slot()
    def refresh_pipeline(self):
        if self._pipeline_thread and self._pipeline_thread.isRunning():
            return
        
        self._status = "Synchronizing..."
        self.statusChanged.emit(self._status)

        self._pipeline_thread = QThread()
        self._pipeline_worker = PipelineWorker()
        self._pipeline_worker.moveToThread(self._pipeline_thread)

        self._pipeline_thread.started.connect(self._pipeline_worker.run)
        
        self._pipeline_worker.finished.connect(self._on_pipeline_success)
        self._pipeline_worker.error.connect(self._on_pipeline_error)

        self._pipeline_worker.finished.connect(self._pipeline_thread.quit)
        self._pipeline_worker.error.connect(lambda _: self._pipeline_thread.quit())
        
        self._pipeline_thread.finished.connect(self._pipeline_worker.deleteLater)
        self._pipeline_thread.finished.connect(self._pipeline_thread.deleteLater)
        
        def cleanup():
            self._pipeline_thread = None
            self._pipeline_worker = None
        
        self._pipeline_thread.finished.connect(cleanup)
        
        self._pipeline_thread.start()
        
    def _on_pipeline_success(self):
        self._status = "Listo"
        self.statusChanged.emit(self._status)
        self.dataUpdated.emit()
        
    def _on_pipeline_error(self, error_msg):
        self._status = f"Error: {error_msg}"
        self.statusChanged.emit(self._status)
    
    @Slot(str, int)
    def load_ohlc_async(self, symbol: str, days: int = 365):
        if self._ohlc_thread and self._ohlc_thread.isRunning():
            return
        
        self._status = f"Loading {symbol}..."
        self.statusChanged.emit(self._status)

        self._ohlc_thread = QThread()
        self._ohlc_worker = OhlcWorker(symbol, days)
        self._ohlc_worker.moveToThread(self._ohlc_thread)
        
        self._ohlc_thread.started.connect(self._ohlc_worker.run)
        
        self._ohlc_worker.finished.connect(self._on_ohlc_success)
        self._ohlc_worker.error.connect(self._on_ohlc_error)
        
        self._ohlc_worker.finished.connect(self._ohlc_thread.quit)
        self._ohlc_worker.error.connect(lambda _: self._ohlc_thread.quit())
        
        self._ohlc_thread.finished.connect(self._ohlc_worker.deleteLater)
        self._ohlc_thread.finished.connect(self._ohlc_thread.deleteLater)

        def cleanup():
            self._ohlc_thread = None
            self._ohlc_worker = None
        
        self._ohlc_thread.finished.connect(cleanup)
        self._ohlc_thread.start()
        
    def _on_ohlc_success(self, ohlc_data):
        self._status = "Listo"
        self.statusChanged.emit(self._status)
        self.ohlcDataReady.emit(ohlc_data)
                
    def _on_ohlc_error(self, error_msg: str):
        self._status = f"Error OHLC: {error_msg}"
        self.statusChanged.emit(self._status)
        self.ohlcError.emit(error_msg)