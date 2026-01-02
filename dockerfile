# Stage 1: Build
FROM debian:bookworm-slim AS builder

# Install dependencies
RUN apt-get update && apt-get install -y unzip curl

# Install postgresql client
RUN apt-get install -y ca-certificates gnupg \
    && install -d /usr/share/postgresql-common/pgdg \
    && curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    && . /etc/os-release \
    && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y postgresql-client-17

# Install awscli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip "awscliv2.zip" \
    && ./aws/install

# Prepare dependencies for distroless
WORKDIR /dist
RUN mkdir -p /dist/lib /dist/bin

# Copy pg_dump binary
# We copy the actual binary, not the /usr/bin/pg_dump wrapper which requires Perl
RUN cp /usr/lib/postgresql/17/bin/pg_dump /dist/bin/

# Identify and copy shared libraries for pg_dump
RUN ldd /usr/lib/postgresql/17/bin/pg_dump | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -L -v '{}' /dist/lib/

# Stage 2: Runtime
# Using debug image for busybox shell support required by backup scripts
FROM gcr.io/distroless/base-debian12:debug

# Prevent aws-cli from needing a pager (less/groff)
ENV AWS_PAGER=""

# Copy AWS CLI
COPY --from=builder /usr/local/aws-cli /usr/local/aws-cli
# Instead of copying the binary (which dereferences symlinks and breaks library lookups),
# we add the installation directory to PATH so the binary is found in its correct context.
ENV PATH="/usr/local/aws-cli/v2/current/bin:${PATH}"

# Copy PostgreSQL client and libs
COPY --from=builder /dist/bin/pg_dump /usr/bin/pg_dump
# Copy shared libraries to /usr/lib (standard library path)
COPY --from=builder /dist/lib/ /usr/lib/

# Copy scripts
COPY --chmod=0755 ./scripts/*.sh /usr/local/bin/

# Set the entrypoint
ENTRYPOINT ["/busybox/sh", "/usr/local/bin/backup.sh"]
