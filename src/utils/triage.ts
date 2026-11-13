import type { RiskColor } from "../types/database";

export interface VitalSigns {
  systolicBp?: number | null;
  heartRate?: number | null;
  temperature?: number | null;
  oxygenSaturation?: number | null;
  painLevel: number;
  consciousness: "alerta" | "confuso" | "inconsciente";
}

const severity: Record<RiskColor, number> = {
  vermelho: 5,
  laranja: 4,
  amarelo: 3,
  verde: 2,
  azul: 1
};

/** Regra didática solicitada no projeto. Não substitui protocolo clínico validado. */
export function suggestRiskColor(v: VitalSigns): RiskColor {
  const candidates: RiskColor[] = [];

  if (
    (v.oxygenSaturation != null && v.oxygenSaturation < 90) ||
    (v.systolicBp != null && v.systolicBp < 80) ||
    (v.heartRate != null && (v.heartRate < 40 || v.heartRate > 140)) ||
    v.consciousness === "inconsciente"
  ) candidates.push("vermelho");

  if (
    (v.oxygenSaturation != null && v.oxygenSaturation >= 90 && v.oxygenSaturation <= 93) ||
    (v.temperature != null && (v.temperature >= 40 || v.temperature <= 35)) ||
    (v.painLevel >= 8 && v.painLevel <= 10) ||
    (v.heartRate != null && v.heartRate >= 121 && v.heartRate <= 140) ||
    v.consciousness === "confuso"
  ) candidates.push("laranja");

  if (
    (v.temperature != null && v.temperature >= 38.5 && v.temperature <= 39.9) ||
    (v.painLevel >= 5 && v.painLevel <= 7) ||
    (v.systolicBp != null && v.systolicBp >= 180)
  ) candidates.push("amarelo");

  if (
    (v.temperature != null && v.temperature >= 37.8 && v.temperature <= 38.4) ||
    (v.painLevel >= 1 && v.painLevel <= 4)
  ) candidates.push("verde");

  if (candidates.length === 0) return "azul";
  return candidates.sort((a, b) => severity[b] - severity[a])[0];
}
