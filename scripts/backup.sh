#!/bin/sh

# Validar parámetros
# AWS_ACCESS_KEY AWS_SECRET_KEY AWS_BUCKET
MISSING_VARS=""
for VAR in PGHOST PGPORT PGUSER PGPASSWORD PGDATABASE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION AWS_S3_BUCKET; do
    eval VALUE=\$$VAR
    if [ -z "$VALUE" ]; then
        MISSING_VARS="$MISSING_VARS $VAR"
    fi
done

if [ -n "$MISSING_VARS" ]; then
    echo "💀 Error: No se proporcionaron las variables de entorno:$MISSING_VARS"
    exit 1
fi

# Configurar la fecha para los nombres de los archivos de respaldo
DATE=$(date +%Y%m%d%H%M)
DUMP_PATH="/tmp/${PGDATABASE}_${DATE}.dump"

echo "📦 Iniciando respaldo de $PGDATABASE..."
pg_dump -b -v -F c -d $PGDATABASE -f "$DUMP_PATH"

if [ $? -ne 0 ]; then
    echo "💀 Error al realizar el respaldo de $PGDATABASE"
    exit 1
fi
echo "✅ Respaldo exitoso de $PGDATABASE - $DUMP_PATH"

echo "📦 Subiendo a S3 bucket: $AWS_S3_BUCKET..."
aws s3 cp "$DUMP_PATH" "s3://$AWS_S3_BUCKET/$PGDATABASE/$PGDATABASE-$DATE.dump"

if [ $? -ne 0 ]; then
    echo "💀 Error al subir el respaldo a S3"
    exit 1
fi
echo "✅ Subida exitosa a S3"
