// SGS Trial Check — incluir em todas as páginas protegidas
// <script src="trial_check.js"></script>

(async function verificarTrial(){
  const SUPA_URL='https://ookqdukeulwcnhilbgbo.supabase.co';
  const SUPA_KEY='sb_publishable_l9NggU-e1bgt7CnrYUWo4w_AMoaJa2e';

  let token=localStorage.getItem('sgs_token');
  const userRaw=localStorage.getItem('sgs_user');
  if(!token||!userRaw)return;

  const user=JSON.parse(userRaw);

  // Tenta renovar o token automaticamente se estiver expirado ou prestes a expirar
  token = await renovarTokenSeNecessario(SUPA_URL, SUPA_KEY, token);
  if(!token) return;

  // SUPERADMIN nunca bloqueia
  try{
    const resPerfil=await fetch(`${SUPA_URL}/rest/v1/usuarios?user_id=eq.${user.id}&select=perfil`,{
      headers:{'apikey':SUPA_KEY,'Authorization':`Bearer ${token}`}
    });
    if(resPerfil.status===401){ redirecionarLogin(); return; }
    const perfil=await resPerfil.json();
    if(perfil[0]?.perfil==='SUPERADMIN')return;
  }catch(e){return;}

  // Busca assinatura ativa
  try{
    const res=await fetch(`${SUPA_URL}/rest/v1/assinaturas?user_id=eq.${user.id}&ativo=eq.true&select=status,data_fim_trial&order=criado_em.desc&limit=1`,{
      headers:{'apikey':SUPA_KEY,'Authorization':`Bearer ${token}`}
    });
    if(res.status===401){ redirecionarLogin(); return; }

    const assinaturas=await res.json();
    const assinatura=assinaturas[0];

    if(!assinatura){mostrarBloqueio(0);return;}
    if(assinatura.status==='Ativo')return;

    if(assinatura.status==='Trial'){
      const fim=new Date(assinatura.data_fim_trial+'T00:00:00');
      const hoje=new Date();hoje.setHours(0,0,0,0);
      const dias=Math.ceil((fim-hoje)/(1000*60*60*24));
      if(dias<=0){mostrarBloqueio(0);return;}
      if(dias<=7){mostrarAvisoTrial(dias);return;}
      return;
    }

    mostrarBloqueio(-1);
  }catch(e){console.error('Erro ao verificar trial:',e);}
})();

// Renovação automática de token
async function renovarTokenSeNecessario(SUPA_URL, SUPA_KEY, token){
  try{
    const payload=JSON.parse(atob(token.split('.')[1]));
    const expiraEm=payload.exp*1000;
    const margem=5*60*1000; // renova se faltar menos de 5 minutos
    if(Date.now() < expiraEm - margem) return token; // ainda válido
  }catch(e){ /* token malformado, tenta renovar */ }

  const refreshToken=localStorage.getItem('sgs_refresh_token');
  if(!refreshToken){ redirecionarLogin(); return null; }

  try{
    const res=await fetch(`${SUPA_URL}/auth/v1/token?grant_type=refresh_token`,{
      method:'POST',
      headers:{'Content-Type':'application/json','apikey':SUPA_KEY},
      body:JSON.stringify({refresh_token:refreshToken})
    });
    if(!res.ok){ redirecionarLogin(); return null; }
    const data=await res.json();
    localStorage.setItem('sgs_token', data.access_token);
    if(data.refresh_token) localStorage.setItem('sgs_refresh_token', data.refresh_token);
    return data.access_token;
  }catch(e){
    console.error('Erro ao renovar token:', e);
    return token;
  }
}

function redirecionarLogin(){
  localStorage.removeItem('sgs_token');
  localStorage.removeItem('sgs_refresh_token');
  localStorage.removeItem('sgs_user');
  window.location.href='login.html';
}

function mostrarBloqueio(dias){
  const overlay=document.createElement('div');
  overlay.style.cssText='position:fixed;inset:0;background:rgba(15,17,23,.97);z-index:99999;display:flex;align-items:center;justify-content:center;font-family:IBM Plex Sans,sans-serif;';
  overlay.innerHTML=`
    <div style="max-width:480px;width:90%;background:#181c27;border:1px solid #2a3044;border-radius:16px;padding:40px;text-align:center;">
      <div style="font-size:40px;margin-bottom:16px;">🔒</div>
      <div style="font-size:20px;font-weight:600;color:#e8eaf0;margin-bottom:10px;">
        ${dias===0?'Período de teste encerrado':'Acesso bloqueado'}
      </div>
      <div style="font-size:14px;color:#8892a4;line-height:1.6;margin-bottom:28px;">
        ${dias===0
          ?'Seu período de <strong style="color:#e8eaf0;">30 dias grátis</strong> encerrou. Assine o SGS para continuar gerenciando sua SST sem interrupções.'
          :'Sua assinatura está inativa. Regularize para continuar usando o sistema.'
        }
      </div>
      <a href="assinar.html" style="display:inline-flex;align-items:center;gap:8px;background:#2dd4a0;color:#0f1117;font-size:15px;font-weight:600;padding:14px 32px;border-radius:6px;text-decoration:none;margin-bottom:14px;">
        ✨ Assinar agora — R$ 999/mês
      </a>
      <div style="font-size:12px;color:#545e72;margin-top:12px;">
        Dúvidas? <a href="https://wa.me/5594981564271" target="_blank" style="color:#4a7cdc;">Fale no WhatsApp</a>
      </div>
    </div>`;
  document.body.appendChild(overlay);
  document.body.style.overflow='hidden';
}

function mostrarAvisoTrial(dias){
  const aviso=document.createElement('div');
  aviso.style.cssText='position:fixed;bottom:20px;right:20px;background:#2a2010;border:1px solid #4a3a10;border-radius:10px;padding:14px 18px;z-index:9999;font-family:IBM Plex Sans,sans-serif;max-width:320px;display:flex;gap:10px;align-items:flex-start;box-shadow:0 4px 20px rgba(0,0,0,.5);';
  aviso.innerHTML=`
    <div style="font-size:20px;flex-shrink:0;">⏰</div>
    <div>
      <div style="font-size:13px;font-weight:500;color:#e8eaf0;margin-bottom:4px;">Trial vence em ${dias} dia(s)</div>
      <div style="font-size:12px;color:#e0a855;margin-bottom:8px;">Assine para não perder o acesso ao sistema.</div>
      <a href="assinar.html" style="font-size:12px;background:#e0a855;color:#0f1117;padding:5px 14px;border-radius:4px;text-decoration:none;font-weight:600;">Assinar agora</a>
    </div>
    <button onclick="this.parentNode.remove()" style="background:none;border:none;color:#545e72;cursor:pointer;font-size:16px;flex-shrink:0;padding:0;line-height:1;">×</button>`;
  document.body.appendChild(aviso);
  setTimeout(()=>aviso.remove(),10000);
}
