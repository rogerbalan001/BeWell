/**
 * Datos de demostración para el Product Review del MVP. BORRA la base de datos.
 * Lo usan `npm run seed`, el sembrado automático al iniciar (SEED_SI_VACIA) y
 * el endpoint de administración POST /demo/reiniciar.
 *
 * Se usan los servicios de aplicación siempre que es posible, para que los
 * datos respeten las mismas reglas de negocio que la API. Solo las citas del
 * pasado se insertan directamente con el repositorio (el dominio no permite
 * agendar en el pasado).
 */
import { getConnectionToken } from '@nestjs/mongoose';
import { Connection } from 'mongoose';
import { aCentavos } from '../shared/domain/dinero';
import { generarId } from '../shared/domain/id';
import { sumarDias, sumarHoras } from '../shared/domain/reloj';
import { Actor, RolUsuario } from '../shared/domain/roles';
import { AuthService } from '../modules/auth/application/auth.service';
import { CitasService } from '../modules/citas/application/citas.service';
import { Cita, EstadoCita } from '../modules/citas/domain/cita';
import { CitaRepository } from '../modules/citas/domain/cita.repository';
import { EmergenciaService } from '../modules/emergencias/application/emergencia.service';
import { ExamenesService } from '../modules/examenes/application/examenes.service';
import { ExpedienteService } from '../modules/expediente/application/expediente.service';
import { ReferenciasService } from '../modules/expediente/application/referencias.service';
import { CategoriaClinica, TipoEvento } from '../modules/expediente/domain/categoria-clinica';
import { HistoriaClinicaService } from '../modules/historia-clinica/application/historia-clinica.service';
import { AgendaService } from '../modules/medicos/application/agenda.service';
import { MedicosService } from '../modules/medicos/application/medicos.service';
import { VerificacionProfesionalService } from '../modules/medicos/application/verificacion-profesional.service';
import { TipoCredencial } from '../modules/medicos/domain/credencial-profesional';
import { TipoPolitica } from '../modules/medicos/domain/politica-cancelacion';
import { PagosService } from '../modules/pagos/application/pagos.service';
import { PagoRepository } from '../modules/pagos/domain/pago.repository';
import { PerfilesService } from '../modules/perfiles/application/perfiles.service';
import { RecipesService } from '../modules/recipes/application/recipes.service';
import { ResenasService } from '../modules/resenas/application/resenas.service';

const PASSWORD = 'Bewell2026!';

const PDF_DEMO = Buffer.from(
  '%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n' +
    '3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 360 160]/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>>>endobj\n' +
    '4 0 obj<</Length 66>>stream\nBT /F1 14 Tf 24 80 Td (Bewell - documento de demostracion) Tj ET\nendstream endobj\n' +
    '5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj\ntrailer<</Root 1 0 R>>\n%%EOF\n',
);

interface MedicoSemilla {
  email: string;
  nombres: string;
  apellidos: string;
  especialidad: string;
  tarifa: number;
  politica: TipoPolitica;
  direccion: string;
  biografia: string;
  aprobar: boolean;
}

const MEDICOS: MedicoSemilla[] = [
  {
    email: 'mateo.ruiz@bewell.app',
    nombres: 'Mateo',
    apellidos: 'Ruiz',
    especialidad: 'Medicina General',
    tarifa: 45,
    politica: 'FLEXIBLE',
    direccion: 'Centro Médico Bewell — Sede Central, Consultorio 302',
    biografia: 'Médico general con 12 años de experiencia en medicina preventiva y control de enfermedades crónicas.',
    aprobar: true,
  },
  {
    email: 'valentina.soto@bewell.app',
    nombres: 'Valentina',
    apellidos: 'Soto',
    especialidad: 'Medicina Interna',
    tarifa: 50,
    politica: 'MODERADA',
    direccion: 'Bewell Virtual Care Network',
    biografia: 'Internista enfocada en enfermedades metabólicas y teleconsulta.',
    aprobar: true,
  },
  {
    email: 'daniel.campos@bewell.app',
    nombres: 'Daniel',
    apellidos: 'Campos',
    especialidad: 'Cardiología',
    tarifa: 65,
    politica: 'ESTRICTA',
    direccion: 'Clínica Bewell Norte — Consultorio 402',
    biografia: 'Cardiólogo clínico. Ecocardiografía y chequeo cardiovascular integral.',
    aprobar: true,
  },
  {
    email: 'camila.morales@bewell.app',
    nombres: 'Camila',
    apellidos: 'Morales',
    especialidad: 'Pediatría',
    tarifa: 45,
    politica: 'MODERADA',
    direccion: 'Centro Médico Bewell — Sede Central, Consultorio 105',
    biografia: 'Pediatra y nutricionista infantil.',
    aprobar: true,
  },
  {
    email: 'andres.perez@bewell.app',
    nombres: 'Andrés',
    apellidos: 'Pérez',
    especialidad: 'Dermatología',
    tarifa: 55,
    politica: 'MODERADA',
    direccion: 'Clínica Bewell Este',
    biografia: 'Dermatólogo (pendiente de verificación: úsalo para la demo del administrador).',
    aprobar: false,
  },
];

