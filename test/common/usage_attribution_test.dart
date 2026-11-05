import 'package:fl_clash/common/usage_attribution.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('usageAppOf', () {
    test('names the outermost app bundle', () {
      const metadata = Metadata(
        process: 'Google Chrome Helper',
        processPath:
            '/Applications/Google Chrome.app/Contents/Frameworks/'
            'Google Chrome Framework.framework/Versions/1/Helpers/'
            'Google Chrome Helper.app/Contents/MacOS/Google Chrome Helper',
      );

      expect(usageAppOf(metadata), 'Google Chrome');
    });

    test('names a bundle executable after its bundle', () {
      const metadata = Metadata(
        process: 'Slack',
        processPath: '/Applications/Slack.app/Contents/MacOS/Slack',
      );

      expect(usageAppOf(metadata), 'Slack');
    });

    test('reads a bundle from a Windows path too', () {
      const metadata = Metadata(
        process: 'tool',
        processPath: r'C:\Tools\Some.app\bin\tool',
      );

      expect(usageAppOf(metadata), 'Some');
    });

    test('falls back to the process without .exe', () {
      expect(
        usageAppOf(
          const Metadata(
            process: 'chrome.exe',
            processPath: r'C:\x\chrome.exe',
          ),
        ),
        'chrome',
      );
      expect(usageAppOf(const Metadata(process: 'CURL.EXE')), 'CURL');
      expect(
        usageAppOf(
          const Metadata(process: 'curl', processPath: '/usr/bin/curl'),
        ),
        'curl',
      );
    });

    test('is empty when the process is unknown', () {
      expect(usageAppOf(const Metadata()), '');
      expect(usageAppOf(const Metadata(processPath: '/usr/bin/')), '');
    });

    test('does not take a bare .app segment for a bundle', () {
      const metadata = Metadata(process: 'x', processPath: '/opt/.app/x');

      expect(usageAppOf(metadata), 'x');
    });
  });

  group('usageDomainOf', () {
    String domainOf(String host, {String ip = ''}) =>
        usageDomainOf(Metadata(host: host, destinationIP: ip));

    test('keeps the last two labels', () {
      expect(domainOf('rr3.googlevideo.com'), 'googlevideo.com');
      expect(domainOf('a.b.c.example.org'), 'example.org');
      expect(domainOf('example.com'), 'example.com');
      expect(domainOf('localhost'), 'localhost');
    });

    test('keeps three labels under a two letter code with a second level', () {
      expect(domainOf('a.b.co.uk'), 'b.co.uk');
      expect(domainOf('www.example.com.au'), 'example.com.au');
      expect(domainOf('mail.u-tokyo.ac.jp'), 'u-tokyo.ac.jp');
      expect(domainOf('co.uk'), 'co.uk');
    });

    test('keeps two labels when the top level is longer than two letters', () {
      expect(domainOf('a.b.co.info'), 'co.info');
      expect(domainOf('a.example.co.uk.net'), 'uk.net');
    });

    test('lowercases and drops the trailing dot', () {
      expect(domainOf('WWW.Example.COM.'), 'example.com');
    });

    test('uses the destination address without a host', () {
      expect(domainOf('', ip: '203.0.113.9'), '203.0.113.9');
      expect(domainOf('.', ip: '2001:db8::1'), '2001:db8::1');
      expect(domainOf(''), '');
    });

    test('never rolls up an address', () {
      expect(domainOf('203.0.113.9'), '203.0.113.9');
      expect(domainOf('2001:DB8::1'), '2001:db8::1');
      expect(domainOf('[2001:db8::1]'), '[2001:db8::1]');
    });
  });

  test('isInnerConnection matches the Core spelling of the type', () {
    expect(isInnerConnection(const Metadata(type: 'Inner')), isTrue);
    expect(isInnerConnection(const Metadata(type: 'INNER')), isTrue);
    expect(isInnerConnection(const Metadata(type: 'HTTPS')), isFalse);
    expect(isInnerConnection(const Metadata()), isFalse);
  });
}
