# Padrões Frontend — SGS

## Design System
```css
:root {
  --bg: #0f1117;
  --surface: #181c27;
  --surface2: #1e2333;
  --border: #2a3044;
  --border-focus: #4a7cdc;
  --accent: #4a7cdc;
  --accent2: #2dd4a0;
  --text: #e8eaf0;
  --text2: #8892a4;
  --text3: #545e72;
  --danger: #e05555;
  --warning: #e0a855;
  --success: #2dd4a0;
  --radius: 6px;
  --mono: 'IBM Plex Mono', monospace;
  --sans: 'IBM Plex Sans', sans-serif;
}
```

## Estrutura padrão de página
```html
<div class="header">
  <a href="index.html" class="header-logo">SGS</a>
  <div class="header-title">... / <span>Módulo</span></div>
</div>
<div class="container">...</div>
```

## Padrão de Modal
```html
<div class="modal-overlay" id="modal-X">
  <div class="modal">
    <div class="modal-titulo">
      <span>Título</span>
      <button onclick="fecharModalX()">×</button>
    </div>
    <!-- conteúdo -->
    <div class="status-bar" id="status-X"></div>
    <div style="display:flex;gap:10px;justify-content:flex-end;">
      <button class="btn btn-cancel" onclick="fecharModalX()">Cancelar</button>
      <button class="btn btn-save" id="btn-salvar-X" onclick="salvarX()">
        <span class="spinner" id="spinner-X"></span>
        <span id="label-salvar-X">Salvar</span>
      </button>
    </div>
  </div>
</div>
```
Abrir: `document.getElementById('modal-X').classList.add('show')`
Fechar: `document.getElementById('modal-X').classList.remove('show')`

## Padrão de operação assíncrona
```javascript
async function salvarX() {
  document.getElementById('btn-salvar-X').disabled = true;
  document.getElementById('spinner-X').className = 'spinner show';
  document.getElementById('label-salvar-X').textContent = 'Salvando...';
  try {
    // operação
    setStatus('status-X', 'success', 'Salvo!');
  } catch(e) {
    setStatus('status-X', 'error', e.message);
  } finally {
    document.getElementById('btn-salvar-X').disabled = false;
    document.getElementById('spinner-X').className = 'spinner';
    document.getElementById('label-salvar-X').textContent = 'Salvar';
  }
}
```

## Funções utilitárias padrão
```javascript
// Escape HTML — SEMPRE usar antes de inserir no DOM
function escHtml(s) { /* ou h(s) */ }

// Status bar
function setStatus(id, tipo, msg) // tipo: 'success' | 'error' | 'info'
function clearStatus(id)

// Toast (notificação flutuante)
function toast(msg, href)

// Data
function fmtData(d)       // 'DD/MM/YYYY'
function fmtDataAtual()   // 'YYYY-MM-DD'
```

## Padrão de formulário (campos)
```html
<div class="modal-field">
  <label>Nome do campo *</label>
  <input type="text" id="x-campo" placeholder="...">
</div>
<div class="modal-field full"> <!-- full = grid-column:1/-1 -->
  <textarea id="x-descricao"></textarea>
</div>
```

## Classes de botão
```
.btn .btn-primary   → azul (ação principal)
.btn .btn-save      → verde (salvar)
.btn .btn-cancel    → cinza (cancelar)
.btn .btn-edit      → neutro (editar)
.btn .btn-danger    → vermelho (excluir)
.btn .btn-sm        → tamanho pequeno
.btn-ia             → roxo (botão IA) — definido em ia_copilot.js
.btn-ia-medida      → botão ✨ inline em textarea
```

## Regras obrigatórias
1. NUNCA inserir dado do banco no DOM sem `escHtml()` / `h()`
2. NUNCA usar `alert()` exceto em confirmações de exclusão
3. SEMPRE desabilitar botão durante operação assíncrona
4. SEMPRE mostrar spinner durante loading
5. NUNCA cores hardcodadas — usar variáveis CSS do projeto
6. Fechar modal ao clicar fora: `if(e.target===this) fecharModal()`

## Padrão de autenticação
```javascript
const token = localStorage.getItem('sgs_token');
if (!token) window.location.href = 'login.html';

const params = new URLSearchParams(window.location.search);
const empresaId = params.get('empresa_id');
if (!empresaId) window.location.href = 'empresas.html';
```

## Includes obrigatórios em páginas protegidas
```html
<script src="trial_check.js"></script>
<script src="plano_utils.js"></script>
<!-- Se usar IA: -->
<script src="ia_copilot.js?v=7"></script>
```