const HORARIO_LABORAL = [1, 2, 3, 4, 5].flatMap((dia) => [
  { diaSemana: dia, horaInicio: '08:00', horaFin: '12:00', duracionCitaMin: 30 },
  { diaSemana: dia, horaInicio: '14:00', horaFin: '18:00', duracionCitaMin: 30 },
]);
HORARIO_LABORAL.push({ diaSemana: 6, horaInicio: '09:00', horaFin: '13:00', duracionCitaMin: 30 });

export const PASSWORD_DEMO = PASSWORD;

export const CUENTAS_DEMO = [
  { rol: 'Paciente (titular con 2 dependientes)', email: 'sofia.morales@bewell.app' },
  { rol: 'Paciente', email: 'martin.alvarez@bewell.app' },
  { rol: 'Médico — Medicina General', email: 'mateo.ruiz@bewell.app' },
  { rol: 'Médico — Medicina Interna', email: 'valentina.soto@bewell.app' },
  { rol: 'Médico — Cardiología', email: 'daniel.campos@bewell.app' },
  { rol: 'Médico — Pediatría', email: 'camila.morales@bewell.app' },
  { rol: 'Médico PENDIENTE de verificación', email: 'andres.perez@bewell.app' },
  { rol: 'Administrador', email: 'admin@bewell.app' },
  { rol: 'Personal de emergencia', email: 'emergencia@bewell.app' },
];

export interface ResultadoDemo {
  password: string;
  cuentas: typeof CUENTAS_DEMO;
  codigoRecipe: string;
  urlRecipe: string;
  urlQrEmergencia: string;
}

/** Resuelve un proveedor del contenedor de Nest (app.get o moduleRef.get). */
export interface Resolver {
  <T>(token: abstract new (...args: never) => T): T;
  <T>(token: string | symbol): T;
}

