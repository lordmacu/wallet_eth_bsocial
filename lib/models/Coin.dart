class Coin{
  String _id;
  String _name;
  String _symbol;
  String _slug;
  String _num_market_pairs;
  String _date_added;
  String _max_supply;
  String _circulating_supply;
  String _total_supply;
  String _is_active;
  String _cmc_rank;
  String _is_fiat;
  String _price;

  String get id => _id;

  set id(String value) {
    _id = value;
  }

  String get name => _name;

  String get price => _price;

  Coin(
      this._id,
      this._name,
      this._symbol,
      this._slug,
      this._num_market_pairs,
      this._date_added,
      this._max_supply,
      this._circulating_supply,
      this._total_supply,
      this._is_active,
      this._cmc_rank,
      this._is_fiat,
      this._price);

  @override
  String toString() {
    return 'Coin{_id: $_id, _name: $_name, _symbol: $_symbol, _slug: $_slug, _num_market_pairs: $_num_market_pairs, _date_added: $_date_added, _max_supply: $_max_supply, _circulating_supply: $_circulating_supply, _total_supply: $_total_supply, _is_active: $_is_active, _cmc_rank: $_cmc_rank, _is_fiat: $_is_fiat, _price: $_price}';
  }

  set price(String value) {
    _price = value;
  }

  String get is_fiat => _is_fiat;

  set is_fiat(String value) {
    _is_fiat = value;
  }

  String get cmc_rank => _cmc_rank;

  set cmc_rank(String value) {
    _cmc_rank = value;
  }

  String get is_active => _is_active;

  set is_active(String value) {
    _is_active = value;
  }

  String get total_supply => _total_supply;

  set total_supply(String value) {
    _total_supply = value;
  }

  String get circulating_supply => _circulating_supply;

  set circulating_supply(String value) {
    _circulating_supply = value;
  }

  String get max_supply => _max_supply;

  set max_supply(String value) {
    _max_supply = value;
  }

  String get date_added => _date_added;

  set date_added(String value) {
    _date_added = value;
  }

  String get num_market_pairs => _num_market_pairs;

  set num_market_pairs(String value) {
    _num_market_pairs = value;
  }

  String get slug => _slug;

  set slug(String value) {
    _slug = value;
  }

  String get symbol => _symbol;

  set symbol(String value) {
    _symbol = value;
  }

  set name(String value) {
    _name = value;
  }
}