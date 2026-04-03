import firebase_admin
from firebase_admin import credentials, initialize_app
from firebase_admin import firestore
from flask_cors import CORS


cred = credentials.Certificate("serviceAccountKey.json")
initialize_app(cred)

from flask import Flask, render_template, request, redirect, session
from flask import jsonify 
import os



# 🔹 your functions
from cart_sessions import create_cart_session, get_active_sessions
from product_quantity import increase_quantity, decrease_quantity
from add_item import get_product_by_barcode, add_item_to_cart
from delete_cart_item import delete_cart_item   # adjust file name if needed
from cart_sessions import mark_session_billing
from cart_sessions import get_billing_sessions
from billing_list import get_billing_for_sessions
from billing_list import get_total_amount
from register import register_user, register_employee
from flask import request, jsonify, session
from firebase_admin import firestore



app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})
print(app.url_map)

app.secret_key = "secret123"

# ---------------- LOGIN PAGE ----------------
@app.route("/")
def login():
    return render_template("login.html")

db = firestore.client()



@app.route("/login-user", methods=["POST"])
def login_user():
    data = request.json
    email = data.get("email")
    password = data.get("password")

    user = db.collection("users") \
             .where("email", "==", email) \
             .where("password", "==", password) \
             .get()

    if not user:
        return jsonify({"error": "Invalid credentials"}), 401

    user_doc = user[0]

    # store session
    session["user_id"] = user_doc.id
    session["role"] = "user"

    # ✅ DO NOT create cart here anymore
    # user must select trolley first

    return jsonify({"msg": "Login successful"})

@app.route("/register-user", methods=["POST"])
def register_user_route():
    data = request.json
    return register_user(data["name"], data["email"], data["password"])

@app.route("/login-employee", methods=["POST"])
def login_employee():
    data = request.json
    email = data.get("email")
    password = data.get("password")
    emp_id = data.get("employee_id")

    emp = db.collection("employees") \
            .where("email", "==", email) \
            .where("password", "==", password) \
            .where("employee_id", "==", emp_id) \
            .get()

    if not emp:
        return jsonify({"error": "Invalid credentials"}), 401

    emp_doc = emp[0]

    session["employee_id"] = emp_doc.id
    session["role"] = "employee"

    return jsonify({"msg": "Employee login successful"})

@app.route("/register-employee", methods=["POST"])
def register_employee_route():
    data = request.json
    return register_employee(
        data["name"],
        data["email"],
        data["password"],
        data["employee_id"]
    )


# ---------------- USER HOME (TROLLEY SELECT) ----------------
@app.route("/user")
def user_home():
    # 🔒 allow only users
    if session.get("role") != "user":
        return "Unauthorized", 403

    active_sessions = get_active_sessions()

    
    db = firestore.client()

    active_trolleys = []

    for session_id in active_sessions:
        doc = db.collection("cart_sessions").document(session_id).get()
        if doc.exists:
            data = doc.to_dict()
            active_trolleys.append(data.get("trolley_id"))

    return render_template("user.html", active_trolleys=active_trolleys)


@app.route("/employee")
def employee():
    # 🔒 allow only employees
    if session.get("role") != "employee":
        return "Unauthorized", 403

    return render_template("billing.html")



# @app.route("/create-session", methods=["POST"])
# def create_session():
#     if session.get("role") != "user":
#         return "Unauthorized", 403

#     trolley_id = request.form.get("trolley_id")
#     # user_id = session.get("user_id")
#     user_id = request.form.get("user_id") or session.get("user_id")

#     try:
#         session_id = create_cart_session(user_id, trolley_id)

#         # ✅ store in Flask session
#         session["cart_session_id"] = session_id
#         session["trolley_id"] = trolley_id

#         # ✅ ALSO store in Firestore (users collection)
#         db = firestore.client()
#         db.collection("users").document(user_id).update({
#             "active_session_id": session_id
#         })

#         return redirect("/cart")

    # except Exception as e:
    #     return f"Error: {str(e)}"

