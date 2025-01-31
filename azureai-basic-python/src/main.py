import uvicorn

if __name__ == "__main__":
    uvicorn.run("api.main:create_app", 
                factory=True,
                reload=True,
                host="127.0.0.1",
                log_level="debug",
                port=8003) 
