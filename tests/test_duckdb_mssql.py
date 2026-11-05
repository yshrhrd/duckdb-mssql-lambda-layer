import sys

sys.path.append('/opt/python')

EXT_DIR = '/opt/duckdb_extensions'


def _connect():
    import duckdb
    return duckdb.connect(config={
        'extension_directory': EXT_DIR,
        'autoinstall_known_extensions': False,
        'autoload_known_extensions': False,
    })


def test_duckdb_import():
    import duckdb
    assert duckdb.__version__


def test_mssql_extension_loads_offline():
    con = _connect()
    con.execute('LOAD mssql')
    row = con.execute(
        "SELECT loaded FROM duckdb_extensions() WHERE extension_name = 'mssql'"
    ).fetchone()
    assert row == (True,)
