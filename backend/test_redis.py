import redis

try:
    r = redis.Redis(host='localhost', port=6379, db=0, decode_responses=True)
    r.set('test', 'Hello Redis!')
    value = r.get('test')
    print(f"✅ Redis connection successful! Value: {value}")
    r.delete('test')
except Exception as e:
    print(f"❌ Redis connection failed: {e}")