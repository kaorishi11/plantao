import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import type { UserRole } from "../types/database";

export function ProtectedRoute({ allowed }: { allowed?: UserRole[] }) {
  const { user, profile, loading } = useAuth();
  if (loading) return <div className="screen-center">Carregando sessão...</div>;
  if (!user) return <Navigate to="/login" replace />;
  if (!profile || !profile.active) return <div className="screen-center">Seu perfil não está ativo. Procure a administração.</div>;
  if (allowed && !allowed.includes(profile.role)) return <Navigate to="/sem-permissao" replace />;
  return <Outlet />;
}
