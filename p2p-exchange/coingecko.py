import time
import logging
import requests

logger = logging.getLogger(__name__)

_cache = {}


def get_xmr_price(currency='usd', cache_ttl=300):
    cache_key = f'xmr_{currency}'
    now = time.time()
    if cache_key in _cache:
        cached_price, cached_time = _cache[cache_key]
        if now - cached_time < cache_ttl:
            return cached_price
    try:
        url = 'https://api.coingecko.com/api/v3/simple/price'
        params = {'ids': 'monero', 'vs_currencies': currency}
        resp = requests.get(url, params=params, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        price = data.get('monero', {}).get(currency, 0.0)
        if price:
            _cache[cache_key] = (price, now)
        return price
    except Exception as e:
        logger.error(f"CoinGecko API error: {e}")
        if cache_key in _cache:
            return _cache[cache_key][0]
        return 0.0


def get_xmr_prices(currencies=None, cache_ttl=300):
    if currencies is None:
        currencies = ['usd', 'eur', 'gbp', 'btc']
    result = {}
    for currency in currencies:
        result[currency] = get_xmr_price(currency, cache_ttl)
    return result
