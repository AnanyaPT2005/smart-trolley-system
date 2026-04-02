

from firebase_admin import firestore

def delete_cart_item(session_id, barcode):
    db = firestore.client()

    item_ref = db.collection("cart_sessions") \
                 .document(session_id) \
                 .collection("items") \
                 .document(barcode)

    doc = item_ref.get()

    if not doc.exists:
        raise Exception(f"Item with barcode {barcode} not found in cart")

    item_ref.delete()

    return {"message": "Item deleted", "barcode": barcode}