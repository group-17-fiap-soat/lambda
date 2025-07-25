import json
import psycopg2
import jwt
import os
from datetime import datetime, timedelta

def lambda_handler(event, context):
    cpf = json.loads(event['body'])['cpf']


    conn = psycopg2.connect(
        host=os.environ['DB_HOST'],
        database=os.environ['DB_NAME'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD']
    )

    cur = conn.cursor()
    cur.execute("SELECT id, name, email, cpf FROM tb_customer WHERE cpf = %s", (cpf,))
    result = cur.fetchone()

    if not result:
        return {
            "statusCode": 401,
            "body": json.dumps({"message": "CPF não encontrado"})
        }

    payload = {
        "iss": "auth.lambda",
        "sub": str(result[0]),
        "name": result[1],
        "email": result[2],
        "cpf": result[3],
        "exp": datetime.utcnow() + timedelta(hours=1)
    }

    token = jwt.encode(payload, os.environ['JWT_SECRET'], algorithm="HS256")

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "id": result[0],
            "name": result[1],
            "email": result[2],
            "cpf": result[3],
            "token": token
        })
    }