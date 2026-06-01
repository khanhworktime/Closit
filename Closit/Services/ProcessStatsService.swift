import Foundation

struct ProcessStats {
    let cpu: Double
    let ram: Int64 // in KB
}

class ProcessStatsService {
    static let shared = ProcessStatsService()
    
    private init() {}
    
    func fetchStats() -> [Int32: ProcessStats] {
        let process = Process()
        process.launchPath = "/bin/ps"
        process.arguments = ["-ax", "-o", "pid,%cpu,rss"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [:] }
            
            var statsMap: [Int32: ProcessStats] = [:]
            
            let lines = output.components(separatedBy: .newlines)
            for line in lines {
                let parts = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                if parts.count >= 3,
                   let pid = Int32(parts[0]),
                   let cpu = Double(parts[1]),
                   let ram = Int64(parts[2]) {
                    statsMap[pid] = ProcessStats(cpu: cpu, ram: ram)
                }
            }
            return statsMap
        } catch {
            print("Failed to fetch process stats: \(error)")
            return [:]
        }
    }
}