# @app.route("/create-session", methods=["POST"])
# def create_session():
#     from flask import request, jsonify
#     from firebase_admin import firestore

#     data = request.get_json()  # ✅ get JSON from Flutter

#     trolley_id = data.get("trolley_id")
#     user_id = data.get("user_id")

#     # ✅ basic validation
#     if not trolley_id or not user_id:
#         return jsonify({"error": "Missing data"}), 400

#     try:
#         session_id = create_cart_session(user_id, trolley_id)

#         # ✅ store in Firestore (users collection)
#         db = firestore.client()
#         db.collection("users").document(user_id).update({
#             "active_session_id": session_id
#         })

#         # ✅ return JSON (not redirect)
#         return jsonify({
#             "message": "Session created",
#             "session_id": session_id
#         }), 200

#     except Exception as e:
#         return jsonify({
#             "error": str(e)
#         }), 400

@app.route("/create-session", methods=["POST"])
def create_session():
    from flask import request, jsonify
    from firebase_admin import firestore

    data = request.get_json(silent=True) or request.form  # ✅ handles both

    trolley_id = data.get("trolley_id")
    user_id = data.get("user_id")

    if not trolley_id or not user_id:
        return jsonify({"error": "Missing data"}), 400

    try:
        session_id = create_cart_session(user_id, trolley_id)

        db = firestore.client()
        db.collection("users").document(user_id).update({
            "active_session_id": session_id
        })

        return jsonify({
            "message": "Session created",
            "session_id": session_id
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route("/cart")
def cart():
    # 🔒 role protection
    if session.get("role") != "user":
        return "Unauthorized", 403

    session_id = session.get("cart_session_id")

    # 🚨 no session → go back
    if not session_id:
        return redirect("/user")

    db = firestore.client()
    doc = db.collection("cart_sessions").document(session_id).get()

    # 🚨 session not in DB → invalid
    if not doc.exists:
        session.pop("cart_session_id", None)
        session.pop("trolley_id", None)
        return redirect("/user")

    data = doc.to_dict()
    trolley_id = data.get("trolley_id")

    return render_template("cart.html",
                           session_id=session_id,
                           trolley_id=trolley_id)

@app.route("/get-product/<barcode>")
def get_product(barcode):
    product = get_product_by_barcode(barcode)

    if not product:
        return {"error": "Not found"}, 404

    return product


# ---------------- DEBUG: VIEW ACTIVE SESSIONS ----------------
@app.route("/debug-sessions")
def debug_sessions():
    sessions = get_active_sessions()
    return {"active_sessions": sessions, "count": len(sessions)}

# @app.route("/add-item", methods=["POST"])
# def add_item():
#     data = request.get_json()
#     barcode = data.get("barcode")

#     session_id = session.get("cart_session_id")

#     if not session_id:
#         return jsonify({"error": "No active session"}), 400

#     try:
#         add_item_to_cart(session_id, barcode)
#         return jsonify({"msg": "Item added"}), 200
#     except Exception as e:
#         return jsonify({"error": str(e)}), 400
    
@app.route("/add-item", methods=["POST"])
def add_item():
    data = request.get_json()
    barcode = data.get("barcode")
    session_id = data.get("session_id")  # ✅ FIXED

    if not session_id:
        return jsonify({"error": "No session_id"}), 400

    try:
        add_item_to_cart(session_id, barcode)
        return jsonify({"msg": "Item added"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route("/get-items/<session_id>")
def get_items(session_id):
    
    db = firestore.client()

    items_ref = db.collection("cart_sessions") \
                  .document(session_id) \
                  .collection("items") \
                  .stream()

    items = []
    for doc in items_ref:
        data = doc.to_dict()
        items.append({
            "barcode": doc.id,
            "name": data.get("name"),
            "price": data.get("price"),
            "quantity": data.get("quantity")
        })

    return jsonify(items)

@app.route("/update-quantity", methods=["POST"])
def update_quantity():
    data = request.get_json()

    barcode = data.get("barcode")
    action = data.get("action")
    session_id = session.get("cart_session_id")

    if not session_id:
        return {"error": "No session"}, 400

    if action == "increase":
        increase_quantity(session_id, barcode)
    elif action == "decrease":
        decrease_quantity(session_id, barcode)

    return {"msg": "updated"}



@app.route("/delete-item", methods=["POST"])
def delete_item():
    data = request.get_json()
    barcode = data.get("barcode")

    session_id = session.get("cart_session_id")

    if not session_id:
        return {"error": "No active session"}, 400

    try:
        result = delete_cart_item(session_id, barcode)
        return result, 200
    except Exception as e:
        return {"error": str(e)}, 400
    


@app.route("/go-to-billing", methods=["POST"])
def go_to_billing():
    session_id = session.get("cart_session_id")

    if not session_id:
        return {"error": "No session"}, 400

    mark_session_billing(session_id)

    return {"msg": "Go to cashier counter"}

@app.route("/get-employee-data")
def get_employee_data():
    
   
    db = firestore.client()

    sessions_ref = db.collection("cart_sessions").stream()

    sessions = []

    for doc in sessions_ref:
        data = doc.to_dict()

        # ❌ skip completed
        if data.get("status") == "completed":
            continue

        sessions.append({
            "session_id": doc.id,
            "trolley_id": data.get("trolley_id"),
            "status": data.get("status")
        })

    # 🔥 get billing data separately
    billing_ids = [s["session_id"] for s in sessions if s["status"] == "billing"]
    billing_data = get_billing_for_sessions(billing_ids)

    return jsonify({
        "sessions": sessions,
        "billing_data": billing_data
    })

@app.route("/confirm-bill", methods=["POST"])
def confirm_bill():
    if session.get("role") != "employee":
        return "Unauthorized", 403
    data = request.get_json()
    session_id = data.get("session_id")

    
    db = firestore.client()

    db.collection("cart_sessions") \
      .document(session_id) \
      .update({"status": "completed"})

    return {"msg": "Payment confirmed"}

@app.route("/get-billing-data")
def get_billing_data():
    session_ids = get_billing_sessions()   # ✅ HERE

    data = get_billing_for_sessions(session_ids)

    return jsonify(data)

@app.route("/check-session-status")
def check_status():
   
    db = firestore.client()

    session_id = session.get("cart_session_id")

    if not session_id:
        return {"status": "none"}

    doc = db.collection("cart_sessions").document(session_id).get()

    if not doc.exists:
        return {"status": "none"}

    return {"status": doc.to_dict().get("status")}


@app.route("/payment-success", methods=["POST"])
def payment_success():
    data = request.json
    method = data.get("method")
    session_id = data.get("session_id")

  
    db = firestore.client()

    # 🔥 mark session completed
    db.collection("cart_sessions") \
      .document(session_id) \
      .update({"status": "completed"})

    return jsonify({
        "msg": f"Payment Successful using {method} ✅"
    })


#FLUTTER FUNCTIONS
@app.route("/api/active-trolleys")
def get_active_trolleys_api():
    db = firestore.client()

    sessions = db.collection("cart_sessions") \
                 .where("status", "==", "active") \
                 .stream()

    active_trolleys = []

    for doc in sessions:
        data = doc.to_dict()
        active_trolleys.append(data.get("trolley_id").lower())
        print(data)
    return jsonify(active_trolleys)

@app.route("/get-user-session/<user_id>", methods=["GET"])
def get_user_session(user_id):
    from firebase_admin import firestore
    db = firestore.client()

    user_doc = db.collection("users").document(user_id).get()

    if not user_doc.exists:
        return {"session_id": None}, 200

    data = user_doc.to_dict()
    session_id = data.get("active_session_id")

    # 🔥 FIX HERE
    if not session_id:
        return {"session_id": None}, 200

    return {"session_id": session_id}, 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)


