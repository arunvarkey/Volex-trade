enum DataSource { websocket, polling, unknown }

class DataStatus {
  final DataSource source;
  final Duration latency;
  final bool isStale;
  final DateTime lastUpdate;

  const DataStatus({
    required this.source,
    required this.latency,
    required this.isStale,
    required this.lastUpdate,
  });

  factory DataStatus.unknown() {
    return DataStatus(
      source: DataSource.unknown,
      latency: Duration.zero,
      isStale: true,
      lastUpdate: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
