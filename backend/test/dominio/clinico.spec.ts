import { sumarDias } from '../../src/shared/domain/reloj';
import { FichaEmergencia } from '../../src/modules/emergencias/domain/ficha-emergencia';
import { EstadoExtraccion, ExamenMedico } from '../../src/modules/examenes/domain/examen-medico';
import { EstadoSolicitud, SolicitudExamen } from '../../src/modules/examenes/domain/solicitud-examen';
import { CategoriaClinica, categoriaDe, TipoEvento } from '../../src/modules/expediente/domain/categoria-clinica';
import { PermisoAcceso } from '../../src/modules/expediente/domain/permiso-acceso';
import { ResenaVerificada } from '../../src/modules/resenas/domain/resena-verificada';

const AHORA = new Date('2026-10-12T12:00:00.000Z');

describe('PermisoAcceso (HU: decidir qué médico ve qué parte de mi historial y por cuánto tiempo)', () => {
  const permiso = () =>
    PermisoAcceso.conceder(
      {
        expedienteId: 'e'.repeat(24),
        pacienteId: 'p'.repeat(24),
        medicoId: 'm'.repeat(24),
        categoriasPermitidas: [CategoriaClinica.LABORATORIOS, CategoriaClinica.DIAGNOSTICOS],
        escritura: false,
        validoHasta: sumarDias(AHORA, 30),
        otorgadoPorUsuarioId: 'u'.repeat(24),
        origen: 'PACIENTE',
      },
      AHORA,
    );

  it('permite leer solo las secciones concedidas mientras está vigente', () => {
    const p = permiso();
    expect(p.permiteLeer(CategoriaClinica.LABORATORIOS, AHORA)).toBe(true);
    expect(p.permiteLeer(CategoriaClinica.SALUD_MENTAL, AHORA)).toBe(false);
    expect(p.permiteEscribir(CategoriaClinica.LABORATORIOS, AHORA)).toBe(false);
    expect(p.estaVigente(sumarDias(AHORA, 31))).toBe(false);
  });

  it('la revocación aplica de inmediato', () => {
    const p = permiso();
    p.revocar(AHORA);
    expect(p.permiteLeer(CategoriaClinica.LABORATORIOS, AHORA)).toBe(false);
  });

  it('cada tipo de evento pertenece a una sección', () => {
    expect(categoriaDe(TipoEvento.EXAMEN)).toBe(CategoriaClinica.LABORATORIOS);
    expect(categoriaDe(TipoEvento.VACUNA)).toBe(CategoriaClinica.VACUNAS);
    expect(categoriaDe(TipoEvento.NOTA_SALUD_MENTAL)).toBe(CategoriaClinica.SALUD_MENTAL);
  });
});

describe('ResenaVerificada (HU: reseñas solo de consultas atendidas)', () => {
  const datos = { citaId: 'c'.repeat(24), pacienteId: 'p'.repeat(24), medicoId: 'm'.repeat(24), autorUsuarioId: 'u'.repeat(24) };

  it('exige calificaciones enteras de 1 a 5 en los cuatro criterios', () => {
    expect(() => ResenaVerificada.publicar({ ...datos, puntualidad: 6, trato: 5, claridad: 5, instalaciones: 5 }, AHORA)).toThrow('puntualidad');
    const r = ResenaVerificada.publicar({ ...datos, puntualidad: 5, trato: 4, claridad: 5, instalaciones: 4 }, AHORA);
    expect(r.promedio).toBe(4.5);
  });

  it('es editable durante 7 días', () => {
    const r = ResenaVerificada.publicar({ ...datos, puntualidad: 3, trato: 3, claridad: 3, instalaciones: 3 }, AHORA);
    r.editar({ puntualidad: 5, trato: 5, claridad: 5, instalaciones: 5, comentario: 'Mejoró' }, sumarDias(AHORA, 6));
    expect(r.promedio).toBe(5);
    expect(() => r.editar({ puntualidad: 1, trato: 1, claridad: 1, instalaciones: 1 }, sumarDias(AHORA, 8))).toThrow('7 días');
  });
});

