import 'strategy_metadata.dart';
import 'strategy_registry.dart';
import '../access_control_service.dart';

class StrategyPublishingException implements Exception {
  final String message;
  StrategyPublishingException(this.message);
  @override
  String toString() => "StrategyPublishingException: $message";
}

class StrategyPublisher {
  final StrategyRegistry _registry = StrategyRegistry();
  final AccessControlService _accessControl = AccessControlService();

  void validate(StrategyMetadata metadata) {
    if (metadata.id.isEmpty) {
      throw StrategyPublishingException("ID is required");
    }
    if (metadata.name.isEmpty) {
      throw StrategyPublishingException("Name is required");
    }
    if (metadata.author.isEmpty) {
      throw StrategyPublishingException("Author is required");
    }
    if (metadata.version.isEmpty) {
      throw StrategyPublishingException("Version is required");
    }

    // Basic SemVer check
    final versionRegex = RegExp(r'^\d+\.\d+\.\d+$');
    if (!versionRegex.hasMatch(metadata.version)) {
      throw StrategyPublishingException("Version must be SemVer (x.y.z)");
    }
  }

  void publish(StrategyMetadata metadata) {
    // 1. Check Permissions
    if (!_accessControl.canPublishStrategies) {
      throw StrategyPublishingException(
          "User does not have permission to publish strategies.");
    }

    // 2. Validate
    validate(metadata);

    // 3. Publish to Registry
    _registry.publish(metadata);
  }
}
