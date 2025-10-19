#!/bin/bash
#
# Filtro Único para EPL com Calibração e Cópias Otimizadas
# Combina as funções de master e copy filter.
#
# 1. Chama o 'rastertolabel' para gerar o código EPL.
# 2. Calcula e envia comandos de calibração (N, q, Q, ZC).
# 3. Injeta o comando de múltiplas cópias P<N> de forma otimizada e segura.

LOG_FILE="/tmp/epl-filter.log"
RASTER_FILTER="/usr/lib/cups/filter/rastertolabel"

# --- Funções de Ajuda ---
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# --- INÍCIO DA EXECUÇÃO ---

# Limpeza e log inicial
echo "" > "$LOG_FILE"
log_message "--- FILTRO ÚNICO EPL INICIADO ---"
log_message "Argumentos: $1 $2 $3 $4 $5 $6"

JOB_ID="$1"
USER="$2"
TITLE="$3"
COPIES="$4"
JOB_OPTIONS="$5"
FILE_TO_PRINT="$6" # Pode estar vazio

# --- ETAPA 1: Gerar o Código EPL (Lógica do Master Filter) ---

log_message "Etapa 1: Gerando código EPL com rastertolabel..."

# Cria um arquivo temporário para armazenar a saída do rastertolabel
TEMP_EPL_OUTPUT=$(mktemp)

# Executa o rastertolabel com os argumentos corretos
if [ -z "$FILE_TO_PRINT" ]; then
    "$RASTER_FILTER" "$JOB_ID" "$USER" "$TITLE" "$COPIES" "$JOB_OPTIONS" > "$TEMP_EPL_OUTPUT"
else
    "$RASTER_FILTER" "$JOB_ID" "$USER" "$TITLE" "$COPIES" "$JOB_OPTIONS" "$FILE_TO_PRINT" > "$TEMP_EPL_OUTPUT"
fi

log_message "Código EPL gerado (tamanho: $(wc -c < "$TEMP_EPL_OUTPUT") bytes)."

# --- ETAPA 2: Lógica de Calibração ---

log_message "Etapa 2: Processando calibração..."

DPI=$(echo "$JOB_OPTIONS" | grep -o 'Resolution=[0-9]*dpi' | sed 's/Resolution=//;s/dpi//')
PAGE_SIZE_STR=$(echo "$JOB_OPTIONS" | grep -o 'PageSize=Custom.[0-9.]*x[0-9.]*')

if [ -n "$DPI" ] && [ -n "$PAGE_SIZE_STR" ]; then
    log_message "Resolução: $DPI dpi, Tamanho: $PAGE_SIZE_STR"
    
    WIDTH_PTS=$(echo "$PAGE_SIZE_STR" | sed 's/PageSize=Custom.//;s/x.*//')
    LENGTH_PTS=$(echo "$PAGE_SIZE_STR" | sed 's/.*x//')

    WIDTH_DOTS=$(echo "($WIDTH_PTS * $DPI) / 72" | bc)
    LENGTH_DOTS=$(echo "($LENGTH_PTS * $DPI) / 72" | bc)
    GAP_DOTS=35 # Valor padrão, ajuste se necessário

    log_message "Calculado -> Largura: $WIDTH_DOTS dots, Altura: $LENGTH_DOTS dots"

    # Envia os comandos de calibração diretamente para a impressora
    echo -e "N"
    echo -e "q$WIDTH_DOTS"
    echo -e "Q$LENGTH_DOTS,$GAP_DOTS"
    echo -e "ZC"
    
    log_message "Comandos de calibração enviados."
else
    log_message "Aviso: Calibração não enviada (Resolução/Tamanho não encontrados)."
fi

# --- ETAPA 3: Lógica de Cópias e Impressão Final ---

log_message "Etapa 3: Processando cópias e imprimindo..."

# Se for cópia única, envia o conteúdo da primeira etiqueta e sai.
if ! [[ "$COPIES" =~ ^[0-9]+$ ]] || [ "$COPIES" -le 1 ]; then
    log_message "Pedido de cópia única."
    # Lê do arquivo temporário, remove comandos redundantes e envia para a impressora
    cat "$TEMP_EPL_OUTPUT" | sed '/^N/d; /^q/d; /^Q/d'
    log_message "--- FILTRO FINALIZADO (Cópia Única) ---"
    rm "$TEMP_EPL_OUTPUT"
    exit 0
fi

# Se forem múltiplas cópias...
log_message "Pedido de múltiplas cópias ($COPIES)."

# Lê do arquivo temporário e aplica a lógica otimizada de cópias
cat "$TEMP_EPL_OUTPUT" | sed -e '/^P[0-9][0-9]*/q' | sed -e '/^N/d; /^q/d; /^Q/d' | sed -e "s/^P[0-9][0-9]*/P$COPIES/"

log_message "--- FILTRO FINALIZADO (Múltiplas Cópias) ---"

# Limpa o arquivo temporário
rm "$TEMP_EPL_OUTPUT"
exit 0



