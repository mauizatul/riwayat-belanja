/// Menandakan kenaikan harga 1 barang tertentu, dibandingkan antara
/// pembelian terakhir dan pembelian sebelumnya, DI MERCHANT YANG SAMA
/// (supaya tidak salah kaprah membandingkan harga antar toko berbeda).
class PriceChange {
  final String itemName;
  final String merchantName;
  final double oldPrice;
  final double newPrice;
  final DateTime oldDate;
  final DateTime newDate;

  PriceChange({
    required this.itemName,
    required this.merchantName,
    required this.oldPrice,
    required this.newPrice,
    required this.oldDate,
    required this.newDate,
  });

  double get priceDiff => newPrice - oldPrice;

  double get percentChange => oldPrice == 0 ? 0 : (priceDiff / oldPrice) * 100;
}
