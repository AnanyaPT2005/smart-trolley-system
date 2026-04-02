

#VERSION 2

from firebase_admin import firestore

db = firestore.client()


# -----------------------------
# 🔍 FETCH PRODUCT BY BARCODE
# -----------------------------
def get_product_by_barcode(barcode: str):
    doc_ref = db.collection("products").document(barcode)
    doc = doc_ref.get()

    if not doc.exists:
        print(f"❌ Product not found for barcode: {barcode}")
        return None

    data = doc.to_dict()

    name = data.get("name")
    price = data.get("price")

    print("\n✅ Product Found:")
    print(f"Name  : {name}")
    print(f"Price : Rs.{price}")

    return {
        "barcode": barcode,
        "name": name,
        "price": price
    }


# -----------------------------
# ➕ ADD ITEM TO CART
# -----------------------------
def add_item_to_cart(session_id: str, barcode: str):
    # 🔍 get product using existing function
    product = get_product_by_barcode(barcode)

    if not product:
        raise Exception("Product not found")

    item_ref = db.collection("cart_sessions") \
                 .document(session_id) \
                 .collection("items") \
                 .document(barcode)

    item_doc = item_ref.get()

    if item_doc.exists:
        print("Item already exists, not increasing quantity")
    else:
        item_ref.set({
            "name": product["name"],
            "price": product["price"],
            "quantity": 1
        })
        print(f"🆕 Added new item: {product['name']}")

    
        