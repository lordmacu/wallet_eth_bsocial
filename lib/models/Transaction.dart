class Transaction {
  String _blockNumber;
  String _timeStamp;
  String _hash;
  String _nonce;
  String _blockHash;
  String _from;
  String _contractAddress;
  String _to;
  String _price;
  String _tokenName;
  String _tokenSymbol;
  String _tokenDecimal;
  String _transactionIndex;
  String _gas;
  String _gasPrice;
  String _gasUsed;
  String _cumulativeGasUsed;
  String _input;

  Transaction(
      this._blockNumber,
      this._timeStamp,
      this._hash,
      this._nonce,
      this._blockHash,
      this._from,
      this._contractAddress,
      this._to,
      this._price,
      this._tokenName,
      this._tokenSymbol,
      this._tokenDecimal,
      this._transactionIndex,
      this._gas,
      this._gasPrice,
      this._gasUsed,
      this._cumulativeGasUsed,
      this._input,
      this._confirmations,
      this._type);

  String get type => _type;

  set type(String value) {
    _type = value;
  }

  @override
  String toString() {
    return 'Transaction{_blockNumber: $_blockNumber, _timeStamp: $_timeStamp, _hash: $_hash, _nonce: $_nonce, _blockHash: $_blockHash, _from: $_from, _contractAddress: $_contractAddress, _to: $_to, _price: $_price, _tokenName: $_tokenName, _tokenSymbol: $_tokenSymbol, _tokenDecimal: $_tokenDecimal, _transactionIndex: $_transactionIndex, _gas: $_gas, _gasPrice: $_gasPrice, _gasUsed: $_gasUsed, _cumulativeGasUsed: $_cumulativeGasUsed, _input: $_input, _confirmations: $_confirmations, _type: $_type}';
  }

  String _confirmations;
  String _type;

  String get blockNumber => _blockNumber;

  set blockNumber(String value) {
    _blockNumber = value;
  }

  String get timeStamp => _timeStamp;

  String get confirmations => _confirmations;

  set confirmations(String value) {
    _confirmations = value;
  }

  String get input => _input;

  set input(String value) {
    _input = value;
  }

  String get cumulativeGasUsed => _cumulativeGasUsed;

  set cumulativeGasUsed(String value) {
    _cumulativeGasUsed = value;
  }

  String get gasUsed => _gasUsed;

  set gasUsed(String value) {
    _gasUsed = value;
  }

  String get gasPrice => _gasPrice;

  set gasPrice(String value) {
    _gasPrice = value;
  }

  String get gas => _gas;

  set gas(String value) {
    _gas = value;
  }

  String get transactionIndex => _transactionIndex;

  set transactionIndex(String value) {
    _transactionIndex = value;
  }

  String get tokenDecimal => _tokenDecimal;

  set tokenDecimal(String value) {
    _tokenDecimal = value;
  }

  String get tokenSymbol => _tokenSymbol;

  set tokenSymbol(String value) {
    _tokenSymbol = value;
  }

  String get tokenName => _tokenName;

  set tokenName(String value) {
    _tokenName = value;
  }

  String get price => _price;

  set price(String value) {
    _price = value;
  }

  String get to => _to;

  set to(String value) {
    _to = value;
  }

  String get contractAddress => _contractAddress;

  set contractAddress(String value) {
    _contractAddress = value;
  }

  String get from => _from;

  set from(String value) {
    _from = value;
  }

  String get blockHash => _blockHash;

  set blockHash(String value) {
    _blockHash = value;
  }

  String get nonce => _nonce;

  set nonce(String value) {
    _nonce = value;
  }

  String get hash => _hash;

  set hash(String value) {
    _hash = value;
  }

  set timeStamp(String value) {
    _timeStamp = value;
  }
}
