from slowapi import Limiter
from slowapi.util import get_remote_address

# Shared across main.py (registers it on the app) and every router that
# decorates an endpoint with it — a single module so both sides import the
# same instance instead of each building their own Limiter.
limiter = Limiter(key_func=get_remote_address)
