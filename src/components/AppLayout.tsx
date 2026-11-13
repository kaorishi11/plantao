import { NavLink, Outlet, useNavigate } from "react-router-dom";
import {
  Activity, Bed, ChartNoAxesCombined, ClipboardList, HeartPulse,
  LayoutDashboard, LogOut, MonitorPlay, Stethoscope, Users
} from "lucide-react";
import { useAuth } from "../contexts/AuthContext";
import { ROLE_LABELS } from "../types/database";

const links = [
  { to: "/", label: "Visão geral", icon: LayoutDashboard, roles: ["recepcao", "enfermagem", "medico", "gestao"] },
  { to: "/recepcao", label: "Recepção", icon: Users, roles: ["recepcao"] },
  { to: "/triagem", label: "Triagem", icon: HeartPulse, roles: ["enfermagem"] },
  { to: "/fila", label: "Fila de atendimento", icon: ClipboardList, roles: ["enfermagem", "medico"] },
  { to: "/leitos", label: "Mapa de leitos", icon: Bed, roles: ["enfermagem"] },
  { to: "/atendimento", label: "Atendimento médico", icon: Stethoscope, roles: ["medico"] },
  { to: "/gestao", label: "Indicadores", icon: ChartNoAxesCombined, roles: ["gestao"] },
  { to: "/painel", label: "Painel de chamadas", icon: MonitorPlay, roles: ["painel"] }
] as const;

export function AppLayout() {
  const { profile, signOut } = useAuth();
  const navigate = useNavigate();
  const visibleLinks = links.filter(link => profile && link.roles.includes(profile.role));
  async function handleSignOut() {
    await signOut();
    navigate("/login");
  }

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand"><span className="brand-mark"><Activity size={22}/></span><span>Plantão<span className="brand-light">PS</span></span></div>
        <div className="sidebar-caption">MENU PRINCIPAL</div>
        <nav className="side-nav">
          {visibleLinks.map(({ to, label, icon: Icon }) => (
            <NavLink key={to} to={to} end={to === "/"} className={({ isActive }) => isActive ? "nav-link active" : "nav-link"}>
              <Icon size={18}/><span>{label}</span>
            </NavLink>
          ))}
        </nav>
        <div className="sidebar-bottom">
          <div className="user-mini"><div className="avatar">{profile?.full_name?.slice(0, 1).toUpperCase() ?? "U"}</div><div><strong>{profile?.full_name}</strong><small>{profile ? ROLE_LABELS[profile.role] : ""}</small></div></div>
          <button className="logout-button" onClick={handleSignOut}><LogOut size={17}/> Sair</button>
        </div>
      </aside>
      <main className="main-area">
        <header className="topbar"><div><span className="topbar-label">PRONTO-SOCORRO</span><strong>Gestão de atendimento</strong></div><div className="topbar-right"><span className="status-dot"/> Sistema conectado</div></header>
        <div className="page-content"><Outlet/></div>
      </main>
    </div>
  );
}
