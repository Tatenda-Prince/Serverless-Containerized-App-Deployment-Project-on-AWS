# Container Testing Guide

## Individual Container Testing

### Backend Testing
1. **Build backend:**
   ```bash
   build-backend.bat
   ```

2. **Run backend:**
   ```bash
   run-backend.bat
   ```

3. **Test backend API:**
   - Open browser: `http://localhost:5000`
   - Should see: `{"message": "Welcome to the Notes API"}`

### Frontend Testing
1. **Build frontend:**
   ```bash
   build-frontend.bat
   ```

2. **Run frontend:**
   ```bash
   run-frontend.bat
   ```

3. **Test frontend:**
   - Open browser: `http://localhost:3000`
   - Should see banking app login page

## Manual Docker Commands

### Backend
```bash
# Build
docker build -f Dockerfile.backend -t banking-backend .

# Run
docker run -p 5000:5000 --name banking-backend-test banking-backend

# Test
curl http://localhost:5000
```

### Frontend
```bash
# Build
docker build -f Dockerfile.frontend -t banking-frontend .

# Run
docker run -p 3000:3000 --name banking-frontend-test banking-frontend

# Test
# Open http://localhost:3000 in browser
```

## Cleanup
```bash
cleanup.bat
```

## Troubleshooting
- If port already in use: Run `cleanup.bat` first
- If build fails: Check Dockerfile paths
- If container won't start: Check logs with `docker logs <container-name>`