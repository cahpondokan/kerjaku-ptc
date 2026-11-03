"""Exercise the production v3 SQL using real SQLite without touching user data."""
import re
import sqlite3
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = (root / 'lib/core/database/app_database.dart').read_text(encoding='utf-8')
creates = re.findall(r"'''\s*(CREATE TABLE.*?)'''", source, re.S)
alter = re.search(r"'(ALTER TABLE overtime_entries ADD COLUMN [^']+)'", source)[1]
assert len(creates) == 4
old_overtime = creates[0].replace(',\n            monthly_wage_basis_cents INTEGER', '')
assert 'monthly_wage_basis_cents' not in old_overtime

scratch = (root / 'build').resolve()
assert scratch.is_relative_to(root.resolve())
scratch.mkdir(exist_ok=True)
for version in (1, 2):
    with tempfile.TemporaryDirectory(prefix='kerjaku-migration-', dir=scratch) as folder:
        path = Path(folder) / 'test.db'
        db = sqlite3.connect(path)
        db.execute(old_overtime)
        overtime = ('old', '2026-10-20', '16:00', '19:00', 3, 5.5, 'regular',
                    'Maintenance', 'Manager', 'Approver', '2026-10-20', '2026-10-20')
        db.execute('INSERT INTO overtime_entries VALUES (?,?,?,?,?,?,?,?,?,?,?,?)', overtime)
        if version == 2:
            for statement in creates[1:]:
                db.execute(statement)
            db.execute("INSERT INTO leave_year_balances VALUES (2026,3)")
            db.execute("INSERT INTO leave_defaults VALUES (1,'Family','Address','Approver','Manager')")
            db.execute("INSERT INTO leave_entries VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
                       ('leave', '2026-10-26', '2026-10-28', '2026-10-20', 'Family',
                        'Address', 'Worker', '123', 'Approver', 'Manager', 'PTC', 'Manager PTC'))
        before = {name: db.execute(f'SELECT * FROM {name}').fetchall()
                  for (name,) in db.execute("SELECT name FROM sqlite_master WHERE type='table'")}
        db.execute(f'PRAGMA user_version = {version}')
        db.commit()
        # Equivalent to the version-gated production onUpgrade callback.
        with db:
            if version < 2:
                for statement in creates[1:]:
                    db.execute(statement)
            db.execute(alter)
            db.execute('PRAGMA user_version = 3')
        assert db.execute('SELECT * FROM overtime_entries').fetchone() == overtime + (None,)
        for name, rows in before.items():
            if name != 'overtime_entries':
                assert db.execute(f'SELECT * FROM {name}').fetchall() == rows
        db.execute('UPDATE overtime_entries SET monthly_wage_basis_cents=519000000 WHERE id=?', ('old',))
        db.commit()
        db.close()
        db = sqlite3.connect(path)
        assert db.execute('PRAGMA user_version').fetchone()[0] == 3
        assert db.execute('SELECT monthly_wage_basis_cents FROM overtime_entries').fetchone()[0] == 519000000
        db.close()
        print(f'SQLite v{version} -> v3: existing records preserved, legacy basis NULL, new basis persists')

with sqlite3.connect(':memory:') as db:
    for statement in creates:
        db.execute(statement)
    assert any(row[1] == 'monthly_wage_basis_cents' for row in db.execute('PRAGMA table_info(overtime_entries)'))
print('Fresh v3 schema: all tables created successfully')
