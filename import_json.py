import json
import os

PASTA_ENTRADA = r"Desktop\jsons"
OUTPUT_FILE = r"Desktop\saida_filtrada.json"

def filtrar_campos(obj):
    """Extrai apenas os campos desejados de um objeto que já passou no filtro do SELECT"""
    campos_desejados = ["name", "delay", "params", "description"]
    return {k: obj[k] for k in campos_desejados if k in obj}

def contem_select(obj):
    """Verifica se o objeto tem SQL (SELECT) no campo params"""
    if isinstance(obj, dict):
        params = obj.get("params")
        if isinstance(params, str) and "select" in params.lower():
            return True
    return False

def filtrar_json(obj):
    """Filtra recursivamente e limpa os campos irrelevantes"""
    if isinstance(obj, dict):
        if contem_select(obj):
            return filtrar_campos(obj)  # Retorna apenas o que importa
        
        novo_dict = {}
        for k, v in obj.items():
            filtrado = filtrar_json(v)
            if filtrado:
                novo_dict[k] = filtrado
        return novo_dict if novo_dict else None

    elif isinstance(obj, list):
        nova_lista = []
        for item in obj:
            filtrado = filtrar_json(item)
            if filtrado:
                nova_lista.append(filtrado)
        return nova_lista if nova_lista else None
    
    return None



# Garante que a pasta existe para não dar erro
if not os.path.exists(PASTA_ENTRADA):
    print(f"Erro: A pasta {PASTA_ENTRADA} não foi encontrada na Área de Trabalho.")
else:
    resultados_por_arquivo = {}

    for nome_arquivo in os.listdir(PASTA_ENTRADA):
        if nome_arquivo.endswith(".json"):
            caminho_completo = os.path.join(PASTA_ENTRADA, nome_arquivo)
            
            try:
                with open(caminho_completo, "r", encoding="utf-8") as f:
                    data = json.load(f)
                
                filtrado = filtrar_json(data)
                
                if filtrado:
                    resultados_por_arquivo[nome_arquivo] = filtrado
                    print(f"✔ {nome_arquivo} processado com sucesso.")
                else:
                    print(f"○ {nome_arquivo} não continha itens com 'SELECT'.")

            except Exception as e:
                print(f"❌ Erro ao ler {nome_arquivo}: {e}")


    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(resultados_por_arquivo, f, indent=2, ensure_ascii=False)

    print(f"\nConcluído! Resultado salvo em: {OUTPUT_FILE}")