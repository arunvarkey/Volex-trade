import 'dart:io';
import 'package:volex_terminal/core/security/secure_logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VpnProxyDetection {
  // Known VPN/Proxy IP ranges (simplified)
  static final _knownVpnProviders = [
    'nordvpn.com',
    'expressvpn.com',
    'cyberghost',
    'protonvpn',
    'tunnelbear',
    'surfshark',
    'ipvanish',
    'privateinternetaccess',
  ];

  // Known proxy ports
  static final _commonProxyPorts = [
    3128,
    8080,
    8888,
    1080,
    3129,
    8081,
    9050,
    9051,
  ];

  /// Detect if user is using VPN or Proxy
  static Future<VpnProxyReport> detect() async {
    try {
      SecureLogger.info('Starting VPN/Proxy detection...');

      final checks = <String, bool>{};

      // 1. Check local network interfaces for VPN adapters
      final hasVpnInterface = await _checkVpnInterface();
      checks['vpn_interface'] = hasVpnInterface;

      // 2. Check for proxy settings
      final hasProxySettings = await _checkProxySettings();
      checks['proxy_settings'] = hasProxySettings;

      // 3. Check IP address reputation
      final suspiciousIp = await _checkIpReputation();
      checks['suspicious_ip'] = suspiciousIp;

      // 4. Check DNS leaks
      final dnsLeak = await _checkDnsLeak();
      checks['dns_leak'] = dnsLeak;

      // 5. Check WebRTC leak
      final webRtcLeak = await _checkWebRtcLeak();
      checks['webrtc_leak'] = webRtcLeak;

      final isVpnOrProxy =
          hasVpnInterface || hasProxySettings || suspiciousIp || dnsLeak;

      if (isVpnOrProxy) {
        SecureLogger.warning('VPN or Proxy detected', data: checks);
      } else {
        SecureLogger.info('No VPN/Proxy detected');
      }

      return VpnProxyReport(
        isVpnOrProxy: isVpnOrProxy,
        checks: checks,
        riskScore: _calculateRiskScore(checks),
      );
    } catch (e) {
      SecureLogger.error('VPN/Proxy detection failed', data: {
        'error': e.toString(),
      });

      return VpnProxyReport(
        isVpnOrProxy: false,
        checks: {},
        riskScore: 0,
      );
    }
  }

  /// Check for VPN network interfaces
  static Future<bool> _checkVpnInterface() async {
    try {
      final interfaces = await NetworkInterface.list();

      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();

        // Check for common VPN interface names
        if (name.contains('tun') ||
            name.contains('tap') ||
            name.contains('ppp') ||
            name.contains('vpn') ||
            name.contains('utun') ||
            name.contains('ipsec')) {
          SecureLogger.warning('VPN interface detected', data: {
            'interface': interface.name,
          });

          return true;
        }
      }

      return false;
    } catch (e) {
      SecureLogger.error('VPN interface check failed', data: {
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Check for proxy settings
  static Future<bool> _checkProxySettings() async {
    try {
      // Check environment variables
      final httpProxy = Platform.environment['HTTP_PROXY'] ??
          Platform.environment['http_proxy'];
      final httpsProxy = Platform.environment['HTTPS_PROXY'] ??
          Platform.environment['https_proxy'];

      if (httpProxy != null || httpsProxy != null) {
        SecureLogger.warning('Proxy environment variables detected', data: {
          'http_proxy': httpProxy != null,
          'https_proxy': httpsProxy != null,
        });
        return true;
      }

      // Check for common proxy ports listening
      for (final port in _commonProxyPorts) {
        try {
          final socket = await Socket.connect(
            'localhost',
            port,
            timeout: const Duration(milliseconds: 100),
          );
          socket.destroy();

          SecureLogger.warning('Proxy port detected', data: {'port': port});
          return true;
        } catch (e) {
          // Port not open, continue
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check IP address reputation
  static Future<bool> _checkIpReputation() async {
    try {
      // Get public IP
      final ip = await _getPublicIp();

      if (ip == null) {
        return false;
      }

      // Check against IP reputation services
      // Using ipinfo.io as example
      final response = await http
          .get(
            Uri.parse('https://ipinfo.io/$ip/json'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check org/isp field for VPN providers
        final org = (data['org'] as String?)?.toLowerCase() ?? '';

        for (final vpnProvider in _knownVpnProviders) {
          if (org.contains(vpnProvider)) {
            SecureLogger.warning('VPN provider detected in IP info', data: {
              'provider': vpnProvider,
              'org': org,
            });
            return true;
          }
        }

        // Check for hosting/datacenter IPs (common for VPNs)
        if (org.contains('hosting') ||
            org.contains('datacenter') ||
            org.contains('cloud')) {
          SecureLogger.warning('Datacenter IP detected', data: {
            'org': org,
          });
          return true;
        }
      }

      return false;
    } catch (e) {
      SecureLogger.error('IP reputation check failed', data: {
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Get public IP address
  static Future<String?> _getPublicIp() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://api.ipify.org?format=json'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ip'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check for DNS leaks (VPN DNS vs real DNS)
  static Future<bool> _checkDnsLeak() async {
    try {
      // This is a simplified check
      // In production, would compare DNS resolver IPs
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check for WebRTC leaks
  static Future<bool> _checkWebRtcLeak() async {
    try {
      // This would require WebRTC implementation
      // Placeholder for now
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Calculate risk score based on checks
  static int _calculateRiskScore(Map<String, bool> checks) {
    int score = 0;

    if (checks['vpn_interface'] == true) score += 40;
    if (checks['proxy_settings'] == true) score += 30;
    if (checks['suspicious_ip'] == true) score += 20;
    if (checks['dns_leak'] == true) score += 10;

    return score.clamp(0, 100);
  }
}

class VpnProxyReport {
  final bool isVpnOrProxy;
  final Map<String, bool> checks;
  final int riskScore;

  VpnProxyReport({
    required this.isVpnOrProxy,
    required this.checks,
    required this.riskScore,
  });

  Map<String, dynamic> toJson() => {
        'is_vpn_or_proxy': isVpnOrProxy,
        'checks': checks,
        'risk_score': riskScore,
      };
}
