from sqlalchemy import inspect
from app.database import engine

inspector = inspect(engine)
tables = inspector.get_table_names()

print("\n" + "="*50)
print("✅ Tables created in PostgreSQL database:")
print("="*50)
for table in tables:
    print(f"\n📊 Table: {table}")
    columns = inspector.get_columns(table)
    print(f"   Columns ({len(columns)}):")
    for col in columns[:5]:  # Show first 5 columns
        print(f"   - {col['name']} ({col['type']})")
    if len(columns) > 5:
        print(f"   ... and {len(columns) - 5} more columns")
print("\n" + "="*50)