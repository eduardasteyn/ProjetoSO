//
//  DeviceInfoCPU.swift
//  ProjetoSO
//
//  Created by Eduarda Gislon on 05/06/25.
//

import SwiftUI

struct DeviceInfoCPU: View {
    @Environment(\.dismiss) var dismiss
    @State private var cpuDetails = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("📱Informações da dispositivo")
                .font(.title2)
                .bold()
                .padding(.top)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(cpuDetails.components(separatedBy: "\n"), id: \.self) { line in
                    Text(line)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemGray6)))
            .shadow(radius: 3)
            .padding()

            Spacer()
        }
        .padding()
        .onAppear {
            cpuDetails = getCPUInfo()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Voltar")
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    func getCPUInfo() -> String {
        var output = ""

        if let modelCode = getSysctlString(for: "hw.machine") {
            let modelName = deviceName(from: modelCode)
            output += "Modelo: \(modelName) (\(modelCode))\n"
        }

        if let cputype = getSysctlInt(for: "hw.cputype") {
            let typeDesc = cpuTypeDescription(cputype)
            output += "Arquitetura: \(typeDesc)\n"
        }


        if let cpufreq = getSysctlInt(for: "hw.cpufrequency") {
            let ghz = Double(cpufreq) / 1_000_000_000
            output += String(format: "Frequência: %.2f GHz\n", ghz)
        }

        if let cpucount = getSysctlInt(for: "hw.ncpu") {
            output += "Núcleos: \(cpucount)"
        }

        return output
    }

    func getSysctlString(for name: String) -> String? {
        var size: size_t = 0
        sysctlbyname(name, nil, &size, nil, 0)
        var result = [CChar](repeating: 0, count: size)
        sysctlbyname(name, &result, &size, nil, 0)
        return String(cString: result)
    }

    func getSysctlInt(for name: String) -> Int? {
        var value: Int = 0
        var size = MemoryLayout<Int>.size
        let result = sysctlbyname(name, &value, &size, nil, 0)
        return result == 0 ? value : nil
    }
    
    func deviceName(from identifier: String) -> String {
        let map: [String: String] = [
            "iPhone14,5": "iPhone 13",
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone13,2": "iPhone 12",
            "iPhone15,2": "iPhone 14 Pro",
        ]
        return map[identifier] ?? identifier // Se não encontrado, mostra o código bruto
    }
    
    func cpuTypeDescription(_ value: Int) -> String {
        switch value {
        case 12: return "ARM"
        case 16777228: return "ARM64"
        case 7: return "x86"
        case 16777223: return "x86_64"
        default: return "Desconhecido (\(value))"
        }
    }
}
