/// Kullanıcıların projesine import edeceği ana paket dosyası.
/// Bu dosya, paketin "public API"sini, yani dışarıya açtığı
/// tüm widget'ları ve class'ları tanımlar.
library;

// Oluşturduğumuz animasyonlu text widget'ını dışa aktar:
export 'src/animated_text_counter.dart';

// Birazdan oluşturacağımız flip counter widget'ını dışa aktar:
export 'src/flip_counter.dart';
