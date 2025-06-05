//
//  ContentView.swift
//  ProjetoSO
//
//  Created by Eduarda Gislon on 05/06/25.
//

import SwiftUI

struct ContentView: View {
    @State private var memoryUsage = ""
    @State private var diskUsage = ""
    @State private var cpuCount = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("📊 Monitor de Sistema")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(spacing: 15) {
                    infoRow(icon: "memorychip", title: "Memória", value: memoryUsage)
                    infoRow(icon: "externaldrive", title: "Disco", value: diskUsage)
                    infoRow(icon: "cpu", title: "Núcleos CPU", value: cpuCount)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemGray6)))
                .shadow(radius: 4)
                
                Text(avaliarEstado(cpu: Double(cpuCount) ?? 0,
                                   memoria: Double(memoryUsage.components(separatedBy: " ").first ?? "") ?? 0,
                                   memoriaTotal: Double(getDiskUsage()) ?? 0))
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color(.systemGray5)))
                    .padding(.horizontal)


                NavigationLink(destination: DeviceInfoCPU()) {
                    Text("Mostrar informações do Dispositivo")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Button("Atualizar") {
                    updateStats()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .onAppear {
                updateStats()
            }
        }
    }

    func infoRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.headline)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.gray)
        }
    }

    func updateStats() {
        memoryUsage = String(format: "%.2f MB", getMemoryUsage())
        diskUsage = getDiskUsage()
        cpuCount = "\(ProcessInfo.processInfo.processorCount)"
    }

    func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info)) / 4

        let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            return Double(info.resident_size) / 1_048_576 // MB
        } else {
            return -1
        }
    }

    func getDiskUsage() -> String {
        let fileManager = FileManager.default
        if let attrs = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let total = attrs[.systemSize] as? NSNumber,
           let free = attrs[.systemFreeSize] as? NSNumber {
            let used = total.int64Value - free.int64Value
            let totalGB = Double(total.int64Value) / 1_000_000_000
            let usedGB = Double(used) / 1_000_000_000
            return String(format: "%.2f GB / %.2f GB", usedGB, totalGB)
        }
        return "N/A"
    }

    func avaliarEstado(cpu: Double, memoria: Double, memoriaTotal: Double) -> String {
        var status = "✅ Tudo OK"

        if cpu > 8 {
            status = "🔴 CPU em uso extremo!"
        } else if cpu > 4 {
            status = "⚠️ CPU em uso elevado"
        }

        let usoMemoria = (memoria / (memoriaTotal * 1000)) * 100 // ajustando para GB vs MB

        if usoMemoria > 90 {
            status += "\n🔴 Memória quase cheia!"
        } else if usoMemoria > 75 {
            status += "\n⚠️ Uso de memória alto"
        }

        return status
    }
}

