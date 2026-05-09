"""
Importa a base CAEPI do Ministério do Trabalho para o Supabase.
Executado automaticamente via GitHub Actions toda segunda-feira às 3h.
"""
import os
import io
import sys
import json
import zipfile
import rarfile
import requests

SUPA_URL     = os.environ['SUPA_URL']
SUPA_KEY     = os.environ['SUPA_SERVICE_KEY']
BATCH_SIZE   = 500

# URLs tentadas em ordem — gov.br pode mudar formato entre versões
CAEPI_URLS = [
    'https://www.gov.br/trabalho-e-emprego/pt-br/assuntos/inspecao-do-trabalho/seguranca-e-saude-no-trabalho/equipamentos-de-protecao-individual-epi/tgg_export_caepi.zip/@@download/tgg_export_caepi.zip',
    'https://www.gov.br/trabalho-e-emprego/pt-br/assuntos/inspecao-do-trabalho/seguranca-e-saude-no-trabalho/equipamentos-de-protecao-individual-epi/tgg_export_caepi.zip',
    'https://www.gov.br/trabalho-e-emprego/pt-br/assuntos/inspecao-do-trabalho/seguranca-e-saude-no-trabalho/equipamentos-de-protecao-individual-epi/tgg_export_caepi.txt',
]

HEADERS_HTTP = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/zip,application/octet-stream,text/plain,*/*',
}

# Mapeamento flexível: nome no arquivo MTE → coluna no Supabase
# O arquivo pode ter variações entre versões — incluímos aliases
COL_MAP = {
    # Formato atual do MTE (sem underscores, com # no primeiro campo)
    '#NRREGISTROCA':             'numero_ca',
    'NOMEEQUIPAMENTO':           'nome_equipamento',
    'DESCRICAOEQUIPAMENTO':      'descricao_equipamento',
    'MARCACA':                   'marca',
    'REFERENCIA':                'referencia',
    'DATAVALIDADE':              'data_validade',
    'SITUACAO':                  'situacao',
    'NORMA':                     'norma',
    'CNPJ':                      'cnpj_fabricante',
    'RAZAOSOCIAL':               'razao_social_fabricante',
    # Aliases para versões anteriores do arquivo
    'NR_CA':                     'numero_ca',
    'REGISTRO_CA':               'numero_ca',
    'NRREGISTROCA':              'numero_ca',
    'NOME_EPI':                  'nome_equipamento',
    'NOME_EQUIPAMENTO':          'nome_equipamento',
    'DESCRICAO_EPI':             'descricao_equipamento',
    'DESCRICAO_EQUIPAMENTO':     'descricao_equipamento',
    'MARCA_CA':                  'marca',
    'DATA_VALIDADE':             'data_validade',
    'RAZAO_SOCIAL':              'razao_social_fabricante',
}

def baixar_arquivo():
    ultimo_erro = None
    for url in CAEPI_URLS:
        print(f"Tentando: {url}")
        try:
            resp = requests.get(url, headers=HEADERS_HTTP, timeout=180, allow_redirects=True)
            resp.raise_for_status()
            conteudo = resp.content
            print(f"Baixado: {len(conteudo)/1024/1024:.1f} MB — Content-Type: {resp.headers.get('Content-Type','?')}")
            print(f"Primeiros bytes: {conteudo[:8]}")
            # Verifica se é ZIP (magic bytes PK) ou texto
            if conteudo[:2] == b'PK' or b'|' in conteudo[:2000]:
                return conteudo
            print(f"  → Conteúdo não reconhecido, tentando próxima URL...")
            print(f"  → Início do conteúdo: {conteudo[:300]}")
        except Exception as e:
            ultimo_erro = e
            print(f"  → Erro: {e}")
    raise RuntimeError(f"Todas as URLs falharam. Último erro: {ultimo_erro}")

def extrair_e_parsear(conteudo):
    if conteudo[:2] == b'PK':
        print("Formato: ZIP")
        z = zipfile.ZipFile(io.BytesIO(conteudo))
        nomes = z.namelist()
        print(f"Arquivos no ZIP: {nomes}")
        txt = next((n for n in nomes if n.lower().endswith('.txt')), None)
        if not txt:
            raise ValueError(f"Nenhum .txt no ZIP. Arquivos: {nomes}")
        texto = z.read(txt).decode('latin-1', errors='replace')
    elif conteudo[:4] == b'Rar!':
        print("Formato: RAR")
        tmp = '/tmp/caepi.rar'
        with open(tmp, 'wb') as f:
            f.write(conteudo)
        rf = rarfile.RarFile(tmp)
        nomes = rf.namelist()
        print(f"Arquivos no RAR: {nomes}")
        txt = next((n for n in nomes if n.lower().endswith('.txt')), None)
        if not txt:
            raise ValueError(f"Nenhum .txt no RAR. Arquivos: {nomes}")
        texto = rf.read(txt).decode('latin-1', errors='replace')
    else:
        print("Formato: TXT direto")
        texto = conteudo.decode('latin-1', errors='replace')

    linhas = [l for l in texto.splitlines() if l.strip()]
    print(f"Total de linhas: {len(linhas)}")

    # Primeira linha: cabeçalho
    headers_brutos = [h.strip().upper() for h in linhas[0].split('|')]
    print(f"Colunas encontradas: {headers_brutos}")

    # Verifica se coluna principal está mapeada
    col_ca = next((h for h in headers_brutos if h in COL_MAP and COL_MAP[h] == 'numero_ca'), None)
    if not col_ca:
        raise ValueError(f"Coluna do CA não encontrada. Headers: {headers_brutos}")

    registros = []
    for linha in linhas[1:]:
        vals = linha.split('|')
        raw = {headers_brutos[i]: vals[i].strip() if i < len(vals) else '' for i in range(len(headers_brutos))}

        mapeado = {}
        for col_mte, col_db in COL_MAP.items():
            if col_mte in raw and raw[col_mte]:
                mapeado[col_db] = raw[col_mte]

        if not mapeado.get('numero_ca'):
            continue

        # Normaliza situacao: trim + upper
        if 'situacao' in mapeado and mapeado['situacao']:
            mapeado['situacao'] = mapeado['situacao'].strip().upper()

        registros.append(mapeado)

    print(f"Registros válidos: {len(registros)}")
    return registros

COLUNAS_DB = [
    'numero_ca', 'nome_equipamento', 'descricao_equipamento',
    'marca', 'referencia', 'data_validade', 'situacao',
    'norma', 'cnpj_fabricante', 'razao_social_fabricante',
]

def normalizar(registros):
    """Garante chaves uniformes e remove duplicatas de numero_ca."""
    vistos = {}
    for r in registros:
        ca = r.get('numero_ca')
        if ca:
            vistos[ca] = {col: r.get(col) for col in COLUNAS_DB}
    dedup = list(vistos.values())
    print(f"Após deduplicação: {len(dedup)} registros únicos (eram {len(registros)})")
    return dedup

def upsert_supabase(registros):
    registros = normalizar(registros)
    headers = {
        'apikey':        SUPA_KEY,
        'Authorization': f'Bearer {SUPA_KEY}',
        'Content-Type':  'application/json',
        'Prefer':        'resolution=merge-duplicates',
    }
    total = 0
    erros = 0
    for i in range(0, len(registros), BATCH_SIZE):
        batch = registros[i:i+BATCH_SIZE]
        resp = requests.post(f'{SUPA_URL}/rest/v1/ca_epi', json=batch, headers=headers, timeout=60)
        if resp.ok:
            total += len(batch)
            print(f"  ✓ {total}/{len(registros)} registros importados")
        else:
            erros += 1
            print(f"  ✗ Erro batch {i}: {resp.status_code} — {resp.text[:200]}")
            if erros > 5:
                raise RuntimeError("Muitos erros consecutivos, abortando.")
    return total

def registrar_log(total, sucesso, erro=None):
    headers = {
        'apikey':        SUPA_KEY,
        'Authorization': f'Bearer {SUPA_KEY}',
        'Content-Type':  'application/json',
    }
    payload = {'total_registros': total, 'sucesso': sucesso}
    if erro:
        payload['erro'] = str(erro)[:500]
    requests.post(f'{SUPA_URL}/rest/v1/ca_epi_importacoes', json=payload, headers=headers, timeout=30)

if __name__ == '__main__':
    try:
        zip_bytes  = baixar_arquivo()
        registros  = extrair_e_parsear(zip_bytes)  # aceita ZIP ou TXT
        total      = upsert_supabase(registros)
        registrar_log(total, True)
        print(f"\n✅ Importação concluída: {total} registros")
    except Exception as e:
        print(f"\n❌ Erro: {e}", file=sys.stderr)
        registrar_log(0, False, e)
        sys.exit(1)
