import { Injectable } from '@nestjs/common';
import { ClasificadorExamen, PistasClasificacion, SugerenciaClasificacion } from '../application/clasificador-examen';
import { categoriaDeTipo, CATEGORIA_OTRO } from '../domain/clasificacion-examen';

const sinTildes = (t: string) => t.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();

/** Reglas por analitos reconocidos: el primer tipo cuyos analitos aparezcan gana. */
const POR_ANALITOS: { tipo: string; analitos: RegExp }[] = [
  { tipo: 'Perfil lipídico', analitos: /colesterol|triglicerido/ },
  { tipo: 'Hemoglobina glicosilada (HbA1c)', analitos: /hba1c|glicosilada/ },
  { tipo: 'Hematología completa', analitos: /leucocitos|plaquetas|hematocrito|^hemoglobina$/ },
  { tipo: 'Perfil tiroideo (TSH, T4 libre)', analitos: /\btsh\b/ },
  { tipo: 'Perfil renal (urea y creatinina)', analitos: /creatinina|urea|acido urico/ },
  { tipo: 'Perfil hepático', analitos: /tgo|tgp|\bast\b|\balt\b/ },
  { tipo: 'Vitamina D', analitos: /vitamina d/ },
  { tipo: 'Glicemia en ayunas', analitos: /glucosa/ },
];

/** Reglas por palabras del nombre del archivo o del título que escribió el paciente. */
const POR_PALABRAS: { tipo: string; palabras: RegExp }[] = [
  { tipo: 'Radiografía de tórax', palabras: /\b(rx|radiografia|rayos x)\b/ },
  { tipo: 'Electrocardiograma', palabras: /\b(ecg|ekg|electrocardiograma)\b/ },
  { tipo: 'Ecocardiograma', palabras: /ecocardio/ },
  { tipo: 'Ecografía abdominal', palabras: /\b(eco|ecografia|ultrasonido)\b.*abdom|abdominal/ },
  { tipo: 'Ecografía pélvica', palabras: /pelvic/ },
  { tipo: 'Mamografía', palabras: /mamograf/ },
  { tipo: 'Tomografía', palabras: /\b(tac|tomografia)\b/ },
  { tipo: 'Resonancia magnética', palabras: /\b(rm|rmn|resonancia)\b/ },
  { tipo: 'Holter 24 h', palabras: /holter/ },
  { tipo: 'Examen de orina', palabras: /\borina\b|uroanalisis/ },
  { tipo: 'Examen de heces', palabras: /\bheces\b|coproanalisis/ },
  { tipo: 'Hematología completa', palabras: /hematologia/ },
  { tipo: 'Perfil lipídico', palabras: /lipid/ },
];

/**
 * Clasificador sin IA (por defecto y para demos sin clave de Gemini): deduce
 * el tipo por los analitos que reconoció el OCR y por palabras del nombre del
 * archivo o del título. Confianza moderada, porque son reglas fijas.
 */
@Injectable()
export class ClasificadorSimuladoAdapter extends ClasificadorExamen {
  async clasificar(archivo: { nombre: string }, pistas: PistasClasificacion): Promise<SugerenciaClasificacion | null> {
    const analitos = pistas.analitos.map(sinTildes);
    const porAnalito = POR_ANALITOS.find((r) => analitos.some((a) => r.analitos.test(a)));
    if (porAnalito) return this.sugerir(porAnalito.tipo, 0.7);
    const texto = sinTildes(`${archivo.nombre.replace(/[_\-.]/g, ' ')} ${pistas.tituloPaciente ?? ''}`);
    const porPalabra = POR_PALABRAS.find((r) => r.palabras.test(texto));
    return porPalabra ? this.sugerir(porPalabra.tipo, 0.5) : null;
  }

  private sugerir(tipo: string, confianza: number): SugerenciaClasificacion {
    return { categoria: categoriaDeTipo(tipo) ?? CATEGORIA_OTRO, tipo, confianza };
  }
}

/** Sin clasificador: el paciente siempre elige la categoría y el tipo. */
@Injectable()
export class ClasificadorNoDisponibleAdapter extends ClasificadorExamen {
  async clasificar(): Promise<SugerenciaClasificacion | null> {
    return null;
  }
}
