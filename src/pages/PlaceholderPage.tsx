import { Construction } from "lucide-react";
export function PlaceholderPage({ title, description }: { title: string; description: string }) {
  return <div className="page-stack"><div className="page-heading"><div><span className="eyebrow">MÓDULO</span><h1>{title}</h1><p>{description}</p></div></div><section className="panel module-placeholder"><div className="empty-icon"><Construction size={26}/></div><h3>Módulo preparado para implementação</h3><p>Esta etapa será conectada às tabelas e operações seguras do Supabase nas próximas fases.</p></section></div>;
}
