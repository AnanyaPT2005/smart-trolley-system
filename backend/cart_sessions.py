from firebase_admin import firestore

def create_cart_session(user_id, trolley_id):
    db = firestore.client()

    # ✅ validate trolley
    if trolley_id not in ["t1", "t2", "t3", "t4", "t5"]:
        raise Exception("Invalid trolley ID")

    # 🔍 check if trolley already active
    existing = db.collection("cart_sessions") \
        .where("trolley_id", "==", trolley_id) \
        .where("status", "==", "active") \
        .stream()

    if any(existing):
        raise Exception("Trolley occupied")

    # ✅ create session
    doc_ref = db.collection("cart_sessions").document()

    doc_ref.set({
        "user_id": user_id,  # ✅ NEW
        "trolley_id": trolley_id,
        "status": "active",
        "created_at": firestore.SERVER_TIMESTAMP  # ✅ RESTORED
    })

    return doc_ref.id

def get_active_sessions():
    db = firestore.client()

    sessions = db.collection("cart_sessions") \
                 .where("status", "==", "active") \
                 .stream()

    session_ids = [doc.id for doc in sessions]

    return session_ids

def get_billing_sessions():
    db = firestore.client()

    sessions = db.collection("cart_sessions") \
                 .where("status", "==", "billing") \
                 .stream()

    return [doc.id for doc in sessions]

def mark_session_billing(session_id):
    db = firestore.client()

    db.collection("cart_sessions") \
      .document(session_id) \
      .update({
          "status": "billing"
      })