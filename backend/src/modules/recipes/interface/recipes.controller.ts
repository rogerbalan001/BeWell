import { Body, Controller, Get, HttpCode, Ip, Param, Post, Query } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsInt,
  IsMongoId,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ActorActual, Publico, Roles } from '../../../shared/interface/auth/decoradores';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { MedicosService } from '../../medicos/application/medicos.service';
import { Medico } from '../../medicos/domain/medico';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { PerfilPaciente } from '../../perfiles/domain/perfil-paciente';
import { RecipesService } from '../application/recipes.service';
import { ItemRecipe, RecipeDigital } from '../domain/recipe-digital';

export class ItemRecipeDto implements ItemRecipe {
  @IsString() @IsNotEmpty() @MaxLength(120) medicamento: string;
  @IsString() @MaxLength(120) presentacion: string;
  @IsString() @IsNotEmpty() @MaxLength(120) dosis: string;
  @IsString() @IsNotEmpty() @MaxLength(120) frecuencia: string;
  @IsInt() @Min(1) @Max(365) duracionDias: number;
  @IsOptional() @IsString() @MaxLength(500) indicaciones?: string;
}

export class EmitirRecipeDto {
  @IsMongoId() citaId: string;
  @IsArray() @ArrayNotEmpty() @ValidateNested({ each: true }) @Type(() => ItemRecipeDto) items: ItemRecipeDto[];
  @IsOptional() @IsString() @MaxLength(300) diagnostico?: string;
  @IsOptional() @IsInt() @Min(1) @Max(180) validoDias?: number;
}

export class AnularRecipeDto {
  @IsString() @IsNotEmpty() @MaxLength(300) motivo: string;
}

export class FiltroRecipesDto {
  @IsMongoId() pacienteId: string;
}

const enmascararCedula = (c?: string) => (c ? `${c.slice(0, 2)}${'•'.repeat(Math.max(0, c.length - 5))}${c.slice(-3)}` : undefined);

/** «Boundary» RecipesController y VerificacionRecipeController. */
@ApiTags('Récipes digitales')
@Controller('recipes')
export class RecipesController {
  constructor(
    private readonly recipes: RecipesService,
    private readonly medicos: MedicosService,
    private readonly perfiles: PerfilesService,
    private readonly config: ConfigService,
  ) {}

  /** Endpoint público para farmacias: código escrito o escaneado del QR. */
  @Publico()
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @Get('verificar/:codigo')
  async verificar(@Param('codigo') codigo: string, @Ip() ip: string) {
    const r = await this.recipes.verificar(codigo, ip);
    if (!r.encontrado || !r.recipe) return { encontrado: false, valido: false, mensaje: 'No existe un récipe con ese código' };
    return {
      encontrado: true,
      valido: r.valido,
      firmaValida: r.firmaValida,
      integro: r.integro,
      vigente: r.vigente,
      estado: r.recipe.estado,
      codigoVerificacion: r.recipe.codigoVerificacion,
      emitidoEn: r.recipe.emitidoEn,
      validoHasta: r.recipe.validoHasta,
      algoritmo: r.recipe.algoritmo,
      hashContenido: r.recipe.hashContenido,
      medico: {
        nombreCompleto: r.medico?.nombreCompleto,
        especialidad: r.medico?.especialidades[0],
        verificado: r.medico?.estaVerificado(),
        colegiatura: r.medico?.credenciales.find((c) => c.tipo === 'COLEGIATURA')?.numero,
      },
      paciente: { nombreCompleto: r.paciente?.nombreCompleto, cedula: enmascararCedula(r.paciente?.cedula) },
      items: r.recipe.items,
      motivoAnulacion: r.recipe.motivoAnulacion,
    };
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.MEDICO)
  @Post()
  async emitir(@ActorActual() actor: Actor, @Body() dto: EmitirRecipeDto) {
    return (await this.responder([await this.recipes.emitir(actor, dto.citaId, dto)]))[0];
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.MEDICO)
  @Get('emitidos')
  async emitidos(@ActorActual() actor: Actor) {
    return this.responder(await this.recipes.listarEmitidos(actor));
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.PACIENTE, RolUsuario.MEDICO)
  @Get()
  async listarPorPaciente(@ActorActual() actor: Actor, @Query() q: FiltroRecipesDto) {
    return this.responder(await this.recipes.listarPorPaciente(actor, q.pacienteId));
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.PACIENTE, RolUsuario.MEDICO)
  @Get(':id')
  async obtener(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string) {
    return (await this.responder([await this.recipes.obtener(actor, id)]))[0];
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.MEDICO)
  @HttpCode(200)
  @Post(':id/anular')
  async anular(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string, @Body() dto: AnularRecipeDto) {
    return (await this.responder([await this.recipes.anular(actor, id, dto.motivo)]))[0];
  }

  private async responder(lista: RecipeDigital[]) {
    const [medicos, pacientes] = await Promise.all([
      this.medicos.obtenerVarios(lista.map((r) => r.medicoId)),
      this.perfiles.obtenerVarios(lista.map((r) => r.pacienteId)),
    ]);
    const m = new Map<string, Medico>(medicos.map((x) => [x.id, x]));
    const p = new Map<string, PerfilPaciente>(pacientes.map((x) => [x.id, x]));
    const base = this.config.get<string>('PUBLIC_WEB_URL') ?? 'http://localhost:8080/#';
    return lista.map((r) => ({
      id: r.id,
      citaId: r.citaId,
      codigoVerificacion: r.codigoVerificacion,
      urlVerificacion: `${base}/verificar/${r.codigoVerificacion}`,
      estado: r.estado,
      emitidoEn: r.emitidoEn,
      validoHasta: r.validoHasta,
      diagnostico: r.diagnostico,
      items: r.items,
      hashContenido: r.hashContenido,
      algoritmo: r.algoritmo,
      motivoAnulacion: r.motivoAnulacion,
      medico: m.get(r.medicoId)
        ? { id: r.medicoId, nombreCompleto: m.get(r.medicoId)!.nombreCompleto, especialidad: m.get(r.medicoId)!.especialidades[0] }
        : { id: r.medicoId },
      paciente: p.get(r.pacienteId) ? { id: r.pacienteId, nombreCompleto: p.get(r.pacienteId)!.nombreCompleto } : { id: r.pacienteId },
    }));
  }
}
