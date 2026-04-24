import json
import re

INPUT_FILE = r"saida_filtrada - copia.json"
OUTPUT_FILE = r"saida_formatada.json"


def limpar_string(s):
    """Remove quebras de linha e espaços extras"""
    return re.sub(r"\s+", " ", s.replace("\n", " ").replace("\r", " ")).strip()


def normalizar_sql(sql):
    """Normaliza SQL para comparação"""
    sql = limpar_string(sql)
    return sql.lower()  # ignora maiúsculo/minúsculo


def processar_obj(obj, vistos):
    """Percorre estrutura removendo duplicados baseado no params"""
    
    if isinstance(obj, dict):
        # Se for um item com params
        if "params" in obj and isinstance(obj["params"], str):
            sql_normalizado = normalizar_sql(obj["params"])

            if sql_normalizado in vistos:
                return None  # remove duplicado
            
            vistos.add(sql_normalizado)

            # limpa o params também
            obj["params"] = limpar_string(obj["params"])
            return obj

        novo = {}
        for k, v in obj.items():
            filtrado = processar_obj(v, vistos)
            if filtrado:
                novo[k] = filtrado

        return novo if novo else None

    elif isinstance(obj, list):
        nova_lista = []
        for item in obj:
            filtrado = processar_obj(item, vistos)
            if filtrado:
                nova_lista.append(filtrado)

        return nova_lista if nova_lista else None

    return obj


# --- Execução ---

with open(INPUT_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)

vistos = set()

resultado_final = {}

for arquivo, conteudo in data.items():
    filtrado = processar_obj(conteudo, vistos)

    if filtrado:
        resultado_final[arquivo] = filtrado


with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    json.dump(resultado_final, f, indent=2, ensure_ascii=False)

print(f"\n✅ Finalizado! Arquivo salvo em: {OUTPUT_FILE}")