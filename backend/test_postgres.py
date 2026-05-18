import psycopg2

try:
    conn = psycopg2.connect(
        dbname="smart_assistant",
        user="assistant_user",
        password="H7UNF0QQW",
        host="localhost",
        port="5432"
    )
    print("✅ PostgreSQL connection successful!")
    conn.close()
except Exception as e:
    print(f"❌ PostgreSQL connection failed: {e}")