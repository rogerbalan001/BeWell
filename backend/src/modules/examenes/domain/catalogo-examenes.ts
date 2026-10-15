/** Catálogo inicial de exámenes que el médico puede solicitar. */
export const CATALOGO_EXAMENES: { categoria: string; examenes: string[] }[] = [
  {
    categoria: 'Laboratorio clínico',
    examenes: [
      'Hematología completa',
      'Glicemia en ayunas',
      'Hemoglobina glicosilada (HbA1c)',
      'Perfil lipídico',
      'Perfil renal (urea y creatinina)',
      'Perfil hepático',
      'Perfil tiroideo (TSH, T4 libre)',
      'Examen de orina',
      'Examen de heces',
      'Proteína C reactiva',
      'Vitamina D',
      'Ferritina',
      'Antígeno prostático (PSA)',
    ],
  },
  { categoria: 'Cardiología', examenes: ['Electrocardiograma', 'Ecocardiograma', 'Prueba de esfuerzo', 'Holter 24 h'] },
  {
    categoria: 'Imagenología',
    examenes: ['Radiografía de tórax', 'Ecografía abdominal', 'Ecografía pélvica', 'Mamografía', 'Tomografía', 'Resonancia magnética'],
  },
];

export const NOMBRES_CATALOGO = CATALOGO_EXAMENES.flatMap((c) => c.examenes);
