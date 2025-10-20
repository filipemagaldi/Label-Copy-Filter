#!/bin/bash

# Script para instalar o filtro de cópias apropriado (ZPL ou EPL2) para uma
# impressora CUPS, detectando a linguagem, garantindo a persistência da
# configuração, definindo cópias manuais e reiniciando o serviço no final.

# --- VERIFICAÇÕES INICIAIS ---

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "ERRO: Este script precisa ser executado com privilégios de root (sudo)."
  exit 1
fi

# Verificar se o nome da impressora foi passado como parâmetro
if [ -z "$1" ]; then
  echo "Uso: sudo ./install.sh <nome_da_impressora_no_cups>"
  echo "Exemplo: sudo ./install.sh Zebra_ZPL_Escritorio"
  exit 1
fi

PRINTER_NAME="$1"
PPD_FILE_PATH="/etc/cups/ppd/${PRINTER_NAME}.ppd"

# Verificar se o arquivo PPD da impressora existe
if [ ! -f "$PPD_FILE_PATH" ]; then
  echo "ERRO: O arquivo PPD para a impressora '$PRINTER_NAME' não foi encontrado em '$PPD_FILE_PATH'."
  echo "Por favor, verifique o nome da impressora com o comando 'lpstat -p -d'."
  exit 1
fi

# Verificar se os scripts dos filtros estão na mesma pasta
if [ ! -f "zpl-copy-filter.sh" ] || [ ! -f "epl2-copy-filter.sh" ]; then
    echo "ERRO: Certifique-se de que os arquivos 'zpl-copy-filter.sh' e 'epl2-copy-filter.sh' estão no mesmo diretório que este script."
    exit 1
fi

# --- DETECÇÃO DA LINGUAGEM DA IMPRESSORA ---

echo "Analisando o PPD da impressora para detectar a linguagem (ZPL ou EPL2)..."
PRINTER_LANG=""
FILTER_SCRIPT_NAME=""

# Procura por "zpl" (case-insensitive) no arquivo PPD
if grep -qi "zpl" "$PPD_FILE_PATH"; then
    PRINTER_LANG="ZPL"
    FILTER_SCRIPT_NAME="zpl-copy-filter.sh"
# Se não achar ZPL, procura por "epl"
elif grep -qi "epl" "$PPD_FILE_PATH"; then
    PRINTER_LANG="EPL2"
    FILTER_SCRIPT_NAME="epl2-copy-filter.sh"
fi

# Se nenhuma linguagem for detectada, encerra o script
if [ -z "$PRINTER_LANG" ]; then
    echo "ERRO: Não foi possível detectar se a impressora é ZPL ou EPL2."
    echo "Este script é compatível apenas com impressoras que mencionam sua linguagem no arquivo PPD."
    exit 1
fi

echo "Detectada linguagem da impressora: $PRINTER_LANG"
echo "Será instalado o filtro: $FILTER_SCRIPT_NAME"
echo ""

# --- VARIÁVEIS DE CONFIGURAÇÃO ---
FILTER_SOURCE_PATH="$(pwd)/${FILTER_SCRIPT_NAME}"
FILTER_DEST_PATH="/usr/lib/cups/filter/${FILTER_SCRIPT_NAME}"
MODEL_DIR="/usr/share/cups/model/custom"
MODIFIED_PPD_NAME="${PRINTER_NAME}-custom.ppd"
MODIFIED_PPD_DEST_PATH="${MODEL_DIR}/${MODIFIED_PPD_NAME}"


# --- INÍCIO DA INSTALAÇÃO ---

echo "Iniciando a instalação do filtro para a impressora: $PRINTER_NAME"

# 1) Copiar o filtro para a pasta do CUPS e dar permissão de execução
echo "1/5: Copiando $FILTER_SCRIPT_NAME para /usr/lib/cups/filter/..."
cp "$FILTER_SOURCE_PATH" "$FILTER_DEST_PATH"
chmod +x "$FILTER_DEST_PATH"
echo "Filtro copiado e com permissão de execução."
echo ""

# 2) Modificar o arquivo PPD
echo "2/5: Modificando o arquivo PPD em $PPD_FILE_PATH..."
# Cria um backup do PPD original por segurança
cp "$PPD_FILE_PATH" "${PPD_FILE_PATH}.bak"
echo "Backup do PPD original criado em ${PPD_FILE_PATH}.bak"

# a) Modifica a linha cupsFilter
sed -i "s/^\*cupsFilter:.*/\*cupsFilter: \"application\/vnd.cups-raster 50 $FILTER_SCRIPT_NAME\"/" "$PPD_FILE_PATH"
echo "Linha cupsFilter modificada com sucesso."

# b) Garante que *cupsManualCopies esteja definido como True
if grep -q "^\*cupsManualCopies:" "$PPD_FILE_PATH"; then
    # Se a linha existe, substitui para garantir que seja 'True'
    sed -i 's/^\*cupsManualCopies:.*/\*cupsManualCopies: True/' "$PPD_FILE_PATH"
    echo "Linha *cupsManualCopies atualizada para True."
else
    # Se a linha não existe, adiciona após a linha *cupsFilter
    sed -i "/^\*cupsFilter:.*/a \*cupsManualCopies: True" "$PPD_FILE_PATH"
    echo "Linha *cupsManualCopies: True adicionada ao PPD."
fi
echo ""

# 3) Copiar o PPD modificado para a pasta de modelos do CUPS
echo "3/5: Copiando PPD modificado para o diretório de modelos para persistência..."
mkdir -p "$MODEL_DIR"
cp "$PPD_FILE_PATH" "$MODIFIED_PPD_DEST_PATH"
echo "PPD copiado para $MODIFIED_PPD_DEST_PATH"
echo ""

# 4) Recarregar a impressora para usar o novo PPD como modelo
echo "4/5: Recarregando a configuração da impressora no CUPS..."
lpadmin -p "$PRINTER_NAME" -m "custom/$MODIFIED_PPD_NAME"
echo "Impressora reconfigurada."
echo ""

# 5) Reiniciar o serviço CUPS para aplicar todas as mudanças
echo "5/5: Reiniciando o serviço CUPS..."
systemctl restart cups
echo "Serviço CUPS reiniciado."
echo ""

echo "------------------------------------------------------------"
echo "Instalação concluída com sucesso!"
echo "A impressora '$PRINTER_NAME' agora usa o filtro $PRINTER_LANG customizado."
echo "O sistema já está pronto para imprimir."
echo "------------------------------------------------------------"

exit 0
