import { useState } from "react";
import { Activity, LockKeyhole, Mail } from "lucide-react";
import { useAuth } from "../contexts/AuthContext";
import { isSupabaseConfigured } from "../lib/supabase";
import { Navigate } from "react-router-dom";

export function LoginPage() {
  const { signIn, user, profile } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  if (user && profile) return <Navigate to="/" replace />;

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    setError("");
    setBusy(true);
    try { await signIn(email, password); }
    catch (err) { setError(err instanceof Error ? err.message : "Não foi possível entrar."); }
    finally { setBusy(false); }
  }

  return (
    <div className="login-page">
      <div className="login-decoration"><div className="login-brand"><Activity size={28}/> Plantão<span>PS</span></div><div className="login-message"><h1>Atendimento integrado.<br/>Cuidado em primeiro lugar.</h1><p>Uma plataforma para conectar equipes, organizar fluxos e acompanhar cada etapa do pronto-socorro.</p></div><div className="login-footer">PLATAFORMA DE GESTÃO DE PRONTO-SOCORRO</div></div>
      <div className="login-panel"><form className="login-form" onSubmit={submit}><div className="login-icon"><LockKeyhole size={23}/></div><h2>Bem-vindo(a)</h2><p>Entre com suas credenciais institucionais.</p>
        {!isSupabaseConfigured && <div className="alert alert-warning">Configure VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY no arquivo .env antes de entrar.</div>}
        <label>E-mail institucional</label><div className="input-icon"><Mail size={17}/><input type="email" value={email} onChange={e=>setEmail(e.target.value)} placeholder="nome@hospital.com" required/></div>
        <label>Senha</label><div className="input-icon"><LockKeyhole size={17}/><input type="password" value={password} onChange={e=>setPassword(e.target.value)} placeholder="Digite sua senha" required/></div>
        {error && <div className="alert alert-error">{error}</div>}
        <button className="primary-button full-button" disabled={busy || !isSupabaseConfigured}>{busy ? "Entrando..." : "Entrar no sistema"}</button>
        <small className="login-help">Acesso restrito a funcionários autorizados.</small>
      </form></div>
    </div>
  );
}
