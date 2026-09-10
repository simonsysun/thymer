import Foundation
import CSQLite

struct DatabaseError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
final class Database {
    private var db: OpaquePointer?
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    init(url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard sqlite3_open(url.path, &db) == SQLITE_OK else { throw failure() }
        sqlite3_busy_timeout(db, 3000)
        try execute("PRAGMA journal_mode=WAL; PRAGMA synchronous=FULL; CREATE TABLE IF NOT EXISTS state (id INTEGER PRIMARY KEY CHECK(id=1), json TEXT NOT NULL); CREATE TABLE IF NOT EXISTS entries (id TEXT PRIMARY KEY, group_id TEXT NOT NULL, task TEXT NOT NULL, phase TEXT NOT NULL, start REAL NOT NULL, end REAL NOT NULL CHECK(end>=start)); CREATE INDEX IF NOT EXISTS entries_time ON entries(start,end); PRAGMA user_version=1;")
    }
    deinit { sqlite3_close(db) }
    private func failure() -> DatabaseError { DatabaseError(message: db.map { String(cString: sqlite3_errmsg($0)) } ?? "Unable to open database") }
    private func execute(_ sql: String) throws { guard sqlite3_exec(db,sql,nil,nil,nil) == SQLITE_OK else { throw failure() } }
    private func statement(_ sql: String) throws -> OpaquePointer {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db,sql,-1,&stmt,nil) == SQLITE_OK, let stmt else { throw failure() }
        return stmt
    }
    private func bind(_ value: String, at: Int32, to stmt: OpaquePointer) throws {
        guard let count = Int32(exactly:value.utf8.count) else { throw DatabaseError(message:"Text is too long to save") }
        guard sqlite3_bind_text(stmt,at,value,count,transient) == SQLITE_OK else { throw failure() }
    }
    private func string(_ stmt: OpaquePointer, at index: Int32) -> String {
        guard let bytes = sqlite3_column_text(stmt,index) else { return "" }
        return String(decoding:UnsafeBufferPointer(start:bytes,count:Int(sqlite3_column_bytes(stmt,index))),as:UTF8.self)
    }
    func load() throws -> TimerModel? {
        let stmt = try statement("SELECT json FROM state WHERE id=1"); defer { sqlite3_finalize(stmt) }
        let result = sqlite3_step(stmt)
        if result == SQLITE_DONE { return nil }
        guard result == SQLITE_ROW else { throw failure() }
        return try JSONDecoder().decode(TimerModel.self, from: Data(string(stmt,at:0).utf8))
    }
    // Commit the timer and its ledger together: no recorded second without matching state.
    func save(_ state: TimerModel, entries: [TimeEntry]) throws {
        let json = String(decoding:try JSONEncoder().encode(state),as:UTF8.self)
        try execute("BEGIN IMMEDIATE")
        do {
            for entry in entries {
                let stmt = try statement("INSERT INTO entries VALUES (?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET end=excluded.end")
                defer { sqlite3_finalize(stmt) }
                try bind(entry.id,at:1,to:stmt); try bind(entry.group,at:2,to:stmt); try bind(entry.task,at:3,to:stmt); try bind(entry.phase.rawValue,at:4,to:stmt)
                sqlite3_bind_double(stmt,5,entry.start.timeIntervalSince1970); sqlite3_bind_double(stmt,6,entry.end.timeIntervalSince1970)
                guard sqlite3_step(stmt) == SQLITE_DONE else { throw failure() }
            }
            let stmt = try statement("INSERT INTO state VALUES (1,?) ON CONFLICT(id) DO UPDATE SET json=excluded.json")
            defer { sqlite3_finalize(stmt) }; try bind(json,at:1,to:stmt)
            guard sqlite3_step(stmt) == SQLITE_DONE else { throw failure() }
            try execute("COMMIT")
        } catch { try? execute("ROLLBACK"); throw error }
    }
    func entries(from start: Date, to end: Date) throws -> [TimeEntry] {
        let stmt = try statement("SELECT id,group_id,task,phase,start,end FROM entries WHERE end>? AND start<? ORDER BY start")
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_double(stmt,1,start.timeIntervalSince1970); sqlite3_bind_double(stmt,2,end.timeIntervalSince1970)
        var rows: [TimeEntry] = []
        while true {
            let result = sqlite3_step(stmt)
            if result == SQLITE_DONE { return rows }
            guard result == SQLITE_ROW else { throw failure() }
            func string(_ index:Int32) -> String { self.string(stmt,at:index) }
            guard let phase = Phase(rawValue:string(3)) else { throw DatabaseError(message:"Unknown record phase") }
            rows.append(TimeEntry(id:string(0),group:string(1),task:string(2),phase:phase,start:max(start,Date(timeIntervalSince1970:sqlite3_column_double(stmt,4))),end:min(end,Date(timeIntervalSince1970:sqlite3_column_double(stmt,5)))))
        }
    }
}
