# Banking App Backend

## Setup Instructions

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Run the application:
```bash
python app.py
```

## API Endpoints

### Authentication
- POST `/api/register` - Register new user
- POST `/api/login` - Login user

### Accounts
- GET `/api/accounts` - Get user accounts (requires auth)
- POST `/api/accounts/{id}/deposit` - Deposit money
- POST `/api/accounts/{id}/withdraw` - Withdraw money
- POST `/api/transfer` - Transfer money between accounts
- GET `/api/accounts/{id}/transactions` - Get transaction history

## Example Usage

### Register:
```json
POST /api/register
{
  "email": "user@example.com",
  "password": "password123",
  "full_name": "John Doe"
}
```

### Login:
```json
POST /api/login
{
  "email": "user@example.com",
  "password": "password123"
}
```

### Deposit:
```json
POST /api/accounts/1/deposit
Authorization: Bearer <token>
{
  "amount": 100.00,
  "description": "Initial deposit"
}
```

### Transfer:
```json
POST /api/transfer
Authorization: Bearer <token>
{
  "from_account_id": 1,
  "to_account_number": "1234567890",
  "amount": 50.00
}
```

## Docker Setup (Recommended)

1. Install Docker Desktop
2. Run the app:
```bash
docker-compose up --build
```
3. Access at: http://localhost:3000

## Manual Setup

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Install React dependencies:
```bash
npm install
```

3. Start Flask backend:
```bash
python app.py
```

4. Start React frontend (new terminal):
```bash
npm start
```