import Foundation
import CSQLite
@main struct Checks {
 static func main() throws {
  let dir = FileManager.default.temporaryDirectory.appendingPathComponent("thymer-db-check-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at:dir) }
  let url=dir.appendingPathComponent("records.sqlite"), db=try Database(url:url)
  var model=TimerModel()
  model.task="学习 '); DROP TABLE entries; -- 🫖"
  let start=Date(timeIntervalSince1970:1788990000)
  let row=TimeEntry(group:"test",task:model.task,phase:.work,start:start,end:start.addingTimeInterval(20))
  try db.save(model,entries:[row])
  let loaded=try db.load()!, rows=try db.entries(from:start,to:start.addingTimeInterval(60))
  precondition(loaded.task==model.task && rows.count==1 && rows[0].task==model.task)
  print("PASS: SQL syntax and Unicode in task names round-trip as literal data")
  model.work=99
  let invalid=TimeEntry(group:"test",task:"invalid",phase:.work,start:start,end:start.addingTimeInterval(-1))
  do {try db.save(model,entries:[invalid]);fatalError("Expected rejected transaction")} catch {}
  let rolledBack = try db.load()!;precondition(rolledBack.work==50)
  let kept=try db.entries(from:start,to:start.addingTimeInterval(60));precondition(kept.count==1 && kept[0].duration==20)
  print("PASS: invalid entry rolls back both state and ledger")
  var raw:OpaquePointer?;precondition(sqlite3_open(url.path,&raw)==SQLITE_OK);defer{sqlite3_close(raw)}
  var stmt:OpaquePointer?;precondition(sqlite3_prepare_v2(raw,"PRAGMA integrity_check",-1,&stmt,nil)==SQLITE_OK);defer{sqlite3_finalize(stmt)}
  precondition(sqlite3_step(stmt)==SQLITE_ROW && String(cString:sqlite3_column_text(stmt,0))=="ok")
  print("PASS: SQLite integrity_check")
  let nul=TimeEntry(group:"nul",task:"Before\u{0}After",phase:.work,start:start,end:start.addingTimeInterval(2))
  try db.save(model,entries:[nul])
  let nulRead=try db.entries(from:start,to:start.addingTimeInterval(60)).first{$0.id==nul.id}!
  precondition(nulRead.task == nul.task)
  print("PASS: embedded NUL task round-trip")
 }
}
