import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_service.dart';
import 'genre_songs_screen.dart';

class GenresScreen extends StatefulWidget {
  const GenresScreen({super.key});

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen> {
  late Future<void> _futureGenres;

  @override
  void initState() {
    super.initState();
    _futureGenres =
        Provider.of<LibraryService>(context, listen: false).fetchGenres();
  }

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Thể loại'),
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
            color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: FutureBuilder(
        future: _futureGenres,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (lib.genres.isEmpty) {
            return Center(
              child:
                  Text('Không có thể loại', style: TextStyle(color: textColor)),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2),
            itemCount: lib.genres.length,
            itemBuilder: (c, i) {
              final g = lib.genres[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        GenreSongsScreen(genreId: g.id, genreName: g.name),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      if (g.imageUrl != null && g.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            g.imageUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 48),
                          ),
                        )
                      else
                        const Icon(Icons.category, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          g.name,
                          style: TextStyle(
                              color: textColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
