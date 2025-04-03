Pod::Spec.new do |s|
  s.name             = 'VPNclientTunnel'
  s.version          = '0.1.0'
  s.summary          = 'Packet Tunnel Network Extension for VPNclient'
  s.description      = 'Provides NEPacketTunnelProvider implementation.'
  s.homepage         = 'https://github.com/VPNclient/VPNclient-engine-ios'
  s.license          = { :type => 'Extended GPLv3', :file => 'LICENSE' }
  s.author           = { 'NativeMind' => 'info@nativemind.net' }
  s.source           = { :git => 'https://github.com/VPNclient/VPNclient-engine-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.source_files = 'VPNclientTunnel/**/*.{swift}'

  s.preserve_paths = 'VPNclientTunnel/*'
  s.frameworks = ['NetworkExtension']
  s.requires_arc = true

  s.platform     = :ios, '12.0'
end