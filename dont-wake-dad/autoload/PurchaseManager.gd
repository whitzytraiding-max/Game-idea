extends Node

const PRODUCT_REMOVE_ADS := "com.whitzy.dontwakedad.removeads"

signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, error: String)
signal restore_completed

var _iap = null

func _ready() -> void:
	if Engine.has_singleton("InAppPurchases"):
		_iap = Engine.get_singleton("InAppPurchases")
		_iap.product_details_query_completed.connect(_on_product_details)
		_iap.purchases_updated.connect(_on_purchases_updated)
		_iap.purchase_error.connect(_on_purchase_error)
		_iap.request_product_info({"product_ids": [PRODUCT_REMOVE_ADS]})
	else:
		push_warning("InAppPurchases: plugin not present — IAP unavailable (dev mode)")

func buy_remove_ads() -> void:
	if SaveManager.ads_removed:
		purchase_completed.emit(PRODUCT_REMOVE_ADS)
		return
	if not _iap:
		# Dev fallback — grant directly so UI can be tested
		_grant_remove_ads()
		return
	_iap.purchase({"product_id": PRODUCT_REMOVE_ADS})

func restore_purchases() -> void:
	if not _iap:
		restore_completed.emit()
		return
	_iap.restore_purchases()

func _on_product_details(_result: Array) -> void:
	pass  # Could populate price display here in future

func _on_purchases_updated(transactions: Array) -> void:
	for tx in transactions:
		var pid: String = tx.get("product_id", "")
		var state: int  = tx.get("transaction_state", -1)
		# state 1 = purchased, 3 = restored
		if pid == PRODUCT_REMOVE_ADS and state in [1, 3]:
			_grant_remove_ads()
	restore_completed.emit()

func _on_purchase_error(error: Dictionary) -> void:
	var pid: String = error.get("product_id", "")
	var msg: String = error.get("error_message", "Unknown error")
	purchase_failed.emit(pid, msg)

func _grant_remove_ads() -> void:
	SaveManager.set_ads_removed()
	purchase_completed.emit(PRODUCT_REMOVE_ADS)
