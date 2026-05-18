from fastapi import FastAPI
import uvicorn

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello from Smart Assistant API!", "status": "running"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    print("🚀 Starting test server...")
    print("📍 Open browser: http://localhost:8000")
    print("📍 API docs: http://localhost:8000/docs")
    uvicorn.run(app, host="0.0.0.0", port=8000)