describe('ExamenMedico (HU: subir exámenes y extraer valores)', () => {
  const examen = () =>
    ExamenMedico.cargar(
      {
        pacienteId: 'p'.repeat(24),
        titulo: 'Perfil lipídico',
        archivoRef: 'examenes/1',
        tipoMime: 'application/pdf',
        nombreArchivo: 'lab.pdf',
        tamanoBytes: 1000,
        cargadoPorUsuarioId: 'u'.repeat(24),
      },
      AHORA,
    );

  it('si el OCR no reconoce el documento se guarda igual como adjunto', () => {
    const e = examen();
    e.registrarExtraccion(null);
    expect(e.estadoExtraccion).toBe(EstadoExtraccion.NO_RECONOCIDO);
    expect(e.resultados).toHaveLength(0);
  });

  it('el paciente corrige los valores extraídos antes de confirmarlos', () => {
    const e = examen();
    e.registrarExtraccion([
      { analito: 'Colesterol total', valor: '192', unidad: 'mg/dL', confianzaOcr: 0.9, validadoPorMedico: false },
      { analito: 'HDL', valor: '48', unidad: 'mg/dL', confianzaOcr: 0.8, validadoPorMedico: false },
    ]);
    expect(e.estadoExtraccion).toBe(EstadoExtraccion.EXTRAIDO);
    e.confirmarResultados([
      { analito: 'Colesterol total', valor: '192', unidad: 'mg/dL' },
      { analito: 'HDL', valor: '52', unidad: 'mg/dL' },
    ]);
    expect(e.estadoExtraccion).toBe(EstadoExtraccion.CONFIRMADO);
    expect(e.resultados[0].confianzaOcr).toBe(0.9);
    expect(e.resultados[1].confianzaOcr).toBeUndefined();
  });

  it('la orden pasa a completada al recibir resultados', () => {
    const s = SolicitudExamen.crear({ pacienteId: 'p'.repeat(24), medicoId: 'm'.repeat(24), examenes: ['Perfil lipídico', 'Perfil lipídico'] }, AHORA);
    expect(s.examenes).toHaveLength(1);
    expect(s.estado).toBe(EstadoSolicitud.PENDIENTE);
    s.completar('x'.repeat(24), AHORA);
    expect(s.estado).toBe(EstadoSolicitud.COMPLETADA);
  });
});

describe('FichaEmergencia (HU: QR con la ficha médica)', () => {
  const ficha = () => {
    const f = FichaEmergencia.vacia('p'.repeat(24), AHORA);
    f.actualizar(
      {
        grupoSanguineo: 'O+',
        alergias: ['Penicilina'],
        condicionesCronicas: ['Asma'],
        medicacionActual: ['Salbutamol'],
        contactos: [{ nombre: 'Carlos', parentesco: 'Esposo', telefono: '+58 414' }],
        camposPublicos: ['grupoSanguineo', 'alergias', 'condicionesCronicas', 'contactos'],
      },
      AHORA,
    );
    return f;
  };

  it('la vista pública no incluye campos no marcados; la ampliada sí', () => {
    const f = ficha();
    expect(f.vista(false).medicacionActual).toBeUndefined();
    expect(f.vista(false).alergias).toEqual(['Penicilina']);
    expect(f.vista(true).medicacionActual).toEqual(['Salbutamol']);
  });

  it('guarda solo el hash del token y regenerarlo cambia el hash', () => {
    const f = ficha();
    const { token } = f.regenerarToken(AHORA);
    expect(f.tokenQrHash).toBe(FichaEmergencia.hashToken(token));
    expect(f.tokenQrHash).not.toBe(token);
    const { hashAnterior } = f.regenerarToken(AHORA);
    expect(hashAnterior).toBe(FichaEmergencia.hashToken(token));
    expect(f.tokenQrHash).not.toBe(hashAnterior);
  });

  it('valida el grupo sanguíneo', () => {
    const f = ficha();
    expect(() => f.actualizar({ ...f, grupoSanguineo: 'Z+' }, AHORA)).toThrow('Grupo sanguíneo');
  });
});
