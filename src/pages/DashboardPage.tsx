import { Activity, Clock3, Users, Bed, ArrowUpRight, ShieldCheck } from "lucide-react";
import { useAuth } from "../contexts/AuthContext";
import { ROLE_LABELS } from "../types/database";

export function DashboardPage() {
  const { profile } = useAuth();
  const cards = [
    { label: "Atendimentos hoje", value: "—", note: "Aguardando conexão com o banco", icon: Users },
    { label: "Tempo médio de espera", value: "—", note: "Será calculado pelos atendimentos", icon: Clock3 },
    { label: "Pacientes em atendimento", value: "—", note: "Dados em tempo real", icon: Activity },
    { label: "Leitos ocupados", value: "—", note: "Ocupação atual", icon: Bed }
  ];
  return <div className="page-stack">
    <div className="page-heading"><div><span className="eyebrow">VISÃO GERAL</span><h1>Olá, {profile?.full_name?.split(" ")[0] ?? "equipe"}!</h1><p>Acompanhe as informações do pronto-socorro.</p></div><span className="role-chip"><ShieldCheck size={15}/> {profile ? ROLE_LABELS[profile.role] : ""}</span></div>
    <div className="stat-grid">{cards.map(({label,value,note,icon:Icon})=><div className="stat-card" key={label}><div className="stat-top"><span>{label}</span><span className="stat-icon"><Icon size={19}/></span></div><strong>{value}</strong><small>{note}</small></div>)}</div>
    <div className="content-grid"><section className="panel"><div className="panel-heading"><div><h3>Fluxo de atendimento</h3><p>Resumo das etapas do pronto-socorro</p></div><ArrowUpRight size={19}/></div><div className="empty-state"><div className="empty-icon"><Activity size={25}/></div><strong>Banco de dados aguardando configuração</strong><p>Após conectar o Supabase e cadastrar os primeiros atendimentos, os indicadores serão exibidos aqui.</p></div></section><section className="panel"><div className="panel-heading"><div><h3>Conexão do sistema</h3><p>Status dos serviços</p></div></div><div className="connection-row"><span>Interface web</span><span className="connection-ok">Operacional</span></div><div className="connection-row"><span>Supabase</span><span className="connection-pending">Configuração necessária</span></div><div className="connection-row"><span>Atualização em tempo real</span><span className="connection-pending">Aguardando banco</span></div></section></div>
  </div>;
}
