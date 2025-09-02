from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_jwt_extended import JWTManager, jwt_required, create_access_token, get_jwt_identity
from dotenv import load_dotenv
import os
from models import db, User, Account, Transaction
from decimal import Decimal
import random
import string

load_dotenv()

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL')
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)
jwt = JWTManager(app)
CORS(app)

def generate_account_number():
    return ''.join(random.choices(string.digits, k=10))

with app.app_context():
    db.create_all()

@app.route('/', methods=['GET'])
def home():
    return jsonify({
        "message": "Banking API is running",
        "endpoints": ["/api/register", "/api/login", "/api/accounts"]
    }), 200

# Authentication Routes
@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()
    
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'error': 'Email already exists'}), 400
    
    user = User(email=data['email'], full_name=data['full_name'])
    user.set_password(data['password'])
    
    db.session.add(user)
    db.session.commit()
    
    # Create default checking account
    account = Account(
        account_number=generate_account_number(),
        account_type='checking',
        user_id=user.id
    )
    db.session.add(account)
    db.session.commit()
    
    return jsonify({'message': 'User registered successfully'}), 201

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    user = User.query.filter_by(email=data['email']).first()
    
    if user and user.check_password(data['password']):
        access_token = create_access_token(identity=user.id)
        return jsonify({'access_token': access_token}), 200
    
    return jsonify({'error': 'Invalid credentials'}), 401

# Account Routes
@app.route('/api/accounts', methods=['GET'])
@jwt_required()
def get_accounts():
    user_id = get_jwt_identity()
    accounts = Account.query.filter_by(user_id=user_id).all()
    
    return jsonify([{
        'id': acc.id,
        'account_number': acc.account_number,
        'account_type': acc.account_type,
        'balance': float(acc.balance)
    } for acc in accounts]), 200

@app.route('/api/accounts/<int:account_id>/deposit', methods=['POST'])
@jwt_required()
def deposit(account_id):
    user_id = get_jwt_identity()
    data = request.get_json()
    amount = Decimal(str(data['amount']))
    
    if amount <= 0:
        return jsonify({'error': 'Amount must be positive'}), 400
    
    account = Account.query.filter_by(id=account_id, user_id=user_id).first()
    if not account:
        return jsonify({'error': 'Account not found'}), 404
    
    account.balance += amount
    
    transaction = Transaction(
        transaction_type='deposit',
        amount=amount,
        description=data.get('description', 'Deposit'),
        account_id=account_id
    )
    
    db.session.add(transaction)
    db.session.commit()
    
    return jsonify({'message': 'Deposit successful', 'new_balance': float(account.balance)}), 200

@app.route('/api/accounts/<int:account_id>/withdraw', methods=['POST'])
@jwt_required()
def withdraw(account_id):
    user_id = get_jwt_identity()
    data = request.get_json()
    amount = Decimal(str(data['amount']))
    
    if amount <= 0:
        return jsonify({'error': 'Amount must be positive'}), 400
    
    account = Account.query.filter_by(id=account_id, user_id=user_id).first()
    if not account:
        return jsonify({'error': 'Account not found'}), 404
    
    if account.balance < amount:
        return jsonify({'error': 'Insufficient funds'}), 400
    
    account.balance -= amount
    
    transaction = Transaction(
        transaction_type='withdrawal',
        amount=amount,
        description=data.get('description', 'Withdrawal'),
        account_id=account_id
    )
    
    db.session.add(transaction)
    db.session.commit()
    
    return jsonify({'message': 'Withdrawal successful', 'new_balance': float(account.balance)}), 200

@app.route('/api/accounts/<int:account_id>/transactions', methods=['GET'])
@jwt_required()
def get_transactions(account_id):
    user_id = get_jwt_identity()
    account = Account.query.filter_by(id=account_id, user_id=user_id).first()
    
    if not account:
        return jsonify({'error': 'Account not found'}), 404
    
    transactions = Transaction.query.filter_by(account_id=account_id).order_by(Transaction.created_at.desc()).all()
    
    return jsonify([{
        'id': t.id,
        'type': t.transaction_type,
        'amount': float(t.amount),
        'description': t.description,
        'date': t.created_at.isoformat()
    } for t in transactions]), 200

@app.route('/api/transfer', methods=['POST'])
@jwt_required()
def transfer():
    user_id = get_jwt_identity()
    data = request.get_json()
    amount = Decimal(str(data['amount']))
    from_account_id = data['from_account_id']
    to_account_number = data['to_account_number']
    
    if amount <= 0:
        return jsonify({'error': 'Amount must be positive'}), 400
    
    from_account = Account.query.filter_by(id=from_account_id, user_id=user_id).first()
    if not from_account:
        return jsonify({'error': 'Source account not found'}), 404
    
    to_account = Account.query.filter_by(account_number=to_account_number).first()
    if not to_account:
        return jsonify({'error': 'Destination account not found'}), 404
    
    if from_account.balance < amount:
        return jsonify({'error': 'Insufficient funds'}), 400
    
    # Process transfer
    from_account.balance -= amount
    to_account.balance += amount
    
    # Create transactions
    withdrawal = Transaction(
        transaction_type='transfer_out',
        amount=amount,
        description=f'Transfer to {to_account_number}',
        account_id=from_account_id
    )
    
    deposit = Transaction(
        transaction_type='transfer_in',
        amount=amount,
        description=f'Transfer from {from_account.account_number}',
        account_id=to_account.id
    )
    
    db.session.add(withdrawal)
    db.session.add(deposit)
    db.session.commit()
    
    return jsonify({'message': 'Transfer successful', 'new_balance': float(from_account.balance)}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)