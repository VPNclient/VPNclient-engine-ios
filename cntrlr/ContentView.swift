import SwiftUI
import NetworkExtension

struct ContentView: View {
    @StateObject private var vpnManager = VPNManager()
    @State private var vpnStatus: NEVPNStatus = .invalid
    @State private var socks5Proxy: String = "176.226.244.28:1080" 
    @State private var tunAddr: String = "192.168.1.2"
    @State private var tunMask: String = "255.255.255.0"
    @State private var tunDns: String = "8.8.8.8"

    var body: some View {
        VStack(spacing: 20) {
            Text("VPN Status: \(vpnStatus.description)")
                .font(.headline)

            TextField("SOCKS5 Proxy (e.g., server:port)", text: $socks5Proxy)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("TUN Address (e.g., 192.168.1.2)", text: $tunAddr)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("TUN Mask (e.g., 255.255.255.0)", text: $tunMask)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("TUN DNS (e.g., 8.8.8.8)", text: $tunDns)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                vpnManager.setupVPNConfiguration(tunAddr: tunAddr, tunMask: tunMask, tunDns: tunDns, socks5Proxy: socks5Proxy) { error in
                    if let error = error {
                        print("Error setting up VPN: \(error)")
                    } else {
                        print("VPN configuration set up successfully")
                        vpnManager.startVPN { error in
                            if let error = error {
                                print("VPN start failed: \(error)")
                            } else {
                                print("VPN starting")
                            }
                        }
                    }
                }
            }) {
                Text(vpnStatus != .invalid ? "Start VPN" : "Add VPN profile")
                    .frame(width: 200, height: 50)
                    .background(vpnStatus == .connected || vpnStatus == .connecting || vpnStatus == .disconnecting ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(vpnStatus == .connected || vpnStatus == .connecting || vpnStatus == .disconnecting)

            Button(action: {
                vpnManager.stopVPN {
                    print("VPN stopping")
                }
            }) {
                Text("Stop VPN")
                    .frame(width: 200, height: 50)
                    .background(vpnStatus != .connected ? Color.gray : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(vpnStatus != .connected)
        }
        .padding()
        .onAppear {
            updateStatus()
            NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: nil, queue: .main) { _ in
                updateStatus()
            }
        }
    }

    private func updateStatus() {
        vpnStatus = vpnManager.vpnStatus
        print("\(vpnStatus.description)")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
