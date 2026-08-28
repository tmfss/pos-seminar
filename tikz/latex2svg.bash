#!/bin/bash

#> Inksplt macro
inksplit() {
    if [ -z "$1" ]; then
        echo "Erro: Forneça o nome do arquivo. Exemplo: inksplit documento.pdf"
        return 1
    fi

    local FILE="$1"

    # Descobre o número total de páginas automaticamente
    local PAGES
    PAGES=$(pdfinfo "$FILE" 2>/dev/null | grep "Pages:" | awk '{print $2}')

    local FILENAME
    FILENAME=$(basename "$FILE" .pdf) # Remove a extensão .pdf do nome
    
    if [ "$PAGES" -eq 1 ]; then 
        inkscape "$FILE" --export-filename="$OUTPUT_DIR/${FILENAME}.svg"
    else 
        for i in $(seq 1 "$PAGES"); do 
            inkscape --pages="$i" "$FILE" --export-filename="$OUTPUT_DIR/${FILENAME}_$i.svg"
        done
    fi 
}

TARGET_FILE="$1"
INPUT_DIR="tikz"
OUTPUT_DIR="tikz"
LATEXMK_DIR="build"

# Array que vai guardar a lista de arquivos a compilar
files2compile=()

# Verifica se um argumento foi passado
if [ -n "$TARGET_FILE" ]; then
    # Verifica se o arquivo foi passado com o caminho (ex: tikz/file.tex) ou só o nome (ex: file.tex)
    if [ -f "$TARGET_FILE" ]; then
        files2compile=("$TARGET_FILE")
    elif [ -f "$INPUT_DIR/$TARGET_FILE" ]; then
        files2compile=("$INPUT_DIR/$TARGET_FILE")
    else
        echo "Erro: Arquivo '$TARGET_FILE' não encontrado."
        exit 1
    fi
else
    # Comportamento antigo: pega todos os arquivos .tex da pasta
    readarray -t files2compile < <(ls "$INPUT_DIR"/*.tex 2>/dev/null)
    
    if [ ${#files2compile[@]} -eq 0 ]; then
        echo "Nenhum arquivo .tex encontrado em $INPUT_DIR/"
        exit 0
    fi
fi

# Loop unificado: compila e já transforma o arquivo correspondente
for tex_file in "${files2compile[@]}"; do
    echo "Processando: $tex_file"
    
    # Compilação
    latexmk -silent -r "$INPUT_DIR/.latexmkrc" -outdir="$INPUT_DIR" "$tex_file"
    
    # Descobre o nome do PDF gerado
    base_name=$(basename "$tex_file" .tex)
    pdf_file="$INPUT_DIR/${base_name}.pdf"
    
    # Transformação
    if [ -f "$pdf_file" ]; then
        inksplit "$pdf_file"
    else
        echo "Aviso: O arquivo PDF ($pdf_file) não foi gerado corretamente."
    fi
done

# Limpeza
# (Corrigi um pequeno bug no rm do .gz onde o * estava dentro das aspas e não funcionaria)
rm -rf build
rm -rf "$LATEXMK_DIR"
rm -f "$INPUT_DIR"/*.pdf
rm -f "$INPUT_DIR"/*.gz