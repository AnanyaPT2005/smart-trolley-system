# from flask import Flask, request, render_template, redirect
# import firebase_admin
# from firebase_admin import credentials, firestore

# app = Flask(__name__)

# # 🔥 Firebase init using serviceAccountKey.json
# if not firebase_admin._apps:
#     cred = credentials.Certificate("serviceAccountKey.json")
#     firebase_admin.initialize_app(cred)

# db = firestore.client()


# # 🔹 Increase quantity
# def increase_quantity(session_id, barcode):
#     item_ref = db.collection("cart_sessions") \
#                  .document(session_id) \
#                  .collection("items") \
#                  .document(barcode)

#     item_ref.update({
#         "quantity": firestore.Increment(1)
#     })


# # 🔹 Decrease quantity
# def decrease_quantity(session_id, barcode):
#     item_ref = db.collection("cart_sessions") \
#                  .document(session_id) \
#                  .collection("items") \
#                  .document(barcode)

#     doc = item_ref.get()

#     if doc.exists:
#         data = doc.to_dict()
#         qty = data.get("quantity", 1)

#         if qty <= 1:
#             item_ref.delete()  # remove item if qty becomes 0
#         else:
#             item_ref.update({
#                 "quantity": firestore.Increment(-1)
#             })


# # 🔹 Show cart (for a session)
# @app.route('/cart/<session_id>')
# def show_cart(session_id):
#     items_ref = db.collection("cart_sessions") \
#                   .document(session_id) \
#                   .collection("items") \
#                   .stream()

#     items = []

#     for doc in items_ref:
#         data = doc.to_dict()
#         items.append({
#             "id": doc.id,  # barcode
#             "name": data["name"],
#             "quantity": data["quantity"]
#         })

#     return render_template("cart.html", items=items, session_id=session_id)


# # 🔹 Handle + / - button
# @app.route('/update', methods=['POST'])
# def update_item():
#     barcode = request.form.get("barcode")
#     action = request.form.get("action")
#     session_id = request.form.get("session_id")  # important!

#     if action == "increase":
#         increase_quantity(session_id, barcode)
#     elif action == "decrease":
#         decrease_quantity(session_id, barcode)

#     return redirect(f"/cart/{session_id}")


# # 🔹 Run
# if __name__ == "__main__":
#     app.run(debug=True)

from firebase_admin import firestore

db = firestore.client()


def increase_quantity(session_id, barcode):
    item_ref = db.collection("cart_sessions") \
                 .document(session_id) \
                 .collection("items") \
                 .document(barcode)

    item_ref.update({
        "quantity": firestore.Increment(1)
    })


def decrease_quantity(session_id, barcode):
    item_ref = db.collection("cart_sessions") \
                 .document(session_id) \
                 .collection("items") \
                 .document(barcode)

    doc = item_ref.get()

    if doc.exists:
        data = doc.to_dict()
        qty = data.get("quantity", 1)

        if qty <= 1:
            item_ref.delete()
        else:
            item_ref.update({
                "quantity": firestore.Increment(-1)
            })