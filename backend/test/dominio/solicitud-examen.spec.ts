import { EstadoSolicitud, SolicitudExamen } from '../../src/modules/examenes/domain/solicitud-examen';
import { TipoEvento } from '../../src/modules/expediente/domain/categoria-clinica';
import { crearContexto } from '../support/contexto';

const AHORA = new Date('2026-10-12T12:00:00.000Z');
const MEDICO = 'm'.repeat(24);

const nuevaOrden = () =>
  SolicitudExamen.crear({ pacienteId: 'p'.repeat(24), medicoId: MEDICO, examenes: ['Hematología completa', 'Perfil lipídico'] }, AHORA);

describe('SolicitudExamen (HU: solicitar exámenes y recibir los resultados en el expediente)', () => {
  it('nace pendiente y pasa a completada al cargar resultados', () => {
    const orden = nuevaOrden();
    expect(orden.estado).toBe(EstadoSolicitud.PENDIENTE);
    orden.completar('e'.repeat(24), AHORA);
    expect(orden.estado).toBe(EstadoSolicitud.COMPLETADA);
    expect(orden.completadaEn).toEqual(AHORA);
  });

  it('el médico que la indicó puede anularla mientras está pendiente', () => {
    const orden = nuevaOrden();
    orden.anular(MEDICO, 'Indicada por error en el paciente equivocado', AHORA);
    expect(orden.estado).toBe(EstadoSolicitud.ANULADA);
    expect(orden.motivoAnulacion).toBe('Indicada por error en el paciente equivocado');
    expect(orden.anuladaEn).toEqual(AHORA);
  });

  it('no se puede anular sin motivo, por otro médico, ni después de tener resultados', () => {
    expect(() => nuevaOrden().anular(MEDICO, 'no', AHORA)).toThrow('motivo');
    expect(() => nuevaOrden().anular('x'.repeat(24), 'Ya no hace falta', AHORA)).toThrow('Solo el médico');
    const completada = nuevaOrden();
    completada.completar('e'.repeat(24), AHORA);
    expect(() => completada.anular(MEDICO, 'Ya no hace falta', AHORA)).toThrow('resultados');
  });

  it('una orden anulada ya no acepta resultados', () => {
    const orden = nuevaOrden();
    orden.anular(MEDICO, 'Ya no hace falta', AHORA);
    expect(() => orden.completar('e'.repeat(24), AHORA)).toThrow('anulada');
  });
});

describe('Línea de tiempo: el estado de la orden se mantiene al día', () => {
  it('actualiza los detalles del evento que generó la orden', async () => {
    const ctx = crearContexto();
    const { perfil } = await ctx.pacienteTitular();
    const evento = await ctx.expediente.registrarEvento({
      pacienteId: perfil.id,
      tipo: TipoEvento.SOLICITUD_EXAMEN,
      fecha: AHORA,
      titulo: 'Orden de exámenes (2)',
      resumen: 'Hematología completa, Perfil lipídico',
      documentoOrigenId: 'd'.repeat(24),
      detalles: { estado: EstadoSolicitud.PENDIENTE },
    });

    await ctx.expediente.actualizarEventoDeDocumento('d'.repeat(24), TipoEvento.SOLICITUD_EXAMEN, { estado: EstadoSolicitud.COMPLETADA });

    const actualizado = await ctx.repos.eventos.buscarPorId(evento.id);
    expect(actualizado?.detalles.estado).toBe(EstadoSolicitud.COMPLETADA);
  });
});
