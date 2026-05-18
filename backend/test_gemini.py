from google import genai
import os
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")

print(f"API Key found: {bool(api_key)}")

if api_key:
    try:
        client = genai.Client(api_key=api_key)
        print("✅ Client created successfully!")
        
        # List available models
        print("\n📋 Available Models:")
        models = client.models.list()
        for model in models:
            print(f"  - {model.name}")
        
        # Try with a working model
        print("\n🧪 Testing with gemini-2.5-flash:")
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents="Say hello in one sentence"
        )
        
        print(f"✅ API Response: {response.text}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
else:
    print("❌ No API key found")