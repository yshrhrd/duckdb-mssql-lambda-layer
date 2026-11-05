ARG PYTHON_VERSION=3.12
FROM public.ecr.aws/sam/build-python${PYTHON_VERSION}
ENTRYPOINT []

# Optional pin, e.g. --build-arg DUCKDB_VERSION=1.4.4 (empty = latest)
ARG DUCKDB_VERSION=

# Install duckdb into the layer's Python path
RUN if [ -n "$DUCKDB_VERSION" ]; then spec="duckdb==$DUCKDB_VERSION"; else spec="duckdb"; fi \
    && pip3 install "$spec" --upgrade --no-cache-dir --target /opt/python

# Pre-install the mssql community extension (native TDS, no ODBC required).
# Lambda's filesystem is read-only except /tmp, so the extension is bundled in the layer.
RUN PYTHONPATH=/opt/python python -c "\
import duckdb; \
con = duckdb.connect(config={'extension_directory': '/opt/duckdb_extensions'}); \
con.execute('INSTALL mssql FROM community'); \
con.execute('LOAD mssql'); \
print('duckdb', duckdb.__version__)"

# Reduce layer size
RUN find /opt/python -type d -name __pycache__ -prune -exec rm -rf {} + \
    && rm -rf /opt/python/bin

# Remove the build image's bundled Python runtime; it is not part of the layer.
RUN rm -rf /opt/uv

# Generate the zipped file that can be uploaded as a Lambda Layer
WORKDIR /opt
RUN zip -rq /layer.zip .
