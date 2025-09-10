from prometheus_client import Counter, Histogram, Gauge, generate_latest
from functools import wraps
import time

# Banking-specific metrics
user_registrations = Counter('bank_user_registrations_total', 'Total user registrations')
user_logins = Counter('bank_user_logins_total', 'Total user logins')
transactions_total = Counter('bank_transactions_total', 'Total transactions', ['transaction_type'])
transaction_amount = Histogram('bank_transaction_amount', 'Transaction amounts', ['transaction_type'])
active_users = Gauge('bank_active_users', 'Currently active users')
api_requests = Counter('bank_api_requests_total', 'Total API requests', ['method', 'endpoint', 'status'])
api_duration = Histogram('bank_api_request_duration_seconds', 'API request duration', ['method', 'endpoint'])

def track_api_metrics(f):
    """Decorator to track API metrics"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        start_time = time.time()
        
        try:
            result = f(*args, **kwargs)
            status = '200'
            return result
        except Exception as e:
            status = '500'
            raise
        finally:
            duration = time.time() - start_time
            endpoint = f.__name__
            method = 'POST'  # Adjust based on your routes
            
            api_requests.labels(method=method, endpoint=endpoint, status=status).inc()
            api_duration.labels(method=method, endpoint=endpoint).observe(duration)
    
    return decorated_function

def get_metrics():
    """Return Prometheus metrics"""
    return generate_latest()