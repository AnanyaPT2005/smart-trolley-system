

from firebase_admin import firestore
from cart_sessions import get_billing_sessions

def get_billing_for_sessions(session_ids):
    db = firestore.client()

    all_sessions = []

    for session_id in session_ids:
        items_ref = db.collection("cart_sessions") \
                      .document(session_id) \
                      .collection("items") \
                      .stream()

        products = []
        subtotal = 0

        for doc in items_ref:
            data = doc.to_dict()

            total = data["price"] * data["quantity"]
            subtotal += total

            products.append({
                "barcode": doc.id,
                "name": data["name"],
                "price": data["price"],
                "qty": data["quantity"],
                "total": total
            })

        all_sessions.append({
            "session_id": session_id,
            "items": products,
            "subtotal": subtotal
        })

    return all_sessions

from firebase_admin import firestore

def get_total_amount(session_id):
    db = firestore.client()

    # 🔹 get session doc (for trolley_id)
    session_doc = db.collection("cart_sessions").document(session_id).get()

    if not session_doc.exists:
        return {"error": "Session not found"}

    trolley_id = session_doc.to_dict().get("trolley_id")

    # 🔹 get items subcollection
    items_ref = db.collection("cart_sessions") \
                  .document(session_id) \
                  .collection("items") \
                  .stream()

    items = []
    total = 0

    for doc in items_ref:
        data = doc.to_dict()

        item_total = data["price"] * data["quantity"]
        total += item_total

        items.append({
            "name": data["name"],
            "price": data["price"],
            "qty": data["quantity"]
        })

    return {
        "trolley_id": trolley_id,
        "items": items,
        "total": total
    }