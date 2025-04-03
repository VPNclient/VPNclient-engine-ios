import NetworkExtension
import SwiftUI

class VPNManager: ObservableObject {
    private var vpnManager: NETunnelProviderManager?
    private let profileName = "Controller"
    private let initializationGroup = DispatchGroup()

    init() {
        print("VPNManager: Initializing...")
        initializationGroup.enter()
        loadVPNManager { [weak self] in
            self?.setupStatusObserver()
            self?.initializationGroup.leave()
        }
    }

    private func loadVPNManager(completion: @escaping () -> Void) {
        print("VPNManager: Loading VPN managers...")
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else {
                print("VPNManager: Self is nil, completing...")
                completion()
                return
            }
            if let error = error {
                print("VPNManager: Error loading VPN managers: \(error)")
                completion()
                return
            }

            if let existingManager = managers?.first(where: { $0.localizedDescription == self.profileName }) {
                self.vpnManager = existingManager
                print("VPNManager: Found existing VPN profile: \(self.profileName)")
            } else {
                self.vpnManager = NETunnelProviderManager()
                self.vpnManager?.localizedDescription = self.profileName
                print("VPNManager: Created new VPN profile: \(self.profileName)")
            }
            completion()
        }
    }

    private func setupStatusObserver() {
        print("VPNManager: Setting up status observer")
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: nil, queue: .main) { [weak self] _ in
            print("VPNManager: Status changed to: \(self?.vpnStatus.description ?? "unknown")")
            self?.objectWillChange.send()
        }
    }

    func waitForInitialization() {
        initializationGroup.wait()
    }

    func setupVPNConfiguration(tunAddr: String, tunMask: String, tunDns: String, socks5Proxy: String, completion: @escaping (Error?) -> Void) {
        print("VPNManager: Setting up VPN configuration with tunAddr=\(tunAddr), tunMask=\(tunMask), tunDns=\(tunDns), socks5Proxy=\(socks5Proxy)")
        waitForInitialization()
        guard let vpnManager = vpnManager else {
            print("VPNManager: VPN Manager not initialized")
            completion(NSError(domain: "VPNError", code: -1, userInfo: [NSLocalizedDescriptionKey: "VPN Manager not initialized"]))
            return
        }

        vpnManager.loadFromPreferences { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("VPNManager: Load preferences error: \(error)")
                completion(error)
                return
            }

            let tunnelProtocol = NETunnelProviderProtocol()
            tunnelProtocol.providerBundleIdentifier = "click.vpnclient.engine.PacketTunnelProvider"
            tunnelProtocol.serverAddress = socks5Proxy.components(separatedBy: ":").first ?? "127.0.0.1"
            tunnelProtocol.providerConfiguration = [
                "tunAddr": tunAddr,
                "tunMask": tunMask,
                "tunDns": tunDns,
                "socks5Proxy": socks5Proxy
            ]

            vpnManager.protocolConfiguration = tunnelProtocol
            vpnManager.isEnabled = true

            print("VPNManager: Saving VPN configuration...")
            vpnManager.saveToPreferences { error in
                if let error = error {
                    print("VPNManager: Save preferences error: \(error)")
                    completion(error)
                } else {
                    print("VPNManager: VPN configuration saved successfully")
                    completion(nil)
                }
            }
        }
    }

    func startVPN(completion: @escaping (Error?) -> Void) {
        print("VPNManager: Starting VPN...")
        waitForInitialization()
        guard let vpnManager = vpnManager else {
            print("VPNManager: VPN Manager not initialized")
            completion(NSError(domain: "VPNError", code: -1, userInfo: [NSLocalizedDescriptionKey: "VPN Manager not initialized"]))
            return
        }
        do {
            try vpnManager.connection.startVPNTunnel()
            print("VPNManager: VPN tunnel started successfully")
            completion(nil)
        } catch {
            print("VPNManager: Start VPN error: \(error)")
            completion(error)
        }
    }

    func stopVPN(completion: @escaping () -> Void) {
        print("VPNManager: Stopping VPN...")
        waitForInitialization()
        vpnManager?.connection.stopVPNTunnel()
        completion()
    }

    var vpnStatus: NEVPNStatus {
        let status = vpnManager?.connection.status ?? .invalid
        return status
    }
}

extension NEVPNStatus {
    var description: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .disconnecting: return "Disconnecting..."
        default: return "Not Added Profile"
        }
    }
}
