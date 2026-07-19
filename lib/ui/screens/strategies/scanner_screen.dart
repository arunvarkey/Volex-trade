import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/engine/scanner/scanner_engine.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/engine/execution_manager.dart';

class MarketScannerScreen extends StatefulWidget {
  const MarketScannerScreen({super.key});

  @override
  State<MarketScannerScreen> createState() => _MarketScannerScreenState();
}

class _MarketScannerScreenState extends State<MarketScannerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _activeFilter = "all"; // all, gainers, losers, active

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isLive = context.read<ExecutionManager>().isLiveMode;
      context.read<ScannerEngine>().scanAll(useRealData: isLive);
      context.read<ScannerEngine>().startAutoScan(useRealData: isLive);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<ScannerEngine>();
    final isLive = context.read<ExecutionManager>().isLiveMode;

    // Apply Logic
    var results = scanner.results.values.toList();

    // Search Filter
    if (_searchQuery.isNotEmpty) {
      results = results
          .where((r) =>
              r.symbol.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Tab Filters
    if (_activeFilter == "gainers") {
      results = results.where((r) => r.trendStrength > 0).toList();
      results.sort((a, b) => b.trendStrength.compareTo(a.trendStrength));
    } else if (_activeFilter == "losers") {
      results = results.where((r) => r.trendStrength < 0).toList();
      results.sort((a, b) => a.trendStrength.compareTo(b.trendStrength));
    } else if (_activeFilter == "active") {
      results.sort(
          (a, b) => b.trendStrength.abs().compareTo(a.trendStrength.abs()));
    } else {
      // Default: sort by volume or just symbol
      results.sort((a, b) => a.symbol.compareTo(b.symbol));
    }

    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        title: Text("All Markets",
            style: GoogleFonts.spaceMono(
                fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(scanner.isScanning ? Icons.sync : Icons.refresh,
                color: VxColors.neonCyan, size: 20),
            onPressed: scanner.isScanning
                ? null
                : () => scanner.scanAll(useRealData: isLive),
          )
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: VxColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VxColors.border),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: "Search coins...",
                  hintStyle: TextStyle(
                      color: VxColors.textTertiary, fontSize: 14),
                  prefixIcon: Icon(Icons.search,
                      color: VxColors.textTertiary, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Filter Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterPill("all", "All"),
                  _buildFilterPill("gainers", "Gainers"),
                  _buildFilterPill("losers", "Losers"),
                  _buildFilterPill("active", "Most Active"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Column Headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text("COIN", style: _headerStyle),
                ),
                Expanded(
                  child: Center(child: Text("7D SPARK", style: _headerStyle)),
                ),
                Expanded(
                  child: Text("PRICE",
                      style: _headerStyle, textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
          const Divider(color: VxColors.border, height: 1),

          // Content
          Expanded(
            child: scanner.isScanning && results.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: VxColors.neonCyan))
                : results.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) =>
                            _buildMarketItem(results[index]),
                      ),
          ),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: VxColors.textTertiary,
        letterSpacing: 1.2,
      );

  Widget _buildFilterPill(String id, String label) {
    final isActive = _activeFilter == id;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive ? VxColors.neonCyan.withValues(alpha: 0.1) : VxColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isActive ? VxColors.neonCyan.withValues(alpha: 0.3) : VxColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? VxColors.neonCyan : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMarketItem(ScannerResult result) {
    final bool isUp = result.trendStrength >= 0;
    final color = isUp ? VxColors.success : VxColors.danger;
    final name = result.symbol.replaceAll("USDT", "");

    return InkWell(
      onTap: () => context.push('/chart?symbol=${result.symbol}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: VxColors.border.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            // Coin Info
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        name[0],
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text("Vol \$${_formatVolume(result.volume)}",
                          style: const TextStyle(
                              color: VxColors.textTertiary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            // Sparkline
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 60,
                  height: 28,
                  child: CustomPaint(
                    painter: _MiniSparklinePainter(
                      data: result.history.map((e) => e.close).toList(),
                      color: color,
                    ),
                  ),
                ),
              ),
            ),

            // Price & Change
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "\$${result.history.isNotEmpty ? result.history.last.close.toStringAsFixed(2) : "0.00"}",
                    style: GoogleFonts.spaceMono(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "${isUp ? '+' : ''}${result.trendStrength.toStringAsFixed(2)}%",
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: VxColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? "No coins found"
                : "No results for '$_searchQuery'",
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          if (_searchQuery.isNotEmpty)
            TextButton(
              onPressed: () => _searchController.clear(),
              child: const Text("Clear Search",
                  style: TextStyle(color: VxColors.neonCyan)),
            ),
        ],
      ),
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(2)}B';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(2)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(2)}K';
    }
    return volume.toStringAsFixed(0);
  }
}

class _MiniSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _MiniSparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final max = data.reduce((a, b) => a > b ? a : b);
    final min = data.reduce((a, b) => a < b ? a : b);
    final range = max - min;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height -
          ((data[i] - min) / (range == 0 ? 1 : range)) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
