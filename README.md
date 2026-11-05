# duckdb-mssql-lambda-layer

AWS Lambda Layer (Python) containing only `duckdb` and the DuckDB community [`mssql`](https://duckdb.org/community_extensions/extensions/mssql) extension.

The extension talks to SQL Server over a native TDS implementation, so **no ODBC driver, unixODBC, or pyodbc is needed**.

## Build

```bash
docker buildx build --load --platform linux/amd64 \
  --build-arg PYTHON_VERSION=3.12 -t duckdb-mssql .
docker run --rm -v "$(pwd):/out" duckdb-mssql cp /layer.zip /out/duckdb-mssql-python-3.12-x86_64.zip
```

- `--platform linux/arm64` for arm64 layers.
- `PYTHON_VERSION`: 3.12 – 3.14 (Amazon Linux 2023 based runtimes; 3.11 is Amazon Linux 2 and unsupported by recent duckdb wheels).
- Optional `--build-arg DUCKDB_VERSION=1.4.4` to pin duckdb.

## Release

The GitHub Actions workflow builds all Python/architecture combinations and runs tests.

- Push a tag to build and publish a GitHub Release with all zips attached:

  ```bash
  git tag v1.0.0 && git push origin v1.0.0
  ```

- `workflow_dispatch` (manual run) builds and tests only; zips are kept as workflow artifacts. Run it from a tag ref in the Actions UI to also publish a release.

## Layer contents

```text
/opt/python/                 duckdb Python package
/opt/duckdb_extensions/      pre-installed mssql extension (offline)
```

## Usage

Lambda's filesystem is read-only except `/tmp`, so point DuckDB at the bundled extensions.

```python
import duckdb

con = duckdb.connect(config={
    "extension_directory": "/opt/duckdb_extensions",
    "home_directory": "/tmp",
    "autoinstall_known_extensions": False,
})
con.execute("LOAD mssql")
con.execute("""
    ATTACH 'Server=your-host,1433;Database=your-db;User Id=user;Password=pass;Encrypt=yes'
    AS ms (TYPE mssql)
""")
print(con.execute("SELECT * FROM ms.dbo.your_table LIMIT 5").fetchall())
```

The extension is built for a specific DuckDB version; rebuild the layer when upgrading duckdb.

## Security

Pin versions, review builds, publish into your own AWS account, and keep credentials in AWS Secrets Manager.

## License

Licensed under the [Apache License 2.0](LICENSE). The build definitions are adapted from [yshrhrd/pyodbc-mssql-lambda-layer-gconv-extra](https://github.com/yshrhrd/pyodbc-mssql-lambda-layer-gconv-extra), which is based on [davidcomerford/pyodbc-mssql-lambda-layer](https://github.com/davidcomerford/pyodbc-mssql-lambda-layer); see [NOTICE](NOTICE). The resulting layer bundles `duckdb` and the `mssql` extension, which are subject to their own licenses.
