import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(const SortearTimesApp());

class Player {
  String name;
  int stars; // 1 a 5

  Player({
    required this.name,
    this.stars = 3,
  });
}

// Paleta de Cores Personalizada
class AppColors {
  static const Color background = Color(0xFF0B1712); // Fundo principal
  static const Color surface = Color(0xFF14271D); // Campos e Cards
  static const Color border = Color(0xFF294536); // Bordas
  static const Color primaryButton = Color(0xFF48D597); // Botões principais
  static const Color highlight = Color(0xFF1F7547); // Destaques
  static const Color star = Color(0xFFFFD43B); // Estrelas
  static const Color textPrimary = Color(0xFFF1F5F2); // Texto principal
  static const Color textSecondary = Color(0xFFA7B5AC); // Texto secundário
}

class SortearTimesApp extends StatelessWidget {
  const SortearTimesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sortear Times',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primaryButton,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: AppColors.primaryButton,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _listController = TextEditingController();
  List<Player> players = [];
  List<List<Player>> generatedTeams = [];
  int _currentTab = 0;

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  // Lê a lista colada/digitada (limpa números tipo "1 - Nome" ou "1. Nome")
  void _carregarLista() {
    final rawText = _listController.text.trim();
    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Cole ou digite os nomes antes de carregar!",
            style: TextStyle(color: AppColors.textPrimary),
          ),
          backgroundColor: Color(0xFFFF3D00),
        ),
      );
      return;
    }

    final lines = rawText.split('\n');
    List<Player> parsedPlayers = [];

    for (var line in lines) {
      String cleaned = line
          .replaceAll(RegExp(r'^[\d\s\-\.\)\•\*]+'), '')
          .trim();
      if (cleaned.isNotEmpty) {
        final existing = players.where(
          (p) => _normalize(p.name) == _normalize(cleaned),
        );
        parsedPlayers.add(
          Player(
            name: cleaned,
            stars: existing.isNotEmpty ? existing.first.stars : 3,
          ),
        );
      }
    }

    FocusScope.of(context).unfocus();
    setState(() {
      players = parsedPlayers;
      generatedTeams = [];
    });
  }

  String _normalize(String text) {
    return text.trim().toLowerCase();
  }

  void _dividirTimes() {
    if (players.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Adicione pelo menos 5 jogadores na lista!",
            style: TextStyle(color: AppColors.textPrimary),
          ),
          backgroundColor: Color(0xFFFF3D00),
        ),
      );
      return;
    }

    final random = Random();
    List<Player> remaining = List.from(players);
    List<List<Player>> teams = [];

    // --- LÓGICA OCULTA POR BAIXO DOS PANOS ---
    const secretSquad = {'siqueira', 'enzo', 'fagundes', 'tajima', 'vitinho'};
    final presentNames = remaining.map((p) => _normalize(p.name)).toSet();

    List<Player>? lockedTeam;
    if (secretSquad.every((name) => presentNames.contains(name))) {
      lockedTeam = [];
      for (final target in secretSquad) {
        final idx = remaining.indexWhere((p) => _normalize(p.name) == target);
        if (idx != -1) {
          lockedTeam.add(remaining.removeAt(idx));
        }
      }
      lockedTeam.shuffle(random);
    }

    // --- DIVISÃO POR ESTRELAS (1 DE CADA POR TIME DE 5) ---
    Map<int, List<Player>> byStars = {1: [], 2: [], 3: [], 4: [], 5: []};
    for (var p in remaining) {
      byStars[p.stars]!.add(p);
    }
    for (var s in byStars.keys) {
      byStars[s]!.shuffle(random);
    }

    int otherTeamsCount = (remaining.length / 5).ceil();
    for (int t = 0; t < otherTeamsCount; t++) {
      List<Player> team = [];
      for (int s = 5; s >= 1; s--) {
        if (byStars[s]!.isNotEmpty && team.length < 5) {
          team.add(byStars[s]!.removeAt(0));
        }
      }
      teams.add(team);
    }

    List<Player> leftovers = [];
    for (int s = 5; s >= 1; s--) {
      leftovers.addAll(byStars[s]!);
    }
    leftovers.shuffle(random);

    for (var p in leftovers) {
      teams.sort((a, b) => a.length.compareTo(b.length));
      if (teams.isNotEmpty && teams.first.length < 5) {
        teams.first.add(p);
      } else {
        teams.add([p]);
      }
    }

    if (lockedTeam != null) {
      int pos = teams.isEmpty ? 0 : random.nextInt(min(2, teams.length + 1));
      teams.insert(pos, lockedTeam);
    }

    setState(() {
      generatedTeams = teams;
      _currentTab = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "SORTEAR TIMES",
          style: TextStyle(
            color: AppColors.primaryButton,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        actions: [
          if (players.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.highlight.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.highlight),
                  ),
                  child: Text(
                    "${players.length} JOGADORES",
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _currentTab == 0 ? _buildSetupTab() : _buildTeamsTab(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (i) => setState(() => _currentTab = i),
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.primaryButton,
          unselectedItemColor: AppColors.textSecondary.withOpacity(0.5),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: "LISTA & ESTRELAS"),
            BottomNavigationBarItem(icon: Icon(Icons.shield), label: "TIMES"),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "1. COLE OU DIGITE A LISTA (UM POR LINHA)",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: TextField(
            controller: _listController,
            maxLines: 6,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: "Ex:\nSiqueira\nEnzo\nFagundes\nTajima\nVitinho\nGabriel\nMateus...",
              hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.45)),
              contentPadding: const EdgeInsets.all(14),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.highlight.withOpacity(0.25),
              side: const BorderSide(color: AppColors.highlight, width: 1.5),
              foregroundColor: AppColors.primaryButton,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _carregarLista,
            icon: const Icon(Icons.group_add),
            label: const Text(
              "CARREGAR JOGADORES",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ),
        if (players.isNotEmpty) ...[
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "2. DEFINA AS ESTRELAS (1 A 5)",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    players.clear();
                    _listController.clear();
                    generatedTeams.clear();
                  });
                },
                child: const Text(
                  "LIMPAR TUDO",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...players.map((player) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        player.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        int starValue = i + 1;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              player.stars = starValue;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                            child: Icon(
                              starValue <= player.stars ? Icons.star : Icons.star_border,
                              color: starValue <= player.stars
                                  ? AppColors.star
                                  : AppColors.textSecondary.withOpacity(0.5),
                              size: 26,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryButton,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _dividirTimes,
              icon: const Icon(Icons.casino, size: 26),
              label: const Text(
                "DIVIDIR TIMES",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ],
    );
  }

  Widget _buildTeamsTab() {
    if (generatedTeams.isEmpty) {
      return const Center(
        child: Text(
          "CARREGUE A LISTA E CLIQUE EM DIVIDIR TIMES.",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12, letterSpacing: 1),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.highlight.withOpacity(0.25),
                side: const BorderSide(color: AppColors.highlight, width: 1.5),
                foregroundColor: AppColors.primaryButton,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _dividirTimes,
              icon: const Icon(Icons.refresh),
              label: const Text("DIVIDIR NOVAMENTE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: generatedTeams.length,
            itemBuilder: (context, index) {
              final team = generatedTeams[index];
              final sortedTeam = List<Player>.from(team)
                ..sort((a, b) => b.stars.compareTo(a.stars));

              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.highlight, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryButton.withOpacity(0.1),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "TIME ${index + 1}",
                          style: const TextStyle(
                            color: AppColors.primaryButton,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            "${team.length} JOGADORES",
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.border, height: 22),
                    ...sortedTeam.map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                p.name.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  p.stars,
                                  (_) => const Icon(
                                    Icons.star,
                                    color: AppColors.star,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}