/** Borra la base de datos y carga los datos de demostración. */
export async function sembrarDatosDemo(obtener: Resolver, urlWeb: string): Promise<ResultadoDemo> {
  const conexion = obtener<Connection>(getConnectionToken());
  await conexion.dropDatabase();
  await conexion.syncIndexes();

  const auth = obtener(AuthService);
  const verificacion = obtener(VerificacionProfesionalService);
  const agenda = obtener(AgendaService);
  const medicosService = obtener(MedicosService);
  const perfiles = obtener(PerfilesService);
  const expediente = obtener(ExpedienteService);
  const referencias = obtener(ReferenciasService);
  const citas = obtener(CitasService);
  const citaRepo = obtener(CitaRepository);
  const pagos = obtener(PagosService);
  const pagoRepo = obtener(PagoRepository);
  const resenas = obtener(ResenasService);
  const recipes = obtener(RecipesService);
  const examenes = obtener(ExamenesService);
  const emergencia = obtener(EmergenciaService);
  const historiaClinica = obtener(HistoriaClinicaService);
  const ahora = new Date();

  // ---------- Usuarios internos ----------
  const admin = await auth.crearUsuarioInterno('admin@bewell.app', PASSWORD, RolUsuario.ADMIN, 'Administración Bewell');
  await auth.crearUsuarioInterno('emergencia@bewell.app', PASSWORD, RolUsuario.PERSONAL_EMERGENCIA, 'Paramédico de guardia');

  // ---------- Médicos ----------
  const actoresMedicos: Record<string, Actor> = {};
  for (const m of MEDICOS) {
    const sesion = await auth.registrarMedico({
      email: m.email,
      password: PASSWORD,
      nombres: m.nombres,
      apellidos: m.apellidos,
      especialidades: [m.especialidad],
      tarifaConsulta: aCentavos(m.tarifa),
      telefono: '+58 412 555 0000',
    });
    const actor: Actor = { id: sesion.usuario.id, email: m.email, roles: [RolUsuario.MEDICO], medicoId: sesion.usuario.medicoId };
    actoresMedicos[m.email] = actor;
    await medicosService.actualizarPerfil(actor, { direccionConsultorio: m.direccion, biografia: m.biografia });
    await agenda.configurarHorario(actor, HORARIO_LABORAL, ['PRESENCIAL', 'VIRTUAL']);
    await agenda.configurarPolitica(actor, m.politica);
    const numeros: Record<TipoCredencial, string> = {
      TITULO: `UCV-MED-${Math.floor(10000 + Math.random() * 89999)}`,
      COLEGIATURA: `CMDF-${Math.floor(10000 + Math.random() * 89999)}`,
      CEDULA: `V-${Math.floor(8_000_000 + Math.random() * 20_000_000)}`,
    };
    for (const tipo of ['TITULO', 'COLEGIATURA', 'CEDULA'] as TipoCredencial[]) {
      const cred = await verificacion.registrarCredencial(actor, tipo, numeros[tipo], {
        contenido: PDF_DEMO,
        tipoMime: 'application/pdf',
        nombreOriginal: `${tipo.toLowerCase()}-${m.apellidos.toLowerCase()}.pdf`,
      });
      if (m.aprobar) await verificacion.aprobarCredencial(admin.id, actor.medicoId!, cred.id);
    }
  }
  const ruiz = actoresMedicos['mateo.ruiz@bewell.app'];
  const soto = actoresMedicos['valentina.soto@bewell.app'];
  const campos = actoresMedicos['daniel.campos@bewell.app'];

  // ---------- Pacientes ----------
  const sofiaSesion = await auth.registrarPaciente({
    email: 'sofia.morales@bewell.app',
    password: PASSWORD,
    telefono: '+58 414 332 1190',
    nombres: 'Sofía',
    apellidos: 'Morales',
    cedula: 'V-18490231',
    fechaNacimiento: new Date('1992-05-14'),
    sexo: 'F',
  });
  const sofia: Actor = { id: sofiaSesion.usuario.id, email: 'sofia.morales@bewell.app', roles: [RolUsuario.PACIENTE] };
  const sofiaPerfil = (await perfiles.listarPerfiles(sofia.id))[0];
  const lucas = await perfiles.crearPerfilFamiliar(sofia.id, 'HIJO', {
    nombres: 'Lucas',
    apellidos: 'Morales',
    fechaNacimiento: new Date('2019-03-02'),
    sexo: 'M',
  });
  await perfiles.crearPerfilFamiliar(sofia.id, 'MADRE', {
    nombres: 'Elena',
    apellidos: 'Serrano',
    cedula: 'V-5123456',
    fechaNacimiento: new Date('1958-11-20'),
    sexo: 'F',
  });

  const martinSesion = await auth.registrarPaciente({
    email: 'martin.alvarez@bewell.app',
    password: PASSWORD,
    nombres: 'Martín',
    apellidos: 'Álvarez',
    cedula: 'V-20111222',
    fechaNacimiento: new Date('1988-01-09'),
    sexo: 'M',
  });
  const martin: Actor = { id: martinSesion.usuario.id, email: 'martin.alvarez@bewell.app', roles: [RolUsuario.PACIENTE] };
  const martinPerfil = (await perfiles.listarPerfiles(martin.id))[0];

  // ---------- Expediente de Sofía (historial previo) ----------
  const historial: { tipo: TipoEvento; dias: number; titulo: string; resumen: string; medicoId?: string }[] = [
    { tipo: TipoEvento.CIRUGIA, dias: 3650, titulo: 'Apendicectomía laparoscópica', resumen: 'Cirugía sin complicaciones. Alta a las 48 h.' },
    { tipo: TipoEvento.VACUNA, dias: 190, titulo: 'Vacuna contra la influenza 2026', resumen: 'Dosis única, brazo izquierdo. Lote FLU-26-118.' },
    { tipo: TipoEvento.DIAGNOSTICO, dias: 120, titulo: 'Rinitis alérgica estacional', resumen: 'Se indica loratadina 10 mg en temporada de polen.', medicoId: soto.medicoId },
    { tipo: TipoEvento.VACUNA, dias: 30, titulo: 'Refuerzo antitetánico (Td)', resumen: 'Refuerzo decenal aplicado.' },
  ];
  for (const h of historial) {
    await expediente.registrarEvento({
      pacienteId: sofiaPerfil.id,
      tipo: h.tipo,
      fecha: sumarDias(ahora, -h.dias),
      titulo: h.titulo,
      resumen: h.resumen,
      medicoId: h.medicoId,
    });
  }
  await expediente.actualizarAntecedentes(sofia, sofiaPerfil.id, ['Asma leve intermitente en la infancia', 'Madre con hipertensión arterial']);
  await expediente.registrarEvento({
    pacienteId: lucas.id,
    tipo: TipoEvento.VACUNA,
    fecha: sumarDias(ahora, -60),
    titulo: 'Vacuna triple viral (SRP) — refuerzo',
    resumen: 'Esquema de vacunación al día.',
  });

  // Permisos de privacidad: Ruiz con escritura; Soto solo laboratorios y diagnósticos por 30 días.
  await expediente.concederAcceso(sofia, sofiaPerfil.id, {
    medicoId: ruiz.medicoId!,
    categorias: [
      CategoriaClinica.CONSULTAS,
      CategoriaClinica.DIAGNOSTICOS,
      CategoriaClinica.LABORATORIOS,
      CategoriaClinica.CIRUGIAS,
      CategoriaClinica.VACUNAS,
      CategoriaClinica.RECETAS,
    ],
    validoHasta: sumarDias(ahora, 90),
    escritura: true,
  });
  await expediente.concederAcceso(sofia, sofiaPerfil.id, {
    medicoId: soto.medicoId!,
    categorias: [CategoriaClinica.LABORATORIOS, CategoriaClinica.DIAGNOSTICOS],
    validoHasta: sumarDias(ahora, 30),
    escritura: false,
  });

  // ---------- Citas ----------
  const crearCitaPasada = async (pacienteId: string, agendadaPor: string, medicoActor: Actor, horasAtras: number, estado: EstadoCita, motivo: string) => {
    const medico = await medicosService.obtener(medicoActor.medicoId!);
    const inicio = sumarHoras(ahora, -horasAtras);
    inicio.setUTCSeconds(0, 0);
    const cita = new Cita({
      id: generarId(),
      pacienteId,
      medicoId: medico.id,
      agendadaPorUsuarioId: agendadaPor,
      inicio,
      fin: new Date(inicio.getTime() + 30 * 60_000),
      modalidad: 'PRESENCIAL',
      motivo,
      estado,
      monto: medico.tarifaConsulta,
      moneda: medico.moneda,
      politicaAplicada: medico.politicaCancelacion,
      atendidaEn: estado === EstadoCita.ATENDIDA ? sumarHoras(inicio, 0.5) : undefined,
      creadaEn: sumarDias(inicio, -3),
    });
    await citaRepo.guardar(cita);
    await pagos.retenerPago({ citaId: cita.id, pacienteId, medicoId: medico.id, monto: cita.monto, moneda: cita.moneda });
    if (estado === EstadoCita.ATENDIDA) {
      const pago = (await pagoRepo.buscarPorCita(cita.id))!;
      pago.programarLiberacion(cita.atendidaEn!);
      if (horasAtras > 30) pago.liberar(ahora);
      await pagoRepo.guardar(pago);
      await expediente.registrarEvento({
        pacienteId,
        tipo: TipoEvento.CONSULTA,
        fecha: inicio,
        titulo: `Consulta de ${medico.especialidades[0]}`,
        resumen: motivo,
        medicoId: medico.id,
        documentoOrigenId: cita.id,
      });
    }
    return cita;
  };

  // Martín: consultas atendidas con reseñas (alimentan las calificaciones del directorio).
  const resenasDemo: [Actor, number, number[], string][] = [
    [ruiz, 240, [5, 5, 5, 4], 'Muy claro al explicar el tratamiento. Excelente trato.'],
    [soto, 200, [5, 5, 5, 5], 'Pude agendar el mismo día y la videollamada fue impecable.'],
    [campos, 150, [4, 5, 5, 5], 'Chequeo cardiológico completo; muy puntual.'],
  ];
  for (const [medicoActor, horas, [puntualidad, trato, claridad, instalaciones], comentario] of resenasDemo) {
    const cita = await crearCitaPasada(martinPerfil.id, martin.id, medicoActor, horas, EstadoCita.ATENDIDA, 'Control general');
    await resenas.publicar(martin, cita.id, { puntualidad, trato, claridad, instalaciones, comentario });
  }

  // Sofía: consulta atendida hace 2 días (lista para reseña, récipe y orden de exámenes).
  const citaAtendida = await crearCitaPasada(sofiaPerfil.id, sofia.id, ruiz, 50, EstadoCita.ATENDIDA, 'Cefalea tensional y control de rinitis');
  // Sofía: consulta CONFIRMADA que empezó hace 10 minutos (para demostrar "Marcar como atendida").
  await crearCitaPasada(sofiaPerfil.id, sofia.id, ruiz, 10 / 60, EstadoCita.CONFIRMADA, 'Revisión de resultados de laboratorio');

  // Sofía: próxima cita real con la Dra. Soto (usa disponibilidad + agendamiento + retención del pago).
  const franjas = await citas.consultarDisponibilidad(soto.medicoId!, sumarDias(ahora, 2), 7);
  if (franjas[2]) {
    await citas.agendar(sofia, {
      medicoId: soto.medicoId!,
      pacienteId: sofiaPerfil.id,
      inicio: franjas[2].inicio,
      modalidad: 'VIRTUAL',
      motivo: 'Control metabólico y revisión de perfil lipídico',
    });
  }

  // Récipe firmado y orden de exámenes de la consulta atendida.
  const recipe = await recipes.emitir(ruiz, citaAtendida.id, {
    diagnostico: 'Cefalea tensional; rinitis alérgica estacional',
    items: [
      { medicamento: 'Loratadina', presentacion: 'Tabletas 10 mg', dosis: '1 tableta', frecuencia: 'cada 24 h', duracionDias: 14 },
      {
        medicamento: 'Acetaminofén',
        presentacion: 'Tabletas 500 mg',
        dosis: '1 tableta',
        frecuencia: 'cada 8 h si hay dolor',
        duracionDias: 5,
        indicaciones: 'No exceder 3 g al día',
      },
    ],
    validoDias: 30,
  });
  await examenes.solicitar(ruiz, {
    pacienteId: sofiaPerfil.id,
    citaId: citaAtendida.id,
    examenes: ['Perfil lipídico', 'Glicemia en ayunas', 'Hematología completa'],
    indicaciones: 'Ayuno de 12 horas.',
  });

  // Referencia pendiente de aprobación: Ruiz refiere a Sofía con Cardiología.
  await referencias.referir(ruiz, {
    pacienteId: sofiaPerfil.id,
    medicoDestinoId: campos.medicoId!,
    motivo: 'Palpitaciones ocasionales. Solicito evaluación cardiológica y ECG.',
  });

  // Ficha de emergencia + QR.
  await emergencia.actualizarFicha(sofia, sofiaPerfil.id, {
    grupoSanguineo: 'O+',
    alergias: ['Penicilina (anafilaxia)', 'Polen de olivo'],
    condicionesCronicas: ['Asma leve intermitente'],
    medicacionActual: ['Loratadina 10 mg (condicional)'],
    contactos: [{ nombre: 'Carlos Morales', parentesco: 'Esposo', telefono: '+58 414 332 1190' }],
    camposPublicos: ['grupoSanguineo', 'alergias', 'condicionesCronicas', 'contactos'],
  });
  const qr = await emergencia.regenerarQr(sofia, sofiaPerfil.id);

  // ---------- Historia clínica ----------
  // Antecedentes de Sofía (auto-reportados) y de Lucas (registrados por la titular).
  await historiaClinica.actualizarAntecedentes(sofia, sofiaPerfil.id, {
    grupoSanguineo: 'O+',
    alergicos: ['Penicilina (anafilaxia)', 'Polen de olivo'],
    patologicos: ['Asma leve intermitente desde la infancia', 'Rinitis alérgica estacional'],
    quirurgicos: ['Apendicectomía laparoscópica (2016), sin complicaciones'],
    medicamentosActuales: ['Loratadina 10 mg cada 24 h en temporada de polen', 'Salbutamol inhalado 100 mcg a demanda'],
    hospitalizaciones: ['2016 — apendicitis aguda (48 h)'],
    inmunizaciones: ['Influenza 2026', 'Td (refuerzo decenal)', 'Hepatitis B (esquema completo)', 'COVID-19 (3 dosis)'],
    familiares: ['Madre: hipertensión arterial', 'Padre: diabetes mellitus tipo 2', 'Abuela materna: cáncer de mama'],
    habitos: {
      tabaco: 'Niega',
      alcohol: 'Social, 1–2 copas al mes',
      drogas: 'Niega',
      actividadFisica: 'Caminata 30 min, 3 veces por semana',
      alimentacion: 'Balanceada, baja en sal',
      sueno: '7 horas, reparador',
    },
    ginecoObstetricos: {
      menarquia: '12 años',
      ultimaMenstruacion: sumarDias(ahora, -12).toISOString().slice(0, 10),
      gestas: 1,
      partos: 1,
      cesareas: 0,
      abortos: 0,
      metodoAnticonceptivo: 'DIU de cobre',
    },
  });
  await historiaClinica.actualizarAntecedentes(sofia, lucas.id, {
    grupoSanguineo: 'A+',
    patologicos: ['Bronquiolitis a los 8 meses'],
    inmunizaciones: ['Esquema nacional al día', 'Triple viral (SRP) — refuerzo'],
    familiares: ['Madre: asma y rinitis alérgica'],
    habitos: { alimentacion: 'Variada; consume poca verdura', sueno: '10 horas', actividadFisica: 'Natación 2 veces por semana' },
  });

  // Consulta de hace 3 meses (chequeo anual) con su historia completa.
  const chequeo = await crearCitaPasada(sofiaPerfil.id, sofia.id, ruiz, 90 * 24, EstadoCita.ATENDIDA, 'Chequeo periódico anual');
  await historiaClinica.registrarConsulta(ruiz, sofiaPerfil.id, {
    citaId: chequeo.id,
    motivoConsulta: 'Chequeo periódico anual',
    enfermedadActual: 'Paciente femenina de 34 años, asintomática, acude a control anual. Refiere rinitis en primavera controlada con loratadina. Sin crisis de asma en el último año.',
    revisionPorSistemas: 'Niega cefalea, dolor torácico, disnea, palpitaciones o alteraciones gastrointestinales.',
    signosVitales: { tensionArterial: '118/76', frecuenciaCardiaca: 72, frecuenciaRespiratoria: 16, temperatura: 36.6, saturacionOxigeno: 98, peso: 63, talla: 164 },
    examenFisico: 'Buen estado general. Cardiopulmonar: ruidos cardíacos rítmicos sin soplos, murmullo vesicular conservado sin agregados. Abdomen blando, depresible, cicatrices de laparoscopia. Sin edemas.',
    impresionDiagnostica: ['Adulto sano (Z00.0)', 'Rinitis alérgica estacional (J30.2)'],
    plan: 'Perfil lipídico, glicemia y hematología de control. Continuar loratadina en temporada. Control en 12 meses.',
    indicaciones: 'Mantener actividad física y dieta baja en sal.',
  });

  // Historia de la consulta atendida hace 2 días (Ruiz aún puede corregirla durante 24 h).
  await historiaClinica.registrarConsulta(ruiz, sofiaPerfil.id, {
    citaId: citaAtendida.id,
    motivoConsulta: 'Dolor de cabeza de 4 días',
    enfermedadActual: 'Cefalea frontal opresiva, bilateral, de intensidad 5/10, de 4 días de evolución, que empeora al final de la jornada laboral. Sin náuseas, fotofobia ni fiebre. Se asocia a congestión nasal y estornudos matutinos.',
    revisionPorSistemas: 'Rinorrea hialina y prurito nasal. Resto negativo.',
    signosVitales: { tensionArterial: '122/80', frecuenciaCardiaca: 78, frecuenciaRespiratoria: 16, temperatura: 36.8, saturacionOxigeno: 98, peso: 63.5, talla: 164 },
    examenFisico: 'Mucosa nasal pálida y edematosa. Sin dolor a la palpación de senos paranasales. Examen neurológico sin déficit focal. Contractura de trapecios.',
    impresionDiagnostica: ['Cefalea tensional (G44.2)', 'Rinitis alérgica estacional (J30.2)'],
    plan: 'Acetaminofén 500 mg cada 8 h si hay dolor por 5 días; loratadina 10 mg diaria por 14 días. Laboratorio de control. Referencia a cardiología por palpitaciones ocasionales.',
    indicaciones: 'Pausas activas en el trabajo, hidratación y evitar exposición a polen. Volver si la cefalea empeora o aparece fiebre.',
  });

  return {
    password: PASSWORD,
    cuentas: CUENTAS_DEMO,
    codigoRecipe: recipe.codigoVerificacion,
    urlRecipe: `${urlWeb}/verificar/${recipe.codigoVerificacion}`,
    urlQrEmergencia: qr.url,
  };
}
