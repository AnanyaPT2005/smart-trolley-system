from firebase_admin import firestore

db = firestore.client()

def register_user(name, email, password):
    users_ref = db.collection("users")

    # check if email exists
    existing = users_ref.where("email", "==", email).get()
    if existing:
        return {"error": "User already exists"}

    users_ref.add({
        "name": name,
        "email": email,
        "password": password,
        "active_session_id": ""
    })

    return {"msg": "User registered"}

def register_employee(name, email, password, employee_id):
    emp_ref = db.collection("employees")

    # check email
    existing_email = emp_ref.where("email", "==", email).get()
    if existing_email:
        return {"error": "Email already exists"}

    # check employee_id
    existing_id = emp_ref.where("employee_id", "==", employee_id).get()
    if existing_id:
        return {"error": "Employee ID exists"}

    emp_ref.add({
        "name": name,
        "email": email,
        "password": password,
        "employee_id": employee_id
    })

    return {"msg": "Employee registered"}