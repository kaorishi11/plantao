import { Navigate, Route, Routes } from "react-router-dom";
import { useAuth } from "./contexts/AuthContext";
import { ProtectedRoute } from "./components/ProtectedRoute";
import { AppLayout } from "./components/AppLayout";
import { LoginPage } from "./pages/LoginPage";
import { DashboardPage } from "./pages/DashboardPage";
import { PlaceholderPage } from "./pages/PlaceholderPage";

export default function App() {
  const { profile, user, loading } = useAuth();
  if (loading) return <div className="screen-center">Carregando PlantãoPS...</div>;
  const role = profile?.role;
  return <Routes>
    <Route path="/login" element={<LoginPage/>}/>
    <Route element={<ProtectedRoute/>}>
      <Route element={<AppLayout/>}>
        <Route path="/" element={role === "gestao" ? <Navigate to="/gestao" replace/> : role === "recepcao" ? <Navigate to="/recepcao" replace/> : role === "enfermagem" ? <Navigate to="/triagem" replace/> : role === "medico" ? <Navigate to="/fila" replace/> : <DashboardPage/>}/>
        <Route path="/recepcao" element={<ProtectedRoute allowed={["recepcao"]}/> }><Route index element={<PlaceholderPage title="Recepção" description="Cadastro de pacientes e abertura de atendimentos."/>}/></Route>
        <Route path="/triagem" element={<ProtectedRoute allowed={["enfermagem"]}/> }><Route index element={<PlaceholderPage title="Triagem" description="Registro de sinais vitais e classificação de risco."/>}/></Route>
        <Route path="/fila" element={<ProtectedRoute allowed={["enfermagem","medico"]}/> }><Route index element={<PlaceholderPage title="Fila de atendimento" description="Fila priorizada e atualizada em tempo real."/>}/></Route>
        <Route path="/leitos" element={<ProtectedRoute allowed={["enfermagem"]}/> }><Route index element={<PlaceholderPage title="Mapa de leitos" description="Ocupação, limpeza e liberação de leitos."/>}/></Route>
        <Route path="/atendimento" element={<ProtectedRoute allowed={["medico"]}/> }><Route index element={<PlaceholderPage title="Atendimento médico" description="Evolução, prescrição e destino do paciente."/>}/></Route>
        <Route path="/gestao" element={<ProtectedRoute allowed={["gestao"]}/> }><Route index element={<PlaceholderPage title="Indicadores de gestão" description="Indicadores calculados a partir dos dados persistidos."/>}/></Route>
        <Route path="/painel" element={<ProtectedRoute allowed={["painel"]}/> }><Route index element={<PlaceholderPage title="Painel de chamadas" description="Tela pública de chamadas sem identificação nominal."/>}/></Route>
      </Route>
    </Route>
    <Route path="/sem-permissao" element={<div className="screen-center">Você não tem permissão para acessar esta página.</div>}/>
    <Route path="*" element={<Navigate to={user ? "/" : "/login"} replace/>}/>
  </Routes>;
}
