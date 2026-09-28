from PySide6.QtCore import QObject, Signal, Slot
from database.repositories.crypto_repository import CryptoRepository

class InitialQuotesWorker(QObject):
    finished = Signal(list)
    
    def __init__(self, repo: CryptoRepository):
        super().__init__()
        self._repo = repo
        
    @Slot()
    def run(self):
        data = self._repo.get_lastest_quotes()
        self.finished.emit(data)