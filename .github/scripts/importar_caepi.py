"""
Importa a base CAEPI do Ministério do Trabalho para o Supabase.
Executado automaticamente via GitHub Actions toda segunda-feira às 3h.
"""
import os
import io
import sys
import json
import zipfile
import requests

SUPA_URL     = os.environ['SUPA_URL']
SUPA_KEY     = os.environ['SUPA_SERVICE_KEY']
CAEPI_URL    = 'https://www.gov.br/trabalho-e-emprego/pt-br/assuntos/inspecao-do-trabalho/seguranca-e-saude-no-trabalho/equipamentos-de-protecao-individual-epi/tgg_export_caepi.zip'
BATCH_SIZE   = 500

# Mapeamento flexível: nome no arquivo MTE → coluna no Supabase
# O arquivo pode ter variações entre versões — incluímos aliases
COL_MAP = {
    'NR_CA':                     'numero_ca',
    'REGISTRO_CA':               'numero_ca',
    'CA':                        'numero_ca',
    'NOME_EPI':                  'nome_equipamento',
    'NOME_EQUIPAMENTO':          'nome_equipamento',
    'DESCRICAO_EPI':             'descricao_equipamento',
    'DESCRICAO_EQUIPAMENTO':     'descricao_equipamento',
    'DESCRICAO':                 'descricao_equipamento',
    'MARCA':                     'marca',
    'MARCA_CA':                  'marca',
    'REFERENCIA':                'referencia',
    'DATA_VALIDADE':             'data_validade',
    'VALIDADE':                  'data_validade',
    'SITUACAO':                  'situacao',
    'STATUS':                    'situacao',
    'NORMA':                     'norma',
    'NORMAS':                    'norma',
    'CNPJ':                      'cnpj_fabricante',
    'CNPJ_FABRICANTE':           'cnpj_fabricante',
    'RAZAO_SOCIAL':              'razao_social_fabricante',
    'RAZAO_SOCIAL_FABRICANTE':   'razao_social_fabricante',
    'EMPRESA':                   'razao_social_fabricante',
}

def baixar_arquivo():
    print(f"Baixando arquivo de: {CAEPI_URL}")
    resp = requests.get(CAEPI_URL, timeout=180, allow_redirects=True)
    resp.raise_for_status()
    print(f"Arquivo baixado: {len(resp.content)/1024/1024:.1f} MB")
    return resp.content

def extrair_e_parsear(zip_bytes):
    z = zipfile.ZipFile(io.BytesIO(zip_bytes))
    nomes = z.namelist()
    print(f"Arquivos no ZIP: {nomes}")

    txt = next((n for n in nomes if n.lower().endswith('.txt')), None)
    if not txt:
        raise ValueError(f"Nenhum .txt encontrado no ZIP. Arquivos: {nomes}")

    conteudo = z.read(txt).decode('latin-1', errors='replace')
    linhas = [l for l in conteudo.splitlines() if l.strip()]
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

        registros.append(mapeado)

    print(f"Registros válidos: {len(registros)}")
    return registros

def upsert_supabase(registros):
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
        registros  = extrair_e_parsear(zip_bytes)
        total      = upsert_supabase(registros)
        registrar_log(total, True)
        print(f"\n✅ Importação concluída: {total} registros")
    except Exception as e:
        print(f"\n❌ Erro: {e}", file=sys.stderr)
        registrar_log(0, False, e)
        sys.exit(1)
