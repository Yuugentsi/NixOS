#!/usr/bin/env bash

# Define que o script deve sair imediatamente se um comando falhar (-e),
# se uma variável não for definida (-u), e falhar em pipelines (-o pipefail).
set -euo pipefail

# Define o caminho para o arquivo de configuração do NixOS
readonly FILE_TO_EDIT="/etc/nixos/modules/packages.nix"
# Define um arquivo temporário para comparar o conteúdo antes e depois da edição
readonly TEMP_FILE="/tmp/packages.nix.tmp"

# Verifica se o arquivo de configuração existe
if [ ! -f "$FILE_TO_EDIT" ]; then
    notify-send "NixOS Rebuild Error" "File not found: $FILE_TO_EDIT"
    exit 1
fi

# Copia o conteúdo atual do arquivo para o arquivo temporário (requer sudo)
sudo cat "$FILE_TO_EDIT" > "$TEMP_FILE"

# Abre o arquivo para edição no Kitty com nano e sudo
# A classe 'floating_terminal' pode ser usada para regras no seu gerenciador de janelas
kitty --class floating_terminal sudo nano "$FILE_TO_EDIT"

# Compara o conteúdo do arquivo editado com o conteúdo original
if ! sudo diff -q "$FILE_TO_EDIT" "$TEMP_FILE" > /dev/null; then
    # Se houver mudanças, notifica e inicia a reconstrução
    notify-send "NixOS Rebuild" "Changes detected. Starting rebuild..."

    # Executa a reconstrução do NixOS, capturando a saída em tempo real
    # e enviando notificações para fases específicas
    if sudo nixos-rebuild switch 2>&1 | while IFS= read -r line; do
        echo "$line" # Imprime a linha para o stdout (pode ser útil para logs)

        # Verifica por palavras-chave na saída para identificar o progresso
        if [[ "$line" == *"building"* ]]; then
            notify-send "NixOS Rebuild Progress" "Building..."
        elif [[ "$line" == *"activating new configuration"* ]]; then
            notify-send "NixOS Rebuild Progress" "Activating new configuration..."
        elif [[ "$line" == *"deleting old generations"* ]]; then
            notify-send "NixOS Rebuild Progress" "Cleaning up old generations..."
        fi
    done; then
        # Se o comando nixos-rebuild switch foi bem-sucedido
        notify-send "NixOS Rebuild" "Rebuild successful!"
    else
        # Se o comando nixos-rebuild switch falhou
        notify-send "NixOS Rebuild Error" "Rebuild failed! Check terminal for details."
    fi
else
    # Se não houver mudanças, notifica que nenhuma reconstrução é necessária
    notify-send "NixOS Rebuild" "No changes detected. No rebuild needed."
fi

# Limpa o arquivo temporário
rm -f "$TEMP_FILE"