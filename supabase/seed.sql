-- Dados de demonstração não clínicos. Execute depois da migration.
insert into public.beds(code,ward,status) values
('OBS-01','Observação','livre'),
('OBS-02','Observação','livre'),
('OBS-03','Observação','livre'),
('VER-01','Sala Vermelha','livre'),
('VER-02','Sala Vermelha','livre')
on conflict (code) do nothing;

insert into public.medications(name,max_dose,dose_unit) values
('Paracetamol',4000,'mg/dia'),
('Dipirona',4000,'mg/dia'),
('Ibuprofeno',1200,'mg/dia')
on conflict (name) do nothing;
