import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Fungsi async untuk mengambil data berita dari News API.
Future<List<Article>> fetchNews() async {
  // API key.
  const String apiKey = '3957b04e5e5d49cdaa7f38d36c0f79ea';
  const String url =
      'https://newsapi.org/v2/everything?domains=detik.com&sortBy=publishedAt&apiKey=$apiKey';

  // Kirim request GET dan tunggu responsenya.
  final response = await http.get(Uri.parse(url));

  // Jika request sukses (kode 200), parse JSON menjadi List<Article>.
  if (response.statusCode == 200) {
    Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    List articles = jsonResponse['articles'];
    return articles.map((json) => Article.fromJson(json)).toList();
  } else {
    // Jika gagal, lemparkan error untuk ditangani oleh FutureBuilder.
    throw Exception('Gagal memuat berita');
  }
}

// Class model atau 'cetakan' untuk data sebuah artikel.
class Article {
  final String author;
  final String title;
  final String description;
  final String? urlToImage; // Boleh null karena tidak semua berita punya gambar.
  final DateTime? publishedAt; // Boleh null.

  const Article({
    required this.author,
    required this.title,
    required this.description,
    this.urlToImage,
    this.publishedAt,
  });

  // Factory constructor untuk membuat objek Article dari data JSON (Map).
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      // Gunakan '??' untuk memberi nilai default jika data dari API null.
      author: json['author'] as String? ?? 'Tanpa Penulis',
      title: json['title'] as String? ?? 'Tanpa Judul',
      description: json['description'] as String? ?? 'Tanpa Deskripsi',
      urlToImage: json['urlToImage'] as String?,
      // Parse string tanggal menjadi objek DateTime, aman dari format error.
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String)
          : null,
    );
  }
}

// Fungsi utama untuk menjalankan aplikasi.
void main() => runApp(const MyApp());

// Widget utama aplikasi, menggunakan StatefulWidget karena datanya dinamis.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// State class, tempat menyimpan data dan logika UI.
class _MyAppState extends State<MyApp> {
  late Future<List<Article>> futureArticles;

  // Dipanggil sekali saat widget dibuat, cocok untuk memulai fetch data.
  @override
  void initState() {
    super.initState();
    futureArticles = fetchNews();
  }
  
  // Fungsi helper untuk mengubah DateTime menjadi format "x waktu yang lalu".
  String timeAgo(DateTime? date) {
    if (date == null) return 'Tanggal tidak ada';
    final Duration difference = DateTime.now().difference(date);
    if (difference.inDays > 30) return '${(difference.inDays / 30).floor()} bulan yang lalu';
    if (difference.inDays > 0) return '${difference.inDays} hari yang lalu';
    if (difference.inHours > 0) return '${difference.inHours} jam yang lalu';
    if (difference.inMinutes > 0) return '${difference.inMinutes} menit yang lalu';
    return 'Baru saja';
  }

  // Fungsi yang membangun (me-render) UI.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fetcherize App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Berita Terbaru')),
        body: Center(
          // FutureBuilder untuk membangun UI berdasarkan state dari sebuah Future.
          child: FutureBuilder<List<Article>>(
            future: futureArticles,
            builder: (context, snapshot) {
              // Jika Future masih loading, tampilkan spinner.
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // Jika Future selesai dengan error, tampilkan pesan error.
              if (snapshot.hasError) {
                return Center(child: Text('${snapshot.error}'));
              }
              // Jika Future selesai dengan data, tampilkan list berita.
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    Article article = snapshot.data![index];
                    final String timeAgoString = timeAgo(article.publishedAt);

                    // Tampilkan setiap artikel dalam sebuah Card.
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        // Susun konten secara vertikal (gambar, judul, info).
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tampilkan gambar jika URL-nya ada.
                            if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  article.urlToImage!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  // Tampilkan loading spinner saat gambar dimuat.
                                  loadingBuilder: (context, child, progress) => progress == null ? child : const Center(heightFactor: 5, child: CircularProgressIndicator()),
                                  // Tampilkan ikon jika gambar gagal dimuat.
                                  errorBuilder: (context, error, stack) => const SizedBox(height: 200, child: Icon(Icons.broken_image, size: 50)),
                                ),
                              ),
                            const SizedBox(height: 12.0),
                            Text(article.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
                            const SizedBox(height: 8.0),
                            // Info waktu dan penulis.
                            Row(children: [
                              const Icon(Icons.access_time, size: 14.0, color: Colors.black54),
                              const SizedBox(width: 4.0),
                              Text(timeAgoString, style: const TextStyle(color: Colors.black54)),
                            ]),
                            const SizedBox(height: 4.0),
                            Row(children: [
                              const Icon(Icons.person, size: 14.0, color: Colors.black54),
                              const SizedBox(width: 4.0),
                              Expanded(child: Text(article.author, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54), overflow: TextOverflow.ellipsis)),
                            ]),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              // Fallback jika tidak ada kondisi yang terpenuhi (seharusnya tidak terjadi).
              return const Center(child: Text('Tidak ada berita'));
            },
          ),
        ),
      ),
    );
  }
}