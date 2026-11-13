export type UserRole = "recepcao" | "enfermagem" | "medico" | "gestao" | "painel";

export type EncounterStatus =
  | "aguardando_triagem"
  | "aguardando_medico"
  | "em_atendimento"
  | "aguardando_leito"
  | "em_observacao"
  | "alta"
  | "transferido"
  | "cancelado";

export type RiskColor = "vermelho" | "laranja" | "amarelo" | "verde" | "azul";

export interface Profile {
  id: string;
  full_name: string;
  role: UserRole;
  active: boolean;
}

export interface Patient {
  id: string;
  full_name: string;
  birth_date: string;
  sex: string;
  phone: string | null;
  allergies?: string[];
}

export interface Encounter {
  id: string;
  patient_id: string;
  daily_ticket: string;
  status: EncounterStatus;
  arrived_at: string;
  patient?: Patient;
  current_triage?: Triage;
}

export interface Triage {
  id: string;
  encounter_id: string;
  systolic_bp: number | null;
  diastolic_bp: number | null;
  heart_rate: number | null;
  temperature: number | null;
  oxygen_saturation: number | null;
  pain_level: number;
  consciousness: "alerta" | "confuso" | "inconsciente";
  chief_complaint: string;
  suggested_color: RiskColor;
  final_color: RiskColor;
  override_reason: string | null;
  created_at: string;
}

export const ROLE_LABELS: Record<UserRole, string> = {
  recepcao: "Recepção",
  enfermagem: "Enfermagem",
  medico: "Médico",
  gestao: "Gestão",
  painel: "Painel de chamadas"
};

export const RISK_LABELS: Record<RiskColor, string> = {
  vermelho: "Emergência",
  laranja: "Muito urgente",
  amarelo: "Urgente",
  verde: "Pouco urgente",
  azul: "Não urgente"
};

export const WAIT_LIMIT_MINUTES: Record<RiskColor, number> = {
  vermelho: 0,
  laranja: 10,
  amarelo: 60,
  verde: 120,
  azul: 240
};
