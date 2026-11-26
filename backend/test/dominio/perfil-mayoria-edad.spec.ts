import { PerfilesService } from '../../src/modules/perfiles/application/perfiles.service';
import { PARENTESCO_INDEPENDIENTE, PerfilPaciente } from '../../src/modules/perfiles/domain/perfil-paciente';
import { RolUsuario } from '../../src/shared/domain/roles';
import { PerfilesMemoria, RelojFijo } from '../support/memoria';

const HOY = new Date('2026-11-26T12:00:00.000Z');
const TITULAR = '64b000000000000000000001';
const HIJO_CUENTA = '64b000000000000000000002';

const hijo = (fechaNacimiento: string) =>
  PerfilPaciente.crear(TITULAR, 'HIJO', { nombres: 'Lucas', apellidos: 'Morales', cedula: 'V-30111222', fechaNacimiento: new Date(fechaNacimiento), sexo: 'M' }, HOY);

describe('Perfiles familiares: mayoría de edad', () => {
  it('un dependiente menor de edad no puede pedir el control de su perfil', () => {
    const p = hijo('2010-05-01');
    expect(p.esMayorDeEdad(HOY)).toBe(false);
    expect(() => p.solicitarControl(HIJO_CUENTA, HOY)).toThrow(/18 años/);
  });

  it('al cumplir 18, pide el control y el titular lo entrega con su expediente', () => {
    const p = hijo('2008-11-20');
    expect(p.esMayorDeEdad(HOY)).toBe(true);
    p.solicitarControl(HIJO_CUENTA, HOY);
    expect(p.solicitudControl?.usuarioId).toBe(HIJO_CUENTA);
    p.aprobarControl(HOY);
    expect(p.titularUsuarioId).toBe(HIJO_CUENTA);
    expect(p.parentescoConTitular).toBe(PARENTESCO_INDEPENDIENTE);
    expect(p.solicitudControl).toBeUndefined();
  });

  it('el titular puede rechazar la solicitud y el perfil sigue en su cuenta', () => {
    const p = hijo('2008-01-01');
    p.solicitarControl(HIJO_CUENTA, HOY);
    p.rechazarControl();
    expect(p.titularUsuarioId).toBe(TITULAR);
    expect(p.solicitudControl).toBeUndefined();
  });

  it('el servicio encuentra el perfil por cédula y fecha de nacimiento', async () => {
    const repo = new PerfilesMemoria();
    const servicio = new PerfilesService(repo, new RelojFijo(HOY));
    const p = hijo('2008-01-01');
    await repo.guardar(p);
    const actorHijo = { id: HIJO_CUENTA, email: 'lucas@bewell.app', roles: [RolUsuario.PACIENTE] };
    await expect(servicio.solicitarControl(actorHijo, 'V-30111222', new Date('2008-01-02'))).rejects.toThrow(/No encontramos/);
    await servicio.solicitarControl(actorHijo, 'V-30111222', new Date('2008-01-01'));
    const actorTitular = { id: TITULAR, email: 'sofia.morales@bewell.app', roles: [RolUsuario.PACIENTE] };
    const entregado = await servicio.responderSolicitudControl(actorTitular, p.id, true);
    expect(entregado.titularUsuarioId).toBe(HIJO_CUENTA);
    expect((await repo.buscarPorTitular(HIJO_CUENTA)).map((x) => x.id)).toEqual([p.id]);
  });
});
