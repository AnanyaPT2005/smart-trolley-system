# from firebase_admin import firestore

# def create_cart_session(user_id, trolley_id):
#     db = firestore.client()

#     # ✅ validate trolley
#     if trolley_id not in ["t1", "t2", "t3", "t4", "t5"]:
#         raise Exception("Invalid trolley ID")

#     # 🔍 check if trolley already active
#     existing = db.collection("cart_sessions") \
#         .where("trolley_id", "==", trolley_id) \
#         .where("status", "==", "active") \
#         .stream()

#     if any(existing):
#         raise Exception("Trolley occupied")

#     # ✅ create session
#     doc_ref = db.collection("cart_sessions").document()

#     doc_ref.set({
#         "user_id": user_id,  # ✅ NEW
#         "trolley_id": trolley_id,
#         "status": "active",
#         "created_at": firestore.SERVER_TIMESTAMP  # ✅ RESTORED
#     })

#     return doc_ref.id

# def get_active_sessions():
#     db = firestore.client()

#     sessions = db.collection("cart_sessions") \
#                  .where("status", "==", "active") \
#                  .stream()

#     session_ids = [doc.id for doc in sessions]

#     return session_ids

# def get_billing_sessions():
#     db = firestore.client()

#     sessions = db.collection("cart_sessions") \
#                  .where("status", "==", "billing") \
#                  .stream()

#     return [doc.id for doc in sessions]

# def mark_session_billing(session_id):
#     db = firestore.client()

#     db.collection("cart_sessions") \
#       .document(session_id) \
#       .update({
#           "status": "billing"
#       })

from firebase_admin import firestore

def create_cart_session(user_id, trolley_id):
    db = firestore.client()

    # ✅ validate trolley
    if trolley_id not in ["t1", "t2", "t3", "t4", "t5"]:
        raise Exception("Invalid trolley ID")

    # 🔥 NEW: check user already has active/billing session
    existing_user = db.collection("cart_sessions") \
        .where("user_id", "==", user_id) \
        .where("status", "in", ["active", "billing"]) \
        .stream()

    if any(existing_user):
        raise Exception("User already has an active session")

    # 🔍 check if trolley already active OR billing
    existing = db.collection("cart_sessions") \
        .where("trolley_id", "==", trolley_id) \
        .where("status", "in", ["active", "billing"]) \
        .stream()

    if any(existing):
        raise Exception("Trolley occupied")

    # ✅ create session
    doc_ref = db.collection("cart_sessions").document()

    doc_ref.set({
        "user_id": user_id,
        "trolley_id": trolley_id,
        "status": "active",
        "created_at": firestore.SERVER_TIMESTAMP
    })

    # 🔥 NEW: store active session in user doc
    db.collection("users").document(user_id).set({
        "active_session_id": doc_ref.id
    }, merge=True)

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