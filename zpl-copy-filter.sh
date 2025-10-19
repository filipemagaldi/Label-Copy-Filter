#!/bin/bash
#
# Filtro Único para ZPL com Múltiplas Cópias e Preservação de Cabeçalho
# Combina as funções de master e copy filter.
#
# 1. Chama o 'rastertolabel' para gerar o código ZPL.
# 2. Preserva cabeçalhos (~DGR) para evitar problemas de cache.
# 3. Injeta o comando de múltiplas cópias ^PQ no primeiro bloco de etiqueta.

LOG_FILE="/tmp/zpl-filter.log"
RASTER_FILTER="/usr/lib/cups/filter/rastertolabel"

# --- Funções de Ajuda ---
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# --- INÍCIO DA EXECUÇÃO ---

# Limpeza e log inicial
echo "" > "$LOG_FILE"
log_message "--- FILTRO ÚNICO ZPL INICIADO ---"
log_message "Argumentos: $1 $2 $3 $4 $5 $6"

JOB_ID="$1"
USER="$2"
TITLE="$3"
COPIES="$4"
JOB_OPTIONS="$5"
FILE_TO_PRINT="$6" # Pode estar vazio

# --- ETAPA 1: Gerar o Código ZPL (Lógica do Master Filter) ---

log_message "Etapa 1: Gerando código ZPL com rastertolabel..."

# Cria um arquivo temporário para armazenar a saída do rastertolabel
TEMP_ZPL_OUTPUT=$(mktemp)

# Executa o rastertolabel com os argumentos corretos
if [ -z "$FILE_TO_PRINT" ]; then
    "$RASTER_FILTER" "$JOB_ID" "$USER" "$TITLE" "$COPIES" "$JOB_OPTIONS" > "$TEMP_ZPL_OUTPUT"
else
    "$RASTER_FILTER" "$JOB_ID" "$USER" "$TITLE" "$COPIES" "$JOB_OPTIONS" "$FILE_TO_PRINT" > "$TEMP_ZPL_OUTPUT"
fi

log_message "Código ZPL gerado (tamanho: $(wc -c < "$TEMP_ZPL_OUTPUT") bytes)."

# --- ETAPA 2: Lógica de Cópias e Impressão Final ---

log_message "Etapa 2: Processando cópias e imprimindo..."

# Se for cópia única, envia o conteúdo completo e sai.
if ! [[ "$COPIES" =~ ^[0-9]+$ ]] || [ "$COPIES" -le 1 ]; then
    log_message "Pedido de cópia única. Passando dados originais."
    cat "$TEMP_ZPL_OUTPUT"
    log_message "--- FILTRO FINALIZADO (Cópia Única) ---"
    rm "$TEMP_ZPL_OUTPUT"
    exit 0
fi

# Se forem múltiplas cópias...
log_message "Pedido de múltiplas cópias ($COPIES). Preservando cabeçalho e modificando a primeira etiqueta."

# Lê todo o fluxo de dados para uma variável
ZPL_DATA=$(cat "$TEMP_ZPL_OUTPUT")

# Separa o cabeçalho (tudo ANTES do primeiro ^XA) do corpo (do primeiro ^XA em diante)
ZPL_HEADER=$(echo -ne "$ZPL_DATA" | sed '/\^XA/Q')
ZPL_BODY=$(echo -ne "$ZPL_DATA" | sed -n '/\^XA/,$p')

if [ -z "$ZPL_BODY" ]; then
    log_message "ERRO: Bloco ^XA não encontrado. Passando dados originais."
    echo -ne "$ZPL_DATA"
    rm "$TEMP_ZPL_OUTPUT"
    exit 0
fi

# Pega apenas o primeiro bloco de etiqueta (^XA...^XZ) do corpo
ZPL_FIRST_PAGE=$(echo -ne "$ZPL_BODY" | awk '/\^XA/{f=1} f{print; if (/\^XZ/) exit}')

log_message "Cabeçalho e primeira página extraídos. Injetando ^PQ$COPIES."

# Remove qualquer ^PQ preexistente e injeta o nosso no bloco da primeira página
ZPL_FIRST_PAGE_CLEAN=$(echo "$ZPL_FIRST_PAGE" | sed 's/\^PQ[0-9]*//g')
MODIFIED_PAGE="${ZPL_FIRST_PAGE_CLEAN/\^XA/^XA\n^PQ$COPIES}"

# Junta o cabeçalho original com o bloco da página modificada e envia para a impressora
echo -ne "$ZPL_HEADER$MODIFIED_PAGE"

log_message "--- FILTRO FINALIZADO (Múltiplas Cópias com Cabeçalho) ---"

# Limpa o arquivo temporário
rm "$TEMP_ZPL_OUTPUT"
exit 